/-
  LeanPP/Std/Bool.lean
  ----------------------------------------------------------------------------
  Mathlib-free `Bool` helpers. Several `LeanPP.Std.*` modules end up
  decoding `decide P = true` back into `P`, splitting `(a && b) = true`
  into its conjuncts, etc.; this module collects the small handful of
  identities that recur.

  Currently exports:

    - `LeanPP.Std.Bool.and_eq_true_iff`  — `(a && b) = true ↔ a ∧ b`
    - `LeanPP.Std.Bool.or_eq_true_iff`   — `(a || b) = true ↔ a ∨ b`
    - `LeanPP.Std.Bool.not_eq_true_iff`  — `(!a) = true ↔ a = false`
    - `LeanPP.Std.Bool.decide_iff_prop`  — `decide P = true ↔ P`

  All under `LeanPP.Std.Bool`. Open the namespace at the use site or
  qualify by full path.

  These are deliberately thin re-statements of facts available from
  `Bool.and_eq_true` / `decide_eq_true_iff` etc. in Lean core; they
  appear here as `LeanPP.Std.Bool.*` synonyms so a single
  `open LeanPP.Std.Bool` covers the cases that come up while
  unfolding `decide` in `LeanPP.Std.String`-style modules.
-/

namespace LeanPP.Std.Bool

theorem and_eq_true_iff {a b : Bool} :
    (a && b) = true ↔ a = true ∧ b = true := by
  cases a <;> cases b <;> simp

theorem or_eq_true_iff {a b : Bool} :
    (a || b) = true ↔ a = true ∨ b = true := by
  cases a <;> cases b <;> simp

theorem not_eq_true_iff {a : Bool} :
    (!a) = true ↔ a = false := by
  cases a <;> simp

theorem decide_iff_prop {p : Prop} [Decidable p] :
    decide p = true ↔ p := decide_eq_true_iff

end LeanPP.Std.Bool
