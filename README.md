> **Vortex DSE public verification bundle**
>
> [Proofs](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) · [Strict spec](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec) · [Merkle agreement](https://github.com/vasilisnasopoulos-stack/vortex-merkle-agreement)

# Vortex DSE — Merkle Agreement

[![TLC verification](https://img.shields.io/badge/TLC-bounded_checks_passing-brightgreen)](./STATUS.md)
[![Apalache verification](https://img.shields.io/badge/Apalache-bounded_checks_passing-brightgreen)](./STATUS.md)

TLA+ specification for the **per-slot input-set agreement** layer of Vortex DSE.
After C-slot admission, correct live nodes converge on the same committed input set for that slot.

## Agreement layer in one paragraph

This repository isolates the agreement layer that runs after admission: nodes first stop admitting
new inputs for slot `k` (**Freeze**), then exchange and union observations (**Reconcile**), and
finally commit only when the resulting set identity matches by hash/Merkle root (**Commit**).
The goal is deterministic slot agreement with explicit assumptions and reproducible model checks.

## Why this repo matters

This repo is for readers who want the agreement layer, not just the admission rule.
It shows how nodes converge on one committed set per slot under the declared assumptions.

## Position in the public verification bundle

| Repository | Role | Verification status |
|---|---|---|
| [vortex-dse-cslot-proofs](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) | Late-tolerant C-slot admission; deductive safety proofs | TLAPS: `[]TypeInvariant`, `[]NoFutureAdmission`; all 194 obligations proved |
| [vortex-dse-cslot-spec](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec) | Strict C-slot admission, clock skew, Byzantine timestamp/origin spoofing, executable reference | TLC bounded checks; JavaScript reference scenarios |
| **vortex-merkle-agreement** ← you are here | Per-slot input-set agreement: Freeze → Reconcile → Commit | TLC + Apalache bounded checks under declared assumptions |

## One-sentence summary

Freeze admission for the slot, reconcile the node views, confirm equality by Merkle/hash roots, then commit the same input set everywhere.

## Protocol shape

```text
C-slot admission
    ↓
Local processed set
    ↓
Freeze admission for slot k
    ↓
Reconcile node views
    ↓
Merkle/hash equality confirms identical set
    ↓
Commit slot-final input set
```

## Visual architecture

```text
            ┌───────────────────────────────────────────────┐
            │             Vortex DSE (slot k)               │
            └───────────────────────────────────────────────┘
                             │
                    admitted inputs (per node)
                             │
                 ┌──────────────────────────────────────────────┐
                 │  Merkle Agreement: Freeze → Reconcile → Commit  │
                 └──────────────────────────────────────────────┘
                             │
                   identical committed_set[k]
                             │
                  shared Merkle/hash root[k]
```

## Freeze → Reconcile → Commit (visual)

```text
OPEN
  └─ Freeze slot k
      (admission closed, local processed set snapshot)
           ↓
RECONCILE
  └─ Exchange summaries/sets
  └─ Union observed inputs for slot k
  └─ Compute candidate root
           ↓
COMMIT
  └─ Commit only when compared roots imply same set identity
  └─ Result: MerkleAgreement holds for committed correct live nodes
```

## Headline property

The headline property is `MerkleAgreement`:

> any two committed correct live nodes hold an identical `committed_set` for the current slot.

## What this repo is not

- Not the admission rule itself.
- Not the full end-to-end consensus/finality story.
- Not the private lossy or exactly-once refinements.

## Quick start (first-time visitors)

1. Read **Agreement layer in one paragraph** and **Freeze → Reconcile → Commit (visual)**.
2. Open `Vortex_DSE_CSlot_AE.tla` and locate `MerkleAgreement`.
3. Check assumptions and bounded results in `STATUS.md`.
4. Run TLC and Apalache locally (see **Reproduce** section).
5. Read `ARCHITECTURE.md` for bundle-level context.
6. See `CONTRIBUTING.md` if you want to submit improvements.

## Reproduce

### TLC

```sh
./run_tlc.sh /path/to/tla2tools.jar
```

### Apalache

```sh
APALACHE_BIN=/path/to/apalache-mc ./run_apalache.sh
```

## Suggested reviewer path

1. Read the one-sentence summary.
2. Inspect the claims matrix and assumptions.
3. Check the phase transition model: open, frozen, committed.
4. Run TLC and Apalache.
5. Continue to the admission repos to see what this layer depends on.
