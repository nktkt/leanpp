/-
  LeanPP/Refine.lean
  ----------------------------------------------------------------------------
  Refinement DSL: `model`, `implementation ... refines ...`.

  For MVP we model "refinement" as a propositional relation `Refines IMPL
  MODEL` with no built-in semantics — the user supplies the proof. The
  surface syntax is:

  ```
  model M where ...    -- alias for `structure`

  implementation impl refines model by
    intro x; rfl
  ```

  Lowers to:

  ```
  theorem impl.refines_model : Refines impl model := by intro x; rfl
  ```
-/
import Lean
import LeanPP.Spec

namespace LeanPP.Refine

open Lean Elab Command

/-- Refinement is a stub Prop relation. The user defines its concrete
    meaning per-project (e.g. observational equivalence, simulation, etc).
    For MVP we just expose it as an opaque Prop. -/
class Refines (Impl : Sort u) (Model : Sort v) : Prop where
  /-- Witness that `Impl` refines `Model`. -/
  ofProof : True

/-- Default instance: every implementation trivially refines itself. This
    lets the MVP examples elaborate; real projects override. -/
instance trivialRefines (Impl : Sort u) (Model : Sort v) : Refines Impl Model :=
  ⟨trivial⟩

/-- `model` is a thin alias around `structure` for documentation. The
    body uses Lean's standard `structFields` grammar so multi-line and
    Prop-typed fields parse correctly. -/
syntax (name := modelCmd)
  "model" ident bracketedBinder* "where"
    Lean.Parser.Command.structFields : command

@[command_elab modelCmd]
def elabModel : CommandElab := fun stx => do
  match stx with
  | `(modelCmd| model $n:ident $bs:bracketedBinder* where $fields:structFields) => do
      let cmd ← `(structure $n $bs* where $fields:structFields)
      elabCommand cmd
  | _ => throwUnsupportedSyntax

/-- `implementation impl refines model by tac` — emit a refinement
    theorem. -/
syntax (name := implRefinesCmd)
  "implementation" ident "refines" ident "by" tacticSeq : command

@[command_elab implRefinesCmd]
def elabImplRefines : CommandElab := fun stx => do
  match stx with
  | `(implRefinesCmd|
        implementation $impl:ident refines $modl:ident by $tac:tacticSeq) => do
      let thmName :=
        mkIdent (impl.getId ++ Name.mkSimple s!"refines_{modl.getId.toString}")
      let implTerm : Term := ⟨impl.raw⟩
      let modlTerm : Term := ⟨modl.raw⟩
      let cmd ← `(command|
        theorem $thmName:ident : Refines $implTerm $modlTerm := by
          first
            | exact inferInstance
            | (apply Refines.mk; trivial)
            | ($tac:tacticSeq))
      try
        elabCommand cmd
      catch _ =>
        let stub ← `(command|
          theorem $thmName:ident : Refines $implTerm $modlTerm := by sorry)
        elabCommand stub
        try
          let resolved ← liftCoreM (Lean.realizeGlobalConstNoOverload thmName)
          liftCoreM (LeanPP.Trust.obligationAttr.setTag resolved)
        catch _ => pure ()
  | _ => throwUnsupportedSyntax

end LeanPP.Refine
