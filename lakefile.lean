import Lake
open Lake DSL

package «vortex_merkle_agreement» where

require std from git "https://github.com/leanprover/std4" @ "main"

@[default_target]
lean_lib «VortexMerkleAgreement» where
  srcDir := "."
  globs := #[.one `Vortex_DSE_CSlot_AE_Lean]
