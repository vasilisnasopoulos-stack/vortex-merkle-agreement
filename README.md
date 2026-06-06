# Vortex DSE — Merkle Agreement (per-slot input-set agreement)

A TLA+ specification proving that all correct live nodes end a slot holding the
**same input set**, cryptographically verified by Merkle-root equality.

## The property

After admission, each live node runs a three-step barrier inside the residual
portion of the slot:

1. **Freeze** — close the local admission window for the slot.
2. **Reconcile** — exchange views and converge on the **union** of admitted ids,
   verified by Merkle-root equality (abstracted here as a single atomic union;
   the implementation runs a Bloom round + repeated Merkle/hashlist).
3. **Commit** — adopt a slot-final input set that is **bit-identical across all
   correct live nodes**.

The headline invariant `MerkleAgreement` states: any two committed nodes hold an
identical `committed_set` for the current slot.

## Invariants & liveness

- `MerkleAgreement` (headline) — committed nodes hold identical sets.
- `CommittedSupersetsProcessed` — Reconcile only adds; no local rollback.
- `NoPhantomInCommitted` — committed ids correspond to real network records.
- `NoReorderAcrossCslot` — an id admitted in slot *k* keeps stamp *k*.
- `PhaseProgressionValid` — `open → frozen → committed` only.
- `EventualCommit` / `EventualAgreement` — liveness under fairness.

## Declared assumptions (operational envelope)

- **A1 — bounded clock skew.** `Δ_skew < Δt / 2`. Justifies abstracting per-node
  clocks as a single global slot counter: at any real-time instant all correct
  nodes observe the same slot (modulo edge transitions).
- **A2 — freeze barrier within slot.** The agreement phase runs in the residual
  portion of the slot after the admission deadline.
- **A3 — reconcile completeness under bounded loss.** Modeled explicitly in the
  companion *loss-recoverability* spec.
- **A4 — all-live during the agreement phase.** The participant set is fixed at
  Freeze. Crash/rejoin during the phase is out of scope here.

### Out of scope (honest limits)

- Crash/rejoin during the agreement phase.
- A full partition where **no** node receives a message (then it is legitimately
  deferred to a later slot by the producer; not an agreement violation).
- The multi-round Bloom+Merkle wire protocol details — the abstract
  `Reconcile = union` is the *specification* those rounds must refine.

## Reproduce

Two independent checkers verify the same specification.

**TLC** (explicit-state) — requires Java 11+ and `tla2tools.jar`:

```sh
./run_tlc.sh /path/to/tla2tools.jar
```

**Apalache** (symbolic / SMT-backed) — requires Apalache ≥ 0.58 and Java 17+. The
harness `MC_Vortex_DSE_CSlot_AE.tla` fixes the constants and bundles every safety
invariant as `AllInv`:

```sh
APALACHE_BIN=/path/to/apalache-mc ./run_apalache.sh   # default length 8
```

TLC writes logs to `logs/`; Apalache writes to `_apalache-out/`. See `STATUS.md`
for the latest results from both checkers.

## License

Released under the [Apache License 2.0](LICENSE). Copyright 2026 Vasilis Nasopoulos.
