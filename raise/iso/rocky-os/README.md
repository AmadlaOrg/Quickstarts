# Quickstart: Rocky Linux 10.1 VM from Local ISO

Provision a Rocky Linux 10.1 VM using a local ISO image with KVM/libvirt.

## Prerequisites

- KVM/QEMU installed (`qemu-system-x86_64`)
- libvirt running (`systemctl status libvirtd`)
- `virt-install` available
- Rocky Linux ISO at `/home/<user>/Projects/OS/Rocky-10.1-x86_64-minimal.iso`
- `raise` and `raise-libvirt` on PATH

## Entity Files

This quickstart defines the VM using 7 entity files — each describes one concern:

| File | Entity Type | Purpose |
|------|-------------|---------|
| `os.hery` | OS | Rocky Linux 10.1, x86_64, RHEL family |
| `os-preference.hery` | OS/Preference | Tool choices: dnf, firewalld, SELinux, nmcli |
| `infrastructure.hery` | Infrastructure | Provider = libvirt, SSH defaults |
| `vm.hery` | Infrastructure/VM | ISO path, disk size, port forwarding, GUI |
| `system.hery` | System | Hostname, timezone, locale |
| `cpu.hery` | System/CPU | 2 vCPUs |
| `memory.hery` | System/Memory | 2048 MB RAM |

### Entity Relationships

```
vm.hery
├── _requires: infrastructure.hery  (provider config)
└── _requires: os.hery              (which OS to install)

cpu.hery
└── _requires: vm.hery              (CPU allocation for this VM)

memory.hery
└── _requires: vm.hery              (memory allocation for this VM)

os-preference.hery
└── _extends: os.hery               (inherits OS identity, adds tool preferences)

system.hery                          (standalone — hostname/timezone/locale)
```

The DAG execution order would be:
1. `os.hery` + `infrastructure.hery` (no dependencies)
2. `vm.hery` (depends on infrastructure + os)
3. `cpu.hery` + `memory.hery` (depend on vm)

## Step-by-Step

### 1. Review the entities

Read each `.hery` file to understand what's being declared. Key points:

- **`vm.hery`** — `box` points to the local ISO. `gui: true` opens a virt-viewer window so you can interact with the Rocky installer. Port 22 on the guest is forwarded to 2222 on the host.
- **`cpu.hery` / `memory.hery`** — Resource allocation is separate from the VM entity (HERY design: CPU/memory are their own entity types linked via `_requires`).
- **`os-preference.hery`** — Tells downstream tools (lay, enjoin) which backends to use. Not consumed by raise itself, but part of the full entity set.

### 2. Provision the VM

```bash
raise up rocky-demo --from libvirt -f vm.hery
```

This tells raise to delegate to `raise-libvirt`, which runs `virt-install` under the hood.

### 3. Check status

```bash
raise status rocky-demo --from libvirt
```

### 4. SSH into the VM

```bash
raise ssh rocky-demo --from libvirt
```

Or directly:

```bash
ssh -p 2222 root@localhost
```

### 5. Halt / Destroy

```bash
raise halt rocky-demo --from libvirt
raise destroy rocky-demo --from libvirt
```

## Known Limitation: ISO vs Cloud Image

**raise-libvirt currently treats `box` as a disk image** (qcow2). It passes the path to `virt-install --disk`, which works for pre-built cloud images but not for ISO boot installs.

For an ISO install, `virt-install` needs:

```bash
virt-install \
  --name rocky-demo \
  --vcpus 2 \
  --memory 2048 \
  --disk size=20,format=qcow2 \
  --cdrom /home/jn/Projects/OS/Rocky-10.1-x86_64-minimal.iso \
  --os-variant rocky9 \
  --network network=default,model=virtio \
  --graphics spice
```

The key difference: `--cdrom` for the ISO + a blank `--disk` to install onto. The plugin would need to detect ISO files (by extension or content) and switch to `--cdrom` mode instead of passing the ISO as a disk image.

### What raise-libvirt needs to support this

The `resolveBoxImage` / `buildVirtInstallArgs` functions in `raise-libvirt/libvirt/libvirt.go` need:

1. **ISO detection** — check if `box` path ends in `.iso`
2. **Different virt-install args** — use `--cdrom <iso>` + `--disk size=N,format=qcow2` (blank disk)
3. **GUI default** — ISO installs need `gui: true` (interactive installer), so default to `--graphics spice` when ISO detected
4. **OS variant mapping** — map entity OS info to `--os-variant` (e.g., rocky → rocky9)

Until then, this quickstart documents the **target entity model** — the entities are correct, but `raise-libvirt` needs the ISO boot path implemented.

## Full Pipeline (Future)

Once raise supports ISO boot, the full Amadla pipeline for this quickstart would be:

```bash
amadla run --config tools.hery -f .
```

Which processes the entity DAG:
1. **raise** → creates the VM from ISO (interactive install)
2. **lay** → installs packages (reads os-preference for dnf)
3. **enjoin** → configures system state (hostname, firewall, SELinux)
4. **weaver** → generates config files from templates
