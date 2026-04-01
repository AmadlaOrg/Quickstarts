# Weaver Quickstarts

End-to-end demos for each Weaver template engine plugin. Each subdirectory contains:

- `data/` — Sample input data (JSON and YAML)
- `templates/` — Template files for the specific engine
- `expected/` — Expected rendered output
- `test.sh` — E2E test script that renders templates and compares against expected output

## Running all tests

```bash
./run-all.sh
```

## Plugins

| Directory | Engine | Language |
|-----------|--------|----------|
| `weaver-jinja2/` | Jinja2 | Python |
| `weaver-go/` | Go text/template | Go |
| `weaver-mustache/` | Mustache | Go |
| `weaver-qute/` | Quarkus Qute | Java (GraalVM native) |
| `weaver-freemarker/` | Apache FreeMarker | Java/Spring Boot 4 (GraalVM native) |

## Scenario

Each demo renders configuration for a sample **nginx** web application:
1. A single-server config from a JSON object
2. A multi-upstream config from a YAML list
3. A systemd unit file from YAML data
