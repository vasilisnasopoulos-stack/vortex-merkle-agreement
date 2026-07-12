# Contributing to Vortex DSE — Merkle Agreement

Thanks for helping improve the Merkle agreement layer specification.

## What to contribute

- Clarifications in `README.md`, `STATUS.md`, and `ARCHITECTURE.md`
- TLA+ spec refinements in `Vortex_DSE_CSlot_AE.tla`
- Model-check harness/config updates (`MC_*.tla`, `*.cfg`)
- Reproducibility improvements in `run_tlc.sh` and `run_apalache.sh`

## Local verification

Run both existing checkers before opening a PR:

```sh
bash ./run_tlc.sh /path/to/tla2tools.jar
APALACHE_BIN=/path/to/apalache-mc bash ./run_apalache.sh
```

If a tool is missing locally, mention that in your PR notes.

## Contribution flow

1. Fork the repository and create a focused branch.
2. Keep changes minimal and scoped to one concern.
3. Update docs when behavior, assumptions, or commands change.
4. Include the verification output summary (`No error has been found`) when possible.
5. Open a PR with:
   - problem statement
   - summary of changes
   - TLC/Apalache verification notes

## Style notes

- Keep terminology consistent: **Freeze**, **Reconcile**, **Commit**, `MerkleAgreement`.
- Preserve explicit assumptions and avoid unstated guarantees.
- Prefer bounded, reproducible checks over unverifiable claims.
