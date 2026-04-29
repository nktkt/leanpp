/-
  LeanPP/Std/Nat.lean
  ----------------------------------------------------------------------------
  Mathlib-free `Nat` helpers needed by the example suite or by users
  who want bit-counting / ceiling-division without pulling in Mathlib.

  Currently exports:

    - `LeanPP.Std.Nat.log2`         — integer log base 2,
                                       well-founded recursion on
                                       `n / 2`.
    - `LeanPP.Std.Nat.divCeil`      — ceiling division
                                       (`(n + d - 1) / d`, `d = 0` ↦ 0).
    - `LeanPP.Std.Nat.divCeil_zero` — `divCeil 0 d = 0` for any `d`.
    - `LeanPP.Std.Nat.divCeil_one`  — `divCeil n 1 = n`.

  All definitions live under `LeanPP.Std.Nat` so users can either
  qualify (`LeanPP.Std.Nat.log2 n`) or `open LeanPP.Std.Nat` and use
  bare names.
-/

namespace LeanPP.Std.Nat

/-- Integer log base 2: number of times you can halve `n` before
    hitting 0 or 1. Equivalent to `Nat.log 2 n` for `n ≥ 1`.
    Implementation note: well-founded recursion on `n` because `n / 2`
    is not a structural subterm. -/
def log2 (n : Nat) : Nat :=
  if h : n ≤ 1 then 0
  else 1 + log2 (n / 2)
termination_by n

/-- Ceiling division: `divCeil n d = ⌈n / d⌉`. For `d = 0` we follow
    Lean's convention and return `0` (matching `Nat.div`'s behavior on
    a zero divisor). -/
def divCeil (n d : Nat) : Nat :=
  if d = 0 then 0
  else (n + d - 1) / d

/-- For any `d`, ceiling division of `0` is `0`. The `d = 0` case
    follows from the early-return; the `d ≥ 1` case reduces (via
    `simp`'s built-in `Nat.div_eq_zero` handling) to `d - 1 < d`,
    which `omega` discharges. -/
theorem divCeil_zero (d : Nat) : divCeil 0 d = 0 := by
  unfold divCeil
  by_cases h : d = 0
  · simp [h]
  · simp [h]; omega

/-- For `d = 1`, ceiling division is the identity. -/
theorem divCeil_one (n : Nat) : divCeil n 1 = n := by
  unfold divCeil
  simp

end LeanPP.Std.Nat
