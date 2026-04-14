# Quickstart: Rocky Linux 10.1 VM from Local ISO

Provision a Rocky Linux 10.1 VM using a local ISO image with KVM/libvirt.

## Prerequisites

- KVM/QEMU installed (`qemu-system-x86_64`)
- libvirt running (`systemctl status libvirtd`)
- `virt-install` available
- Rocky Linux ISO at `/home/<user>/Projects/OS/Rocky-10.1-x86_64-minimal.iso`
- `raise` and `raise-libvirt` on PATH

## Entity Files

This quickstart defines the VM using 8 entity files — each describes one concern:

| File | Entity Type | Purpose |
|------|-------------|---------|
| `os.hery` | OS | Rocky Linux 10.1, x86_64, RHEL family |
| `preference.os.hery` | OS/Preference | Tool choices: dnf, firewalld, SELinux, nmcli |
| `infrastructure.hery` | Infrastructure | Provider = libvirt, SSH defaults |
| `vm.infrastructure.hery` | Infrastructure/VM | ISO path, disk size, port forwarding, GUI |
| `system.hery` | System | Hostname, timezone, locale |
| `cpu.system.hery` | System/CPU | 2 vCPUs |
| `memory.system.hery` | System/Memory | 2048 MB RAM |
| `mac.security.hery` | Security/MAC | SELinux enforcing mode |

### Entity Relationships

```
preference.os.hery (leaf)    mac.security.hery (leaf)    cpu.system.hery (leaf)    memory.system.hery (leaf)
       ↓                            ↓                          ↓                          ↓
      os.hery ←─────────────────────┘                       system.hery ←──────────────────┘
       ↓                                                       ↓
       └────────────→ vm.infrastructure.hery ←─────────────────┘
                              ↓
                     infrastructure.hery (entry point)
```

Each entity declares `_requires` on its dependencies using local file paths:

- `infrastructure.hery` → `_requires: [./vm.infrastructure.hery]`
- `vm.infrastructure.hery` → `_requires: [./system.hery, ./os.hery]`
- `system.hery` → `_requires: [./cpu.system.hery, ./memory.system.hery]`
- `os.hery` → `_requires: [./preference.os.hery, ./mac.security.hery]`
- `preference.os.hery` → `_extends: amadla.org/entity/os@v1.0.0` (data inheritance, not execution order)

The DAG execution order (leaves first):
1. `preference.os.hery` + `mac.security.hery` + `cpu.system.hery` + `memory.system.hery` (leaves)
2. `os.hery` + `system.hery` (depend on leaves)
3. `vm.infrastructure.hery` (depends on os + system)
4. `infrastructure.hery` (entry point, processed last)

## Step-by-Step

### 1. Review the entities

Read each `.hery` file to understand what's being declared. Key points:

- **`vm.infrastructure.hery`** — `image` points to the local ISO. `gui: true` opens a virt-viewer window so you can interact with the Rocky installer. Port 22 on the guest is forwarded to 2222 on the host.
- **`cpu.system.hery` / `memory.system.hery`** — Resource allocation is separate from the VM entity (HERY design: CPU/memory are their own entity types linked via `_requires`).
- **`preference.os.hery`** — Tells downstream tools (lay, enjoin) which backends to use. Not consumed by raise itself, but part of the full entity set.
- **`mac.security.hery`** — Declares SELinux enforcing mode. Consumed by enjoin-mac downstream.

### 2. Provision the VM

```bash
raise up rocky-demo -f infrastructure.hery
```

raise reads the `provider: libvirt` field from `infrastructure.hery` and delegates to `raise-libvirt`, which runs `virt-install` under the hood. You can also specify the provider explicitly with `--provider libvirt`.

### 3. Check status

```bash
raise status rocky-demo --provider libvirt
```

### 4. SSH into the VM

```bash
raise ssh rocky-demo --provider libvirt
```

Or directly:

```bash
ssh -p 2222 root@localhost
```

### 5. Halt / Destroy

```bash
raise halt rocky-demo --provider libvirt
raise destroy rocky-demo --provider libvirt
```

## Known Limitation: Entity Resolution

raise and raise-libvirt currently accept a single entity file (`-f <file>`). They do not resolve `_requires` or read dependent entities. The full pipeline requires `hery resolve` to build the DAG and pipe the resolved entity stream:

```bash
hery resolve ./rocky-os/ | raise up rocky-demo
```

Until `hery resolve` is implemented, raise-libvirt reads only the Infrastructure entity directly. CPU/memory values from System/CPU and System/Memory are not yet consumed by the plugin.

## Full Pipeline (Future)

Once raise supports ISO boot, the full Amadla pipeline for this quickstart would be:

```bash
amadla run --config tools.hery -f .
```

Which processes the entity DAG:
1. **raise** → creates the VM from ISO (interactive install)
2. **lay** → installs packages (reads os-preference for dnf)
3. **enjoin** → configures system state (hostname, timezone, locale, SELinux)
4. **weaver** → generates config files from templates
