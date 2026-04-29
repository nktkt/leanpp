/-
  tests/lean/StdOptionStress.lean

  Machine-checked coverage of `LeanPP.Std.Option`. Pins each
  exported lemma's signature and computes a tiny sample so a
  regression in the module is caught immediately.
-/
import LeanPP

open LeanPP.Std.Option

namespace LeanPP.Tests.StdOptionStress

-- 1. isSome_of_eq_some lifts `o = some _` to `o.isSome`.
example : (some 42 : Option Nat).isSome = true :=
  isSome_of_eq_some (rfl : (some 42 : Option Nat) = some 42)

-- 2. eq_none_of_not_isSome on a known `none`.
example : (none : Option Nat) = none := by
  apply eq_none_of_not_isSome
  intro h
  cases h

-- 3. bind_some_eq.
example (f : Nat → Option Nat) (a : Nat) :
    (some a).bind f = f a := bind_some_eq a f

example : (some 7).bind (fun n => some (n + 1)) = some 8 := by
  rw [bind_some_eq]

-- 4. bind_none_eq.
example (f : Nat → Option Nat) :
    (none : Option Nat).bind f = none := bind_none_eq f

-- 5. map_id_eq.
example : (some 3 : Option Nat).map id = some 3 := map_id_eq _

example : (none : Option Nat).map id = none := map_id_eq _

-- 6. Direct existence checks for every exported lemma.
#check @isSome_of_eq_some
#check @eq_none_of_not_isSome
#check @bind_some_eq
#check @bind_none_eq
#check @map_id_eq

end LeanPP.Tests.StdOptionStress
