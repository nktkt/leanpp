/-
  LeanPP/Project.lean
  ----------------------------------------------------------------------------
  Project metadata and theorem index stubs for Lean++ MVP.

  This module exposes lightweight metadata helpers. The CLI / transpiler
  agents read these via Lean's environment introspection.
-/
import Lean

namespace LeanPP.Project

/-- Project metadata record. Populated by the CLI's `leanpp.toml` reader. -/
structure Metadata where
  name        : String := "leanpp-project"
  version     : String := "0.1.0"
  authors     : List String := []
  profile     : String := "research"
  deriving Inhabited, Repr

/-- Default metadata used when nothing else is registered. -/
def defaultMetadata : Metadata := {}

/-- An entry in the theorem index — used by `leanpp index` to enumerate
    theorems, obligations, and refinement claims. -/
structure IndexEntry where
  name      : Lean.Name
  kind      : String       -- "theorem" | "obligation" | "refinement" | "law"
  module    : Lean.Name
  deriving Inhabited

/-- A persistent environment extension that accumulates index entries. The
    CLI reads this via the Lean server. -/
initialize indexExt : Lean.SimplePersistentEnvExtension IndexEntry (Array IndexEntry) ←
  Lean.registerSimplePersistentEnvExtension {
    addEntryFn    := fun a e => a.push e
    addImportedFn := fun ess => ess.foldl (· ++ ·) #[]
  }

/-- Record a theorem-index entry. -/
def recordEntry (e : IndexEntry) : Lean.CoreM Unit := do
  Lean.modifyEnv fun env => indexExt.addEntry env e

/-- All currently-known index entries. -/
def allEntries : Lean.CoreM (Array IndexEntry) := do
  return indexExt.getState (← Lean.getEnv)

/-- `#leanpp_index` — print the current theorem index. -/
syntax (name := leanppIndexCmd) "#leanpp_index" : command

open Lean Elab Command in
@[command_elab leanppIndexCmd]
def elabLeanppIndex : CommandElab := fun _ => do
  let entries ← liftCoreM allEntries
  if entries.isEmpty then
    logInfo "LeanPP index: (empty)"
  else
    let lines := entries.toList.map fun e =>
      s!"  {e.kind}: {e.name} (in {e.module})"
    logInfo ("LeanPP index:\n" ++ String.intercalate "\n" lines)

end LeanPP.Project
