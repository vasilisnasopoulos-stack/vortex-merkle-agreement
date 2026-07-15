import Std

set_option autoImplicit false

namespace VortexMerkleAgreement

open Classical

inductive Phase where
  | open
  | frozen
  | reconciled
  | committed
  deriving DecidableEq, Repr

structure MsgRecord (MsgId : Type) where
  id : MsgId
  cslot : Nat
  deriving Repr

structure NodeState (MsgId : Type) where
  processed : Set MsgId
  phase : Phase
  committedSet : Set MsgId
  deriving Repr

structure SystemState (Node MsgId : Type) where
  currentSlot : Nat
  network : Set (MsgRecord MsgId)
  processed : Node → Set MsgId
  phase : Node → Phase
  reconciledSet : Set MsgId
  committedSet : Node → Set MsgId

variable {Node MsgId : Type}

@[simp] def initState : SystemState Node MsgId :=
  { currentSlot := 0
    network := ∅
    processed := fun _ => ∅
    phase := fun _ => Phase.open
    reconciledSet := ∅
    committedSet := fun _ => ∅ }

def Init (s : SystemState Node MsgId) : Prop := s = initState

@[simp] def unionProcessed (s : SystemState Node MsgId) : Set MsgId :=
  { id | ∃ n : Node, id ∈ s.processed n }

def Submit (id : MsgId) (s s' : SystemState Node MsgId) : Prop :=
  (∀ m, m ∈ s.network → m.id ≠ id) ∧
  s' = { s with network := s.network ∪ {m | m.id = id ∧ m.cslot = s.currentSlot} }

def Process (n : Node) (m : MsgRecord MsgId) (s s' : SystemState Node MsgId) : Prop :=
  m ∈ s.network ∧
  s.phase n = Phase.open ∧
  m.cslot = s.currentSlot ∧
  m.id ∉ s.processed n ∧
  s' = { s with processed := Function.update s.processed n (s.processed n ∪ {m.id}) }

def Freeze (n : Node) (s s' : SystemState Node MsgId) : Prop :=
  s.phase n = Phase.open ∧
  s' = { s with phase := Function.update s.phase n Phase.frozen }

def Reconcile (s s' : SystemState Node MsgId) : Prop :=
  (∀ n : Node, s.phase n = Phase.frozen) ∧
  s' =
    { s with
      reconciledSet := unionProcessed s
      phase := fun _ => Phase.reconciled }

def Commit (s s' : SystemState Node MsgId) : Prop :=
  (∀ n : Node, s.phase n = Phase.reconciled) ∧
  (∀ n : Node, s.processed n ⊆ s.reconciledSet) ∧
  s' =
    { s with
      committedSet := fun _ => s.reconciledSet
      phase := fun _ => Phase.committed }

def NextCslot (maxSlot : Nat) (s s' : SystemState Node MsgId) : Prop :=
  s.currentSlot < maxSlot ∧
  (∀ n : Node, s.phase n = Phase.committed) ∧
  s' =
    { s with
      currentSlot := s.currentSlot + 1
      processed := fun _ => ∅
      phase := fun _ => Phase.open
      reconciledSet := ∅ }

inductive Step (maxSlot : Nat) : SystemState Node MsgId → SystemState Node MsgId → Prop where
  | submit (id : MsgId) {s s'} : Submit id s s' → Step maxSlot s s'
  | process (n : Node) (m : MsgRecord MsgId) {s s'} : Process n m s s' → Step maxSlot s s'
  | freeze (n : Node) {s s'} : Freeze n s s' → Step maxSlot s s'
  | reconcile {s s'} : Reconcile s s' → Step maxSlot s s'
  | commit {s s'} : Commit s s' → Step maxSlot s s'
  | nextCslot {s s'} : NextCslot maxSlot s s' → Step maxSlot s s'

inductive Reachable (maxSlot : Nat) : SystemState Node MsgId → Prop where
  | base : Reachable maxSlot initState
  | step {s s'} : Reachable maxSlot s → Step maxSlot s s' → Reachable maxSlot s'

-- Invariants

def TypeInvariant (maxSlot : Nat) (s : SystemState Node MsgId) : Prop :=
  s.currentSlot ≤ maxSlot

-- Mirrors the explicit TLA+ phase-domain invariant.
-- In Lean this is structurally true with the current `Phase` inductive type,
-- but we keep it as a named property to preserve correspondence with the spec.
def PhaseProgressionValid (s : SystemState Node MsgId) : Prop :=
  ∀ n : Node, s.phase n ∈ ({Phase.open, Phase.frozen, Phase.reconciled, Phase.committed} : Set Phase)

def CommittedSupersetsProcessed (s : SystemState Node MsgId) : Prop :=
  ∀ n : Node, s.phase n = Phase.committed → s.processed n ⊆ s.committedSet n

def MerkleAgreement (s : SystemState Node MsgId) : Prop :=
  ∀ n₁ n₂ : Node,
    s.phase n₁ = Phase.committed → s.phase n₂ = Phase.committed →
      s.committedSet n₁ = s.committedSet n₂

def ReconciledContainsProcessed (s : SystemState Node MsgId) : Prop :=
  ∀ n : Node, s.phase n = Phase.reconciled → s.processed n ⊆ s.reconciledSet

def Inv (maxSlot : Nat) (s : SystemState Node MsgId) : Prop :=
  TypeInvariant maxSlot s ∧
  PhaseProgressionValid s ∧
  CommittedSupersetsProcessed s ∧
  MerkleAgreement s ∧
  ReconciledContainsProcessed s

lemma init_phase_valid : PhaseProgressionValid (Node := Node) (MsgId := MsgId) initState := by
  intro n
  simp [PhaseProgressionValid]

lemma init_inv (maxSlot : Nat) : Inv (Node := Node) (MsgId := MsgId) maxSlot initState := by
  refine ⟨?_, init_phase_valid, ?_, ?_, ?_⟩
  · simp [TypeInvariant, initState]
  · intro n h
    simp [initState] at h
  · intro n₁ n₂ h₁ h₂
    simp [initState] at h₁
  · intro n h
    simp [initState] at h

lemma phase_valid_update {s : SystemState Node MsgId} {n : Node} {p : Phase}
    (hvalid : PhaseProgressionValid s)
    (hp : p ∈ ({Phase.open, Phase.frozen, Phase.reconciled, Phase.committed} : Set Phase)) :
    PhaseProgressionValid { s with phase := Function.update s.phase n p } := by
  intro k
  by_cases hk : k = n
  · subst hk
    simpa [Function.update]
  · simpa [Function.update, hk] using hvalid k

lemma unionProcessed_superset (s : SystemState Node MsgId) (n : Node) : s.processed n ⊆ unionProcessed s := by
  intro id hid
  exact ⟨n, hid⟩

lemma inv_preserved_by_step {maxSlot : Nat} {s s' : SystemState Node MsgId}
    (hinv : Inv maxSlot s) (hstep : Step maxSlot s s') :
    Inv maxSlot s' := by
  rcases hinv with ⟨htype, hphase, hsup, hagree, hreconciled⟩
  cases hstep with
  | submit id hsub =>
      rcases hsub with ⟨_, rfl⟩
      refine ⟨htype, hphase, ?_, ?_, hreconciled⟩
      · intro n h
        simpa using hsup n h
      · intro n₁ n₂ h₁ h₂
        simpa using hagree n₁ n₂ h₁ h₂
  | process n m hproc =>
      rcases hproc with ⟨_, hopen, _, _, rfl⟩
      refine ⟨htype, hphase, ?_, ?_, ?_⟩
      · intro k hk
        by_cases hkn : k = n
        · subst hkn
          simpa [hopen] using hk
        · simpa [Function.update, hkn] using hsup k hk
      · intro n₁ n₂ h₁ h₂
        simpa using hagree n₁ n₂ h₁ h₂
      · intro k hk
        by_cases hkn : k = n
        · subst hkn
          simpa [hopen] using hk
        · simpa [Function.update, hkn] using hreconciled k hk
  | freeze n hfr =>
      rcases hfr with ⟨hn, rfl⟩
      refine ⟨htype, ?_, ?_, ?_, ?_⟩
      · exact phase_valid_update hphase (by simp)
      · intro k hk
        by_cases hkn : k = n
        · subst hkn
          simp [Function.update] at hk
        · simpa [Function.update, hkn] using hsup k hk
      · intro n₁ n₂ h₁ h₂
        by_cases h1n : n₁ = n
        · subst h1n
          simp [Function.update] at h₁
        · by_cases h2n : n₂ = n
          · subst h2n
            simp [Function.update] at h₂
          · simpa [Function.update, h1n, h2n] using hagree n₁ n₂ h₁ h₂
      · intro k hk
        by_cases hkn : k = n
        · subst hkn
          simp [Function.update] at hk
        · simpa [Function.update, hkn] using hreconciled k hk
  | reconcile hrec =>
      rcases hrec with ⟨hall, rfl⟩
      refine ⟨htype, ?_, ?_, ?_, ?_⟩
      · intro n
        simp [PhaseProgressionValid]
      · intro n h
        simp at h
      · intro n₁ n₂ h₁ h₂
        simp at h₁
      · intro n h
        simp at h
        exact unionProcessed_superset s n
  | commit hcom =>
      rcases hcom with ⟨hall, hsub, rfl⟩
      refine ⟨htype, ?_, ?_, ?_, ?_⟩
      · intro n
        simp [PhaseProgressionValid]
      · intro n h
        simpa using hsub n
      · intro n₁ n₂ h₁ h₂
        simp
      · intro n h
        simp at h
  | nextCslot hnxt =>
      rcases hnxt with ⟨hlt, hall, rfl⟩
      refine ⟨?_, ?_, ?_, ?_, ?_⟩
      · simpa [TypeInvariant] using Nat.succ_le_of_lt hlt
      · intro n
        simp [PhaseProgressionValid]
      · intro n h
        simp at h
      · intro n₁ n₂ h₁ h₂
        simp at h₁
      · intro n h
        simp at h

theorem reachable_inv {maxSlot : Nat} {s : SystemState Node MsgId}
    (hreach : Reachable (Node := Node) (MsgId := MsgId) maxSlot s) :
    Inv (Node := Node) (MsgId := MsgId) maxSlot s := by
  induction hreach with
  | base =>
      simpa using init_inv (Node := Node) (MsgId := MsgId) maxSlot
  | step hreach ih hstep =>
      exact inv_preserved_by_step ih hstep

-- Requested theorem 3: TypeInvariant by trace induction

theorem reachable_typeInvariant {maxSlot : Nat} {s : SystemState Node MsgId}
    (hreach : Reachable (Node := Node) (MsgId := MsgId) maxSlot s) :
    TypeInvariant (Node := Node) (MsgId := MsgId) maxSlot s :=
  (reachable_inv hreach).1

-- Requested theorem 4: committed set is a superset of processed

theorem reachable_committedSupersetsProcessed {maxSlot : Nat} {s : SystemState Node MsgId}
    (hreach : Reachable (Node := Node) (MsgId := MsgId) maxSlot s) :
    CommittedSupersetsProcessed (Node := Node) (MsgId := MsgId) s :=
  (reachable_inv hreach).2.2.1

-- Requested theorem 5: Merkle agreement among committed nodes

theorem reachable_merkleAgreement {maxSlot : Nat} {s : SystemState Node MsgId}
    (hreach : Reachable (Node := Node) (MsgId := MsgId) maxSlot s) :
    MerkleAgreement (Node := Node) (MsgId := MsgId) s :=
  (reachable_inv hreach).2.2.2.1

theorem reachable_reconciledContainsProcessed {maxSlot : Nat} {s : SystemState Node MsgId}
    (hreach : Reachable (Node := Node) (MsgId := MsgId) maxSlot s) :
    ReconciledContainsProcessed (Node := Node) (MsgId := MsgId) s :=
  (reachable_inv hreach).2.2.2.2

-- Requested theorem 6: structural progression lemmas

lemma freeze_to_frozen {n : Node} {s s' : SystemState Node MsgId}
    (h : Freeze n s s') : s'.phase n = Phase.frozen := by
  rcases h with ⟨_, rfl⟩
  simp [Freeze, Function.update]

lemma reconcile_to_reconciled {s s' : SystemState Node MsgId}
    (h : Reconcile s s') : ∀ n : Node, s'.phase n = Phase.reconciled := by
  rcases h with ⟨_, rfl⟩
  intro n
  simp [Reconcile]

lemma commit_to_committed {s s' : SystemState Node MsgId}
    (h : Commit s s') : ∀ n : Node, s'.phase n = Phase.committed := by
  rcases h with ⟨_, _, rfl⟩
  intro n
  simp [Commit]

lemma committed_sets_equal_after_commit {s s' : SystemState Node MsgId}
    (h : Commit s s') : ∀ n₁ n₂ : Node, s'.committedSet n₁ = s'.committedSet n₂ := by
  rcases h with ⟨_, _, rfl⟩
  intro n₁ n₂
  simp [Commit]

end VortexMerkleAgreement
