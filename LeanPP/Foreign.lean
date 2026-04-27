/-
  LeanPP/Foreign.lean
  ----------------------------------------------------------------------------
  FFI surface — `verified extern` and the `@[ffi_contract]` attribute.

  In Lean 4 you mark a definition as foreign with `@[extern "c_name"]`. We
  layer a contract on top: `verified extern` is a command that emits both
  the foreign declaration and an `@[obligation]`-tagged theorem stating the
  contract that the user must discharge.
-/
import Lean
import LeanPP.Spec
import LeanPP.Trust

namespace LeanPP.Foreign

open Lean Elab Command

/-- `@[ffi_contract]` — tag attached to the contract theorem of a
    `verified extern`. -/
initialize ffiContractAttr : TagAttribute ←
  registerTagAttribute `ffi_contract
    "marks a theorem as the verification contract of a `verified extern`"

/-- Surface form:

    ```
    verified extern "c_my_function" mySig (x : Int) : Int
      ensures fun result => result ≥ 0
    ```

    Lowers to:
    ```
    @[extern "c_my_function"] opaque mySig (x : Int) : Int
    -- attribute [verified_extern, obligation, ffi_contract] mySig.contract
    theorem mySig.contract (x : Int) :
        (fun result => result ≥ 0) (mySig x) := by sorry
    ```
-/
syntax (name := verifiedExternCmd)
  "verified" "extern" str ident bracketedBinder* ":" term
    ("ensures" term)? : command

/-- Pull plain identifiers out of a `bracketedBinder` for use as call args. -/
private def binderArgIdents (bs : Array (TSyntax `Lean.Parser.Term.bracketedBinder)) :
    CommandElabM (Array Term) := do
  let mut acc : Array Term := #[]
  for b in bs do
    let raw := b.raw
    if raw.getNumArgs >= 2 then
      let names := raw[1]!
      for n in names.getArgs do
        if n.isIdent then
          acc := acc.push ⟨n⟩
  return acc

@[command_elab verifiedExternCmd]
def elabVerifiedExtern : CommandElab := fun stx => do
  match stx with
  | `(verifiedExternCmd|
        verified extern $sym:str $name:ident $bs:bracketedBinder* : $ty:term
          $[ensures $post?:term]?) => do
      -- 1) Emit the opaque foreign declaration. We use the `extern`
      --    attribute syntax with a string literal symbol. The attribute
      --    parser wraps the strLit in an `externEntry` automatically.
      let opaqueCmd ← `(@[extern $sym:str] opaque $name $bs* : $ty)
      elabCommand opaqueCmd
      -- 1b) Tag the opaque with verified_extern via API to avoid the
      --     keyword-collision problem that the surface `@[verified_extern]`
      --     hits because `verified` is itself a Lean++ keyword.
      try
        let resolved ← liftCoreM (Lean.realizeGlobalConstNoOverload name)
        liftCoreM (LeanPP.Trust.verifiedExternAttr.setTag resolved)
      catch _ => pure ()
      -- 2) If there's an `ensures`, emit a contract theorem.
      match post? with
      | none => pure ()
      | some post => do
          let argIdents ← binderArgIdents bs
          let head := mkIdent name.getId
          let callExpr : Term ←
            if argIdents.isEmpty then
              `($head)
            else
              `($head $argIdents*)
          let thmName := mkIdent (name.getId ++ `contract)
          let thmCmd ← `(
            theorem $thmName $bs* : ($post) ($callExpr) := by sorry)
          elabCommand thmCmd
          try
            let resolved ← liftCoreM (Lean.realizeGlobalConstNoOverload thmName)
            liftCoreM do
              LeanPP.Trust.obligationAttr.setTag resolved
              ffiContractAttr.setTag resolved
          catch _ => pure ()
  | _ => throwUnsupportedSyntax

end LeanPP.Foreign
