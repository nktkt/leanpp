import Lake
open Lake DSL

package leanpp where
  -- options for downstream packages using Lean++
  leanOptions := #[⟨`pp.unicode.fun, true⟩]

@[default_target]
lean_lib LeanPP where
  -- root LeanPP.lean and LeanPP/*.lean
  globs := #[.andSubmodules `LeanPP]
