# TLAPS next target — `Vortex_DSE_CSlot_AE.tla`

## Why this module (chosen from the public bundle)

| Public TLA | Repo | TLAPS today? | Verdict |
|------------|------|--------------|---------|
| `Vortex_DSE_CSlot.tla` (default) | proofs | **Yes** — `TypeInvariant`, `NoFutureAdmission` | Done |
| `Vortex_DSE_CSlot.tla` (strict) | spec | No (TLC only) | Same layer as proofs; different rule |
| `Vortex_DSE_CSlot_Skew.tla` | spec | No | Harder; adversary + per-node clocks |
| **`Vortex_DSE_CSlot_AE.tla`** | **merkle** | **No** (TLC + Apalache bounded) | **Next** — agreement layer after admission |

This is the natural **second part of the machine**: admission is proved in
`vortex-dse-cslot-proofs`; per-slot agreement is the public slice that still
has only bounded checking.

## Target theorems (proposed order)

1. `Spec => []TypeInvariant`
2. `Spec => []MerkleAgreement` (headline)
3. `Spec => []CommittedSupersetsProcessed`
4. `Spec => []NoPhantomInCommitted`
5. `Spec => []NoReorderAcrossCslot`
6. `PhaseProgressionValid` — likely redundant with `TypeInvariant` (subsumed)

Liveness (`EventualCommit`, `EventualAgreement`) — **later**; needs fairness
(`LiveSpec`), same as admission repo left `TickProgress` for TLC only.

## Proof sketch notes

- **MerkleAgreement** is almost structural after `Reconcile`: all nodes receive
  the same `union_view`. Main work is showing it is **preserved** by other
  steps (stutter, `Submit`, `Process`, `Freeze`, `DuplicateInject`, `NextCslot`).
- **CommittedSupersetsProcessed** — `Reconcile` sets `committed_set[n]` to a
  superset of each `processed[n]` by construction.
- **NoPhantomInCommitted** — needs network witness for each id in the union;
  may require strengthening if `Reconcile` alone is not inductive.
- No crash/rejoin in this module (by design) — keeps AE proofs separate from
  admission `Rejoin` (see spec comments on the 2026-05-27 spurious trace).

## Files

- `Vortex_DSE_CSlot_AE.tla` — spec (this repo)
- `Vortex_DSE_CSlot_AE_Proofs.tla` — TLAPS module (scaffold; run `tlapm` locally)

## Reproduce (when proofs land)

```sh
tlapm --toolbox 0 0 Vortex_DSE_CSlot_AE_Proofs.tla
```

Install [TLAPS](https://github.com/tlaplus/tlapm). This environment does not
ship `tlapm`; proofs must be closed on a machine with TLAPS installed.
