/-
  tests/lean/StdBoolStress.lean

  Machine-checked coverage of `LeanPP.Std.Bool`. Pins the four
  Bool-equivalence lemmas so a regression in the module surfaces
  as a CI failure rather than at user-side proof attempts.
-/
import LeanPP

open LeanPP.Std.Bool

namespace LeanPP.Tests.StdBoolStress

-- and_eq_true_iff: forward + backward.
example (a b : Bool) (h : (a && b) = true) :
    a = true ∧ b = true := and_eq_true_iff.mp h

example (a b : Bool) (ha : a = true) (hb : b = true) :
    (a && b) = true := and_eq_true_iff.mpr ⟨ha, hb⟩

-- or_eq_true_iff: forward + backward.
example (a b : Bool) (h : (a || b) = true) :
    a = true ∨ b = true := or_eq_true_iff.mp h

example (b : Bool) (hb : b = true) :
    (false || b) = true := or_eq_true_iff.mpr (Or.inr hb)

-- not_eq_true_iff: forward + backward.
example (a : Bool) (h : (!a) = true) : a = false := not_eq_true_iff.mp h
example                              : (!false : Bool) = true := not_eq_true_iff.mpr rfl

-- decide_iff_prop: bridge between `decide P = true` and `P`.
-- `decide` collides with the tactic-namespace reservation in
-- term position; use `Decidable.decide` to disambiguate.
example (n : Nat) (h : (Decidable.decide (n = n)) = true) : n = n :=
  decide_iff_prop.mp h

example (n : Nat) (h : n = n) : (Decidable.decide (n = n)) = true :=
  decide_iff_prop.mpr h

-- Direct existence checks.
#check @and_eq_true_iff
#check @or_eq_true_iff
#check @not_eq_true_iff
#check @decide_iff_prop

end LeanPP.Tests.StdBoolStress
