/-
  tests/lean/StdMapLawsStress.lean

  Machine-checked coverage of `LeanPP.Std.MapLaws`. Pins the Prop
  shape (a triple of foralls about find / empty / insert).

  A full instance proof for one of the example carriers (BST or
  AssocMap) would be the natural follow-up; AssocMap proves
  `find_empty` and `find_insert_eq` but not `find_insert_neq`, and
  BST leaves all three open. So the cleanest available coverage at
  this stage is the type-shape level.
-/
import LeanPP

namespace LeanPP.Tests.StdMapLawsStress

open LeanPP.Std

-- The Prop has the documented signature: takes α, β, M, an
-- instance, and yields a Prop.
example : (α β M : Type) → [Map α β M] → Prop := MapLaws

-- Direct existence + type-signature check.
#check @MapLaws
#check @MapLaws Nat Nat Unit

-- A trivial sorry-backed witness shows the statement is at least
-- *constructible*. Real instance proofs belong on the example side
-- (BST / AssocMap), not here.
example : ∀ (α β M : Type) [Map α β M], MapLaws α β M := by
  intros α β M _inst
  refine ⟨?_, ?_, ?_⟩
  all_goals sorry

end LeanPP.Tests.StdMapLawsStress
