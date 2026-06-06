# Verification Status — Merkle Agreement

**Last run: 2026-05-31** · TLC (TLA2Tools) · Java 17 · exhaustive within the stated bounds.

Both configurations completed with **0 errors** (no invariant or temporal-property
violation). Raw logs are in `logs/`.

## `Vortex_DSE_CSlot_AE.tla`

| Config | Constants | States (generated / distinct) | Depth | Result |
|--------|-----------|-------------------------------|-------|--------|
| `..._tiny.cfg` (safety) | Nodes={n1,n2}, MsgIDs={m1,m2}, MaxSlot=2 | 79,601 / 10,000 | 23 | **0 errors** |
| `..._liveness.cfg` | Nodes={n1,n2}, MsgIDs={m1}, MaxSlot=1 | 426 / 120 | 12 | **0 errors** |

Safety invariants checked: `TypeInvariant`, `MerkleAgreement`, `CommittedSupersetsProcessed`,
`NoPhantomInCommitted`, `NoReorderAcrossCslot`, `PhaseProgressionValid`.
Temporal properties checked: `EventualCommit`, `EventualAgreement`.

## Scope note

These are **bounded** model-checking results (small finite instances), not unbounded
proofs. They exhaustively cover the state space within the listed constants.
