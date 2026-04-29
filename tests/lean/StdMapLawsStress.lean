/-
  tests/lean/StdMapLawsStress.lean

  Machine-checked coverage of `LeanPP.Std.MapLaws` (Prop, v0.1.7)
  and `LeanPP.Std.MapLawsClass.MapLawsClass` (typeclass,
  v0.1.8 — the first stdlib user of `concept extends`).
-/
import LeanPP

namespace LeanPP.Tests.StdMapLawsStress

open LeanPP.Std

-- Prop version: signature and sorry-backed witness.
example : (α β M : Type) → [Map α β M] → Prop := MapLaws

example : ∀ (α β M : Type) [Map α β M], MapLaws α β M := by
  intros α β M _inst
  refine ⟨?_, ?_, ?_⟩
  all_goals sorry

#check @MapLaws

-- Typeclass version (concept extends, v0.1.8): signature and a
-- sorry-backed instance to exercise the inheritance shape.
section
  open LeanPP.Std.MapLawsClass

  -- The class declaration succeeds — the v0.1.8 `concept extends`
  -- clause hooked up the parent `Map α β M` correctly.
  #check @MapLawsClass
  #check @MapLawsClass.find_empty
  #check @MapLawsClass.find_insert_eq
  #check @MapLawsClass.find_insert_neq

  -- Synthesize an instance: the parent `Map` field is provided
  -- via `toMap`, the law fields via `sorry`. Demonstrates that
  -- `concept extends` produces a real Lean class that can be
  -- instantiated with the standard `instance ... where` syntax.
  example {α β M : Type} (mInst : Map α β M) : MapLawsClass α β M where
    toMap           := mInst
    find_empty      := by intros; sorry
    find_insert_eq  := by intros; sorry
    find_insert_neq := by intros; sorry
end

end LeanPP.Tests.StdMapLawsStress
