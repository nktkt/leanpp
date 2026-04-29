/-
  LeanPP/Std/String.lean
  ----------------------------------------------------------------------------
  Mathlib-free `String` / `Char` helpers needed by parser specs.
  `examples/simpleParser.leanpp` inlines `digitOf?` because Lean
  core's parsing surface is sparse; promoting it here lets users
  start from a verified primitive instead.

  Currently exports:

    - `LeanPP.Std.String.isDigit c`            — Bool, true if c is '0'..'9'.
    - `LeanPP.Std.String.digitOf? c`           — Char → Option Nat decoder.
    - `LeanPP.Std.String.digitOf?_isDigit`     — `digitOf? c = some _ → isDigit c = true`.
    - `LeanPP.Std.String.digitOf?_none_iff`    — `digitOf? c = none ↔ isDigit c = false`.

  All under `LeanPP.Std.String`. Open the namespace at the use
  site or qualify by full path. A future revision will add a
  `digitOf?_le_nine` bound theorem once `Char.le_iff_val_le`-style
  reasoning is wrapped into the `auto` portfolio.
-/

namespace LeanPP.Std.String

/-- True iff `c` is a decimal digit `'0'..'9'`. -/
def isDigit (c : Char) : Bool :=
  decide ('0' ≤ c ∧ c ≤ '9')

/-- Decode a single decimal digit. `none` on non-digits. -/
def digitOf? (c : Char) : Option Nat :=
  if isDigit c then some (c.toNat - '0'.toNat) else none

/-- If `digitOf? c` succeeds, then `c` was a digit. The forward
    direction of the obvious correspondence; the reverse is
    `digitOf?_of_isDigit`. -/
theorem digitOf?_isDigit {c : Char} {d : Nat} (h : digitOf? c = some d) :
    isDigit c = true := by
  unfold digitOf? at h
  by_cases hd : isDigit c = true
  · exact hd
  · simp [hd] at h

/-- `digitOf?` returns `none` exactly when `isDigit` says no. -/
theorem digitOf?_none_iff {c : Char} :
    digitOf? c = none ↔ isDigit c = false := by
  constructor
  · intro h
    unfold digitOf? at h
    by_cases hd : isDigit c = true
    · simp [hd] at h
    · simp at hd; exact hd
  · intro h
    unfold digitOf?
    simp [h]

end LeanPP.Std.String
