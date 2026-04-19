# HERY CLI E2E Tests

End-to-end tests for the `hery` CLI covering local entity resolution, `_extends` merging, `_requires` dependency tracking, and multi-layer caching.

## Test Cases

| # | Directory | What it tests |
|---|-----------|---------------|
| 1 | `single-entity/` | One `.hery` file, no `_requires`, no `_extends` |
| 2 | `local-entity/` | Multiple `.hery` files in one directory with `_requires` — one local entity, one layer |
| 3 | `extends-local/` | `_extends` within same directory — data merge inheritance |
| 4 | `two-layers/` | Directory includes an external directory — two merge layers |
| 5 | `three-layers/` | C includes B includes A — three merge layers |
| 6 | `extends-external/` | `_extends` referencing an entity in another directory |
| 7 | `mixed/` | Both `_requires` and `_extends` together — orthogonality |

## Running

```bash
# Run all tests
./run-all.sh

# Run a single test
./single-entity/test.sh
```

## Terminology

- **Entity**: a single `.hery` file
- **Local entity**: all `.hery` files in one directory, combined as one unit
- **Layer**: a merge depth from cross-directory inclusion (includer = layer 1)
