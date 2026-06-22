# AGENTS.md

## Cursor Cloud specific instructions

This repository is a **TLA+ formal specification** (no compiled app, no package
manager). The "application" is two model checkers run against
`Vortex_DSE_CSlot_AE.tla`. There is nothing to build or serve; verification runs
are the way to exercise the code.

### Toolchain (installed by the startup update script into `~/tools`)

- `~/tools/tla2tools.jar` — TLC / SANY (TLA2Tools).
- `~/tools/apalache/bin/apalache-mc` — Apalache symbolic checker (v0.58+).
- Java is already on the system (`java -version`, OpenJDK 21). The repo's
  documented minimums are Java 11+ for TLC and Java 17+ for Apalache, both
  satisfied.

The `*.jar` and tool dirs are gitignored, so they never get committed. They live
outside the repo in `~/tools` and persist via the VM snapshot; the update script
re-fetches them only if missing.

### Run the checks

The helper scripts are not marked executable — invoke them with `bash`.

- TLC (safety + liveness, ~2s):
  `bash run_tlc.sh ~/tools/tla2tools.jar`
  Writes `logs/tlc_ae_safety.log` and `logs/tlc_ae_liveness.log` (gitignored).
  Expect `No error has been found` in both.
- Apalache (symbolic, ~15s):
  `APALACHE_BIN=~/tools/apalache/bin/apalache-mc bash run_apalache.sh`
  Expect `The outcome is: NoError` / `EXITCODE: OK`. Apalache writes to
  `_apalache-out/` (gitignored).

There is no lint step. "Linting" for TLA+ is parse/type checking, which TLC's
SANY parser and Apalache's Snowcat type checker perform as part of the runs
above.

### Not available here

- `tlapm` (TLAPS proof manager) is **not** installed. `Vortex_DSE_CSlot_AE_Proofs.tla`
  is a proof scaffold that requires TLAPS; do not expect to discharge proofs in
  this environment (see `TLAPS_NEXT.md`).
