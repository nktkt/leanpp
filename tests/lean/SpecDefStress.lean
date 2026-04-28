/-
  tests/lean/SpecDefStress.lean

  Machine-checked coverage of the `spec def` macro across the
  surface forms exercised by `examples/*.leanpp`. Each block
  asserts both the `def` and the generated `@[obligation] theorem
  NAME.ensures_k` exist (via `#check`) so a regression in the
  spec macro's lowering causes elaboration to fail.

  Patterns covered:
    1. spec def with no clauses
    2. spec def with one `requires`
    3. spec def with one `ensures`
    4. spec def with `requires` + `ensures`
    5. spec def with multiple `ensures`
    6. spec def with `decreases` (well-founded recursion)
    7. spec def with `decreases` + `ensures`
    8. spec def with implicit-typeclass binder

  If you add a new surface clause to `LeanPP.Spec`, add a block
  here and a `#check` assertion for the generated name.
-/
import LeanPP

namespace LeanPP.Tests.SpecDefStress

-- 1. No clauses: just a def.
spec def f01 (n : Nat) : Nat := n + 1
#check @f01

-- 2. One `requires` clause; no ensures (no theorem expected).
spec def f02 (n : Nat) : Nat
  requires n ≥ 0
  := n
#check @f02

-- 3. One `ensures`; the macro emits `f03.ensures_1`.
spec def f03 (n : Nat) : Nat
  ensures fun result => 0 ≤ result
  := n
#check @f03
#check @f03.ensures_1

-- 4. `requires` + `ensures`. The theorem takes the precondition
-- as `_h`.
spec def f04 (n : Nat) : Nat
  requires n ≥ 1
  ensures  fun result => result ≥ 0
  := n - 1
#check @f04
#check @f04.ensures_1

-- 5. Multiple `ensures` produce `f05.ensures_1` and `f05.ensures_2`.
spec def f05 (x : Int) : Nat
  ensures fun result => 0 ≤ result
  ensures fun result => result = x.natAbs
  := x.natAbs
#check @f05
#check @f05.ensures_1
#check @f05.ensures_2

-- 6. `decreases` enables well-founded recursion. Without v0.1.2's
-- threading this would silently no-op and Lean would reject the
-- recursion.
spec def f06 (n : Nat) : Nat
  decreases n
  := if h : n ≤ 1 then 0 else 1 + f06 (n / 2)
#check @f06

-- 7. `decreases` + `ensures` together. The macro must still emit
-- the theorem alongside the well-founded def.
spec def f07 (n : Nat) : Nat
  decreases n
  ensures  fun result => 0 ≤ result
  := if h : n ≤ 1 then 0 else 1 + f07 (n / 2)
#check @f07
#check @f07.ensures_1

-- 8. Bracketed binder with a typeclass dependency. Exercises the
-- macro's binder-walking helper on a non-trivial shape.
spec def f08 [BEq α] (xs : List α) (k : α) : Bool
  ensures fun result => result = result   -- trivial; just exercise the path
  := xs.contains k
#check @f08
#check @f08.ensures_1

end LeanPP.Tests.SpecDefStress
