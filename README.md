> **Vortex DSE public verification bundle**
>
> [Proofs](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) · [Strict spec](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec) · [Merkle agreement](https://github.com/vasilisnasopoulos-stack/vortex-merkle-agreement)

# Vortex DSE — Merkle Agreement

TLA+ specification for the **per-slot input-set agreement** layer of Vortex DSE.
After C-slot admission, correct live nodes converge on the same committed input set for that slot.

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

## Headline property

The headline property is `MerkleAgreement`:

> any two committed correct live nodes hold an identical `committed_set` for the current slot.

## What this repo is not

- Not the admission rule itself.
- Not the full end-to-end consensus/finality story.
- Not the private lossy or exactly-once refinements.

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
