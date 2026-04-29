/-
  tests/lean/StdNatStress.lean

  Machine-checked coverage of `LeanPP.Std.Nat`. Pins the
  computational behaviour of `log2` / `divCeil` and the lemma
  signatures so a regression in the module is caught immediately
  by `tests/run.sh` instead of surfacing only when an example
  happens to use the helper.
-/
import LeanPP

open LeanPP.Std.Nat

namespace LeanPP.Tests.StdNatStress

-- log2 sample table. `native_decide` is required because well-founded
-- recursion is opaque to `decide`'s kernel reducer.
example : log2 1     = 0 := by native_decide
example : log2 2     = 1 := by native_decide
example : log2 3     = 1 := by native_decide
example : log2 4     = 2 := by native_decide
example : log2 8     = 3 := by native_decide
example : log2 16    = 4 := by native_decide
example : log2 100   = 6 := by native_decide
example : log2 1000  = 9 := by native_decide

-- divCeil sample table. `decide` works here because divCeil is
-- a non-recursive `if` over plain Nat division.
example : divCeil 0  3 = 0 := by decide
example : divCeil 1  3 = 1 := by decide
example : divCeil 3  3 = 1 := by decide
example : divCeil 4  3 = 2 := by decide
example : divCeil 7  3 = 3 := by decide
example : divCeil 10 1 = 10 := by decide

-- divCeil_zero applies for any divisor including 0 (returns 0).
example (d : Nat) : divCeil 0 d = 0 := divCeil_zero d

-- divCeil_one is the identity on the dividend.
example (n : Nat) : divCeil n 1 = n := divCeil_one n

end LeanPP.Tests.StdNatStress
