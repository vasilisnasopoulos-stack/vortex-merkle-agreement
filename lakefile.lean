import Lake
open Lake DSL

package «vortex_merkle_agreement» where

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "master"

@[default_target]
lean_lib «VortexMerkleAgreement» where
  srcDir := "."
  globs := #[.one `Vortex_DSE_CSlot_AE_Lean]
