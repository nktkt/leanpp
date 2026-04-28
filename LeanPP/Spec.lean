/-
  LeanPP/Spec.lean
  ----------------------------------------------------------------------------
  Surface-syntax DSL for specifications.

  Implemented in this file:
    * `spec def` — function definition with `requires` / `ensures` /
      `decreases` / proof obligations.
    * `concept` / `law` — bundled algebraic structure with named laws.
    * `obligation` — `theorem ... := by sorry` plus `@[obligation]` tag.
    * `#obligations` — list every unsolved obligation in the environment.

  All macros lower to ordinary Lean 4 declarations (`def`, `theorem`,
  `class`, attributes). The kernel is never touched.
-/
import Lean
import LeanPP.Auto
import LeanPP.Trust

namespace LeanPP.Spec

open Lean Elab Command

/-! ## spec def

  Surface form:

  ```
  spec def double (x : Nat) : Nat
    requires True
    ensures  fun result => result = 2 * x
    := 2 * x
  ```

  Lowers to:

  ```
  def double (x : Nat) : Nat := 2 * x
  @[obligation]
  theorem double.ensures_1 (x : Nat) (_h : True) :
      (fun result => result = 2 * x) (double x) := by LeanPP.auto
  ```
-/

/-- One clause inside a `spec def`. -/
declare_syntax_cat leanpp_spec_clause

syntax "requires"  term            : leanpp_spec_clause
syntax "ensures"   term            : leanpp_spec_clause
syntax "decreases" term            : leanpp_spec_clause

/-- The headline `spec def` command. -/
syntax (name := specDefCmd)
  "spec" "def" ident bracketedBinder* ":" term
    (colGt leanpp_spec_clause)*
    ":=" term : command

/-- Helper: extract `requires` / `ensures` / `decreases` from a clause list.
    Returns `(requires, ensures, decreases?)`. -/
private def partitionClauses (cls : Array Syntax) :
    CommandElabM (Array Term × Array Term × Option Term) := do
  let mut reqs   : Array Term := #[]
  let mut enss   : Array Term := #[]
  let mut decr   : Option Term := none
  for c in cls do
    match c with
    | `(leanpp_spec_clause| requires $t:term)  => reqs := reqs.push t
    | `(leanpp_spec_clause| ensures  $t:term)  => enss := enss.push t
    | `(leanpp_spec_clause| decreases $t:term) => decr := some t
    | _ => throwErrorAt c "leanpp: malformed spec clause"
  return (reqs, enss, decr)

/-- Build the conjunction of preconditions; `True` if there are none. -/
private def conjunctRequires (reqs : Array Term) : CommandElabM Term := do
  if reqs.size = 0 then
    `(True)
  else
    let mut acc : Term := reqs[0]!
    for t in reqs[1:] do
      acc ← `($acc ∧ $t)
    return acc

/-- Pull plain identifiers out of a `bracketedBinder` for use as call args.
    A `bracketedBinder` has shape `( name1 name2 ... : type )` (or `{}` /
    `[]`). The bound names are always in the *second* node (`raw[1]`) of
    the bracket node, which is itself a `null` node holding identifiers. -/
private def binderArgIdents (bs : Array (TSyntax `Lean.Parser.Term.bracketedBinder)) :
    CommandElabM (Array Term) := do
  let mut acc : Array Term := #[]
  for b in bs do
    let raw := b.raw
    -- Try the explicit-binder shape first: `( ids : type )`.
    -- raw[0] is the open bracket, raw[1] is the names, raw[2] is `: type`.
    if raw.getNumArgs >= 2 then
      let names := raw[1]!
      for n in names.getArgs do
        if n.isIdent then
          acc := acc.push ⟨n⟩
  return acc

@[command_elab specDefCmd]
def elabSpecDef : CommandElab := fun stx => do
  match stx with
  | `(specDefCmd|
        spec def $name:ident $bs:bracketedBinder* : $ty:term
          $cls:leanpp_spec_clause*
          := $body:term) => do
      let (reqs, enss, _decr?) ← partitionClauses cls
      -- 1) Emit the underlying definition.
      let defCmd ← `(def $name $bs* : $ty := $body)
      elabCommand defCmd
      -- 2) Build the call expression `name b1 b2 ...`.
      let argIdents ← binderArgIdents bs
      let head := mkIdent name.getId
      let callExpr : Term ←
        if argIdents.isEmpty then
          `($head)
        else
          `($head $argIdents*)
      -- 3) Build the precondition (conjunction of `requires` clauses).
      let preTerm ← conjunctRequires reqs
      -- 4) For each `ensures`, emit `@[obligation] theorem name.ensures_<i>`.
      let ns := name.getId
      for i in [0:enss.size] do
        let post := enss[i]!
        let baseName := ns ++ Name.mkSimple s!"ensures_{i+1}"
        let thmName := mkIdent baseName
        -- The proof first tries `auto`, then `auto` after `unfold $name`
        -- so postconditions referring to the body of the just-defined
        -- function (e.g. `result * d ≤ n` where `result = n / d`) can
        -- close. If both fail, the obligation is left as a `sorry` and
        -- surfaces in `#obligations` / `#trust`. Each branch ends in
        -- `done` so a tactic that simplifies but does not close cannot
        -- be accepted by `first` — without that, the macro would emit
        -- "unsolved goals" errors instead of falling through to sorry.
        let thmCmd ← `(
          theorem $thmName $bs* (_h : $preTerm) :
              ($post) ($callExpr) := by
            first
              | (auto; done)
              | (unfold $name:ident; auto; done)
              | (intros; unfold $name:ident; auto; done)
              | sorry)
        try
          elabCommand thmCmd
          -- Tag the theorem as a (potentially sorry-backed) obligation so
          -- the trust ledger can find it.
          let resolved ← liftCoreM (Lean.realizeGlobalConstNoOverload thmName)
          liftCoreM (LeanPP.Trust.obligationAttr.setTag resolved)
        catch e =>
          logWarningAt post m!"leanpp: failed to emit ensures-theorem: {e.toMessageData}"
  | _ => throwUnsupportedSyntax

/-! ## concept / law -/

/-- `concept Name (α : Type) where field : T ...` — bundle a structure
    with named laws. The body uses Lean's standard `structFields` grammar,
    which already handles indentation-sensitive field parsing correctly.
    Phase 1 limitation: there is no inline `law` keyword inside a concept;
    every field — data or proposition — is just a class field. To tag a
    free-standing theorem as a structural law, use `@[law] theorem ...`
    (the `law` attribute is registered in `LeanPP.Trust`). -/
syntax (name := conceptCmd)
  "concept" ident bracketedBinder* "where"
    Lean.Parser.Command.structFields : command

@[command_elab conceptCmd]
def elabConcept : CommandElab := fun stx => do
  match stx with
  | `(conceptCmd|
        concept $cname:ident $bs:bracketedBinder* where
          $fields:structFields) => do
      let cmd ← `(class $cname $bs* where $fields:structFields)
      elabCommand cmd
  | _ => throwUnsupportedSyntax

/-! ## obligation -/

/-- `obligation NAME : PROP` — declare an unsolved verification obligation.
    Lowers to `@[obligation] theorem NAME : PROP := by sorry`. -/
syntax (name := obligationCmd)
  "obligation" ident " : " term : command

@[command_elab obligationCmd]
def elabObligation : CommandElab := fun stx => do
  match stx with
  | `(obligationCmd| obligation $n:ident : $t:term) => do
      let cmd ← `(theorem $n : $t := by sorry)
      elabCommand cmd
      let resolved ← liftCoreM (Lean.realizeGlobalConstNoOverload n)
      liftCoreM (LeanPP.Trust.obligationAttr.setTag resolved)
  | _ => throwUnsupportedSyntax

/-! ## #obligations -/

/-- True for decls whose own definition uses `sorryAx`. Imports are filtered
    by `#obligations` and `#laws` so the report focuses on user code. -/
private def declUsesSorry (env : Environment) (c : ConstantInfo) : Bool :=
  match c.value? (allowOpaque := true) with
  | some e => e.hasSorry
  | none   => c.type.hasSorry

/-- True for decls that originate in the *current* module (not imports). -/
private def declIsCurrentModule (env : Environment) (n : Name) : Bool :=
  env.getModuleIdxFor? n |>.isNone

/-- `#obligations` — print every `@[obligation]`-tagged declaration in the
    current module along with whether it is solved. -/
syntax (name := obligationsCmd) "#obligations" : command

@[command_elab obligationsCmd]
def elabObligations : CommandElab := fun _ => do
  let env ← getEnv
  let mut total := 0
  let mut unsolved := 0
  let mut lines : Array String := #[]
  for (n, c) in env.constants.toList do
    if n.isInternal then continue
    if !declIsCurrentModule env n then continue
    if LeanPP.Trust.obligationAttr.hasTag env n then
      total := total + 1
      if declUsesSorry env c then
        unsolved := unsolved + 1
        lines := lines.push s!"  [unsolved] {n}"
      else
        lines := lines.push s!"  [solved]   {n}"
  let header := s!"Obligations: {total} total, {unsolved} unsolved"
  if total == 0 then
    logInfo header
  else
    logInfo (header ++ "\n" ++ String.intercalate "\n" lines.toList)

/-! ## #laws -/

/-- `#laws` — print every `@[law]`-tagged declaration in the current module
    along with whether it is fully proved. Useful for surveying the algebraic
    laws that a project's instances are expected to honour. -/
syntax (name := lawsCmd) "#laws" : command

@[command_elab lawsCmd]
def elabLaws : CommandElab := fun _ => do
  let env ← getEnv
  let mut total := 0
  let mut openLaws := 0
  let mut lines : Array String := #[]
  for (n, c) in env.constants.toList do
    if n.isInternal then continue
    if !declIsCurrentModule env n then continue
    if LeanPP.Trust.lawAttr.hasTag env n then
      total := total + 1
      if declUsesSorry env c then
        openLaws := openLaws + 1
        lines := lines.push s!"  [open]   {n}"
      else
        lines := lines.push s!"  [proved] {n}"
  let header := s!"Laws: {total} total, {openLaws} open"
  if total == 0 then
    logInfo header
  else
    logInfo (header ++ "\n" ++ String.intercalate "\n" lines.toList)

end LeanPP.Spec
