# Verification Status — Merkle Agreement

**Last run: 2026-05-31** · TLC (TLA2Tools) · Java 17 · exhaustive within the stated bounds.

Both configurations completed with **0 errors** (no invariant or temporal-property
violation). TLC logs are generated locally via `./run_tlc.sh` (not committed;
see `.gitignore`). Committed Apalache per-invariant logs are in `apalache/ae_logs/`.

## `Vortex_DSE_CSlot_AE.tla`

| Config | Constants | States (generated / distinct) | Depth | Result |
|--------|-----------|-------------------------------|-------|--------|
| `..._tiny.cfg` (safety) | Nodes={n1,n2}, MsgIDs={m1,m2}, MaxSlot=2 | 79,601 / 10,000 | 23 | **0 errors** |
| `..._liveness.cfg` | Nodes={n1,n2}, MsgIDs={m1}, MaxSlot=1 | 426 / 120 | 12 | **0 errors** |

Safety invariants checked: `TypeInvariant`, `MerkleAgreement`, `CommittedSupersetsProcessed`,
`NoPhantomInCommitted`, `NoReorderAcrossCslot`, `PhaseProgressionValid`.
Temporal properties checked: `EventualCommit`, `EventualAgreement`.

## Apalache (symbolic / SMT-backed check)

**Last run: 2026-06-06** · Apalache 0.58.0 · Java 17.

Harness `MC_Vortex_DSE_CSlot_AE.tla` with `ConstInit` (Nodes={n1,n2}, MsgIDs={a,b},
MaxSlot=1), checking `AllInv` — the conjunction of all safety invariants
(`TypeInvariant`, `MerkleAgreement`, `CommittedSupersetsProcessed`,
`NoPhantomInCommitted`, `NoReorderAcrossCslot`, `PhaseProgressionValid`) — to
computation length 8:

| Tool | Constants | Bound | Result |
|------|-----------|-------|--------|
| Apalache `check` | Nodes={n1,n2}, MsgIDs={a,b}, MaxSlot=1 | length 8 | **NoError** |

This is a second, independent verification path: TLC explores states explicitly,
Apalache discharges the invariants symbolically via SMT. Both agree.

Per-invariant Apalache logs (2026-05-27, Apalache 0.57.0, length 8): `apalache/ae_logs/`.
Reproduce: `APALACHE_BIN=/path/to/apalache-mc ./run_apalache.sh`

## Scope note

These are **bounded** model-checking results (small finite instances), not unbounded
proofs. They exhaustively cover the state space within the listed constants.
