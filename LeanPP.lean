/-
  LeanPP.lean
  ----------------------------------------------------------------------------
  Root module of the Lean++ MVP standard library. Re-exports every
  sub-module so users can `import LeanPP` and have the full surface.
-/
import LeanPP.Auto
import LeanPP.Trust
import LeanPP.Spec
import LeanPP.Refine
import LeanPP.Foreign
import LeanPP.Project
import LeanPP.Std.List
import LeanPP.Std.Array
import LeanPP.Std.Map
import LeanPP.Std.Nat
import LeanPP.Std.Option
import LeanPP.Std.String
import LeanPP.Std.Bool

namespace LeanPP

/-- LeanPP MVP version. -/
def version : String := "0.1.0"

/-- Underlying Lean toolchain string this build targets. -/
def leanToolchain : String := "leanprover/lean4:v4.30.0-rc2"

/-- Short banner used by the CLI / `#leanpp_about` command. -/
def banner : String :=
  s!"Lean++ MVP {version} (on {leanToolchain})"

/-- `#leanpp_about` — print the LeanPP version banner. -/
syntax (name := leanppAboutCmd) "#leanpp_about" : command

open Lean Elab Command in
@[command_elab leanppAboutCmd]
def elabLeanppAbout : CommandElab := fun _ => do
  logInfo banner

end LeanPP
