> **Vortex DSE formal surface** · [Proofs (default + TLAPS)](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) · [Strict spec + TLC](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec) · [Merkle agreement](https://github.com/vasilisnasopoulos-stack/vortex-merkle-agreement) · [Profile](https://github.com/vasilisnasopoulos-stack)
>
> Production C engine is **not** public. This repo is **per-slot Merkle agreement** (baseline AE). Lossy specs are staged privately.

> **Vortex public research bundle**
>
> This repository is one part of the public Vortex DSE verification bundle.
>
> [Spec](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec) · [Proofs](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) · [Merkle Agreement](https://github.com/vasilisnasopoulos-stack/vortex-merkle-agreement)

# Vortex DSE — Merkle Agreement

> **Part of one machine:** this repo checks the **agreement layer** (baseline
> per-slot Merkle agreement under ideal-network assumptions,
> `Vortex_DSE_CSlot_AE.tla` only). It follows admission in the stack
> ([proofs repo](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs))
> in design — no composed proof links them yet. Lossy recovery and cross-slot
> exactly-once modules are **not** published here.
> [How the parts connect →](https://github.com/vasilisnasopoulos-stack/blob/main/SLICES.md)

TLA+ specification for the **per-slot input-set agreement** layer of Vortex DSE. After C-slot admission, correct live nodes run a slot-local barrier and commit the same input set for that slot.

## Position in the public verification bundle

| Repository | Role | Verification status |
|---|---|---|
| [vortex-dse-cslot-proofs](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) | Late-tolerant C-slot admission; deductive safety proofs | TLAPS: `[]TypeInvariant`, `[]NoFutureAdmission`; all 194 obligations proved |
| [vortex-dse-cslot-spec](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec) | Strict C-slot admission, clock skew, Byzantine timestamp/origin spoofing, executable reference | TLC bounded checks; JavaScript reference scenarios |
| **vortex-merkle-agreement** ← you are here | Per-slot input-set agreement: Freeze → Reconcile → Commit | TLC + Apalache bounded checks under declared assumptions |

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

The headline property is `MerkleAgreement`: any two committed correct live nodes hold an identical `committed_set` for the current slot.

## The property

After admission, each live node runs a three-step barrier inside the residual portion of the slot:

1. **Freeze** — close the local admission window for the slot.
2. **Reconcile** — exchange views and converge on the union of admitted ids, verified by Merkle-root equality.
3. **Commit** — adopt a slot-final input set that is bit-identical across all correct live nodes.

In this model, `Reconcile` is represented as an abstract atomic union. The real implementation may use Bloom hints, repeated Merkle roots, hash lists, or another wire-level refinement, but that lower-level reconciliation protocol is not unfolded in this repository.

## Claims matrix

| Claim | Status | Method | Scope |
|---|---|---|---|
| Committed nodes hold identical sets | Checked | TLC + Apalache | Configured finite instances under declared assumptions |
| Committed set is a superset of locally processed ids | Checked | TLC + Apalache | Configured finite instances |
| No phantom committed ids | Checked | TLC + Apalache | Configured finite instances |
| No reorder across C-slot | Checked | TLC + Apalache | Configured finite instances |
| Phase progression is valid | Checked | TLC + Apalache | `open → frozen → committed` only |
| Eventual commit/agreement | Checked | Temporal model checking | Under declared fairness assumptions |
| Crash/rejoin during agreement phase | **Not modeled here** | — | Future composed refinement |
| Multi-round Bloom/Merkle wire protocol | **Abstracted** | — | `Reconcile` is modeled as atomic union |
| Cross-slot replay protection | **Not closed in this module alone** | — | Requires composition with global exactly-once/persistence module |
| Full end-to-end consensus/finality | **Not claimed here** | — | Out of scope of this repository |

## Declared assumptions

| Assumption | Meaning | Why it matters |
|---|---|---|
| A1 — bounded clock skew | `Δ_skew < Δt / 2` | Justifies treating correct nodes as sharing the same slot except near edge transitions |
| A2 — freeze barrier within slot | Agreement runs after admission closes and before the slot budget expires | Prevents open admission from racing with commit |
| A3 — reconcile completeness under bounded loss | Missing ids can be recovered during reconciliation | Lets the abstract union represent successful view convergence |
| A4 — all-live during the agreement phase | Participant set is fixed at Freeze | Crash/rejoin inside the agreement phase is delegated to future composed work |

These assumptions define the operational envelope of this artifact. They are not hidden; they are part of the model boundary.

## Invariants and liveness

- `MerkleAgreement` — committed nodes hold identical sets.
- `CommittedSupersetsProcessed` — reconciliation only adds; no local rollback.
- `NoPhantomInCommitted` — committed ids correspond to real network records.
- `NoReorderAcrossCslot` — an id admitted in slot `k` keeps stamp `k`.
- `PhaseProgressionValid` — phase transitions follow `open → frozen → committed`.
- `EventualCommit` / `EventualAgreement` — liveness under fairness.

## Origin and sender identity

This specification answers **which set of inputs** correct nodes agree on per slot. It deliberately does not carry a sender/origin field and therefore does not claim to solve sender spoofing or Sybil resistance inside this module.

That boundary is handled elsewhere:

- the C-slot skew/adversarial model includes an origin field and models timestamp/origin spoofing;
- production identity binding is an implementation-layer concern, e.g. keyed admission tokens, MACs, or BLS/PKI registry mechanisms.

This agreement layer reasons above that trust boundary.

## Known gaps and future refinements

These gaps do not break the properties claimed by this repository, but they are the next targets for a stronger composed bundle:

- **Cross-slot replay:** this module tracks admitted ids per slot; global exactly-once requires composition with a global persisted-id history.
- **Crash/rejoin during multi-slot agreement:** crash handling is delegated to the admission/persistence layer; a single composed crash × agreement model is future work.
- **Non-atomic reconciliation:** `Reconcile` is modeled as one atomic union; a future refinement should unfold Bloom/Merkle rounds and check mid-round crash behavior.
- **Bloom false positives:** the abstract exact-union model cannot show Bloom false-positive ghost ids. In the intended design, Bloom is only a hint and exact Merkle confirmation prevents phantom commits. Modeling that explicitly is future work.

## Sibling specifications (private staging)

This public repo ships the **baseline** agreement module (`Vortex_DSE_CSlot_AE.tla`).
Additional modules exist in private staging and are **not** published here unless
explicitly released:

| Module | Status | Property |
|--------|--------|----------|
| `Vortex_DSE_CSlot_AE.tla` | **Public (this repo)** | `MerkleAgreement` — identical committed sets per cslot |
| `Vortex_DSE_CSlot_AE_Lossy.tla` | **Private / planned** | `MerkleAgreementUnderLoss`, `LossRecoverability` under bounded drops |
| `Vortex_DSE_CSlot_AE_ExactlyOnce.tla` | **Private** | Exactly-once delivery slice — not part of public surface today |

**Related public repos:** [C-slot proofs (default)](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs) · [Strict C-slot spec](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-spec)

## Reproduce

Two independent checkers verify the same specification.

### TLC

Requires Java 11+ and `tla2tools.jar`:

```sh
./run_tlc.sh /path/to/tla2tools.jar
```

### Apalache

Requires Apalache 0.58+ and Java 17+:

```sh
APALACHE_BIN=/path/to/apalache-mc ./run_apalache.sh
```

TLC writes logs to `logs/` (generated locally; gitignored). Apalache writes to
`_apalache-out/` when you run `./run_apalache.sh`. Committed evidence:
`apalache/ae_logs/`. See `STATUS.md`.

## Suggested reviewer path

1. Read the claims matrix and assumptions table.
2. Inspect the phase transition model: open, frozen, committed.
3. Check the `MerkleAgreement` invariant and the no-phantom/no-reorder support invariants.
4. Run TLC and Apalache to reproduce bounded results.
5. Continue to the C-slot repositories to inspect admission and crash/rejoin safety.
6. Treat end-to-end composition as the next formal milestone, not as an already claimed theorem.

## TLAPS (next)

Admission has unbounded TLAPS proofs in
[vortex-dse-cslot-proofs](https://github.com/vasilisnasopoulos-stack/vortex-dse-cslot-proofs).
**This repo** is the proposed next TLAPS target (`Vortex_DSE_CSlot_AE.tla` →
`MerkleAgreement`). See `TLAPS_NEXT.md` and scaffold `Vortex_DSE_CSlot_AE_Proofs.tla`.

## License

Released under the [Apache License 2.0](LICENSE). Copyright 2026 Vasilis Nasopoulos.
