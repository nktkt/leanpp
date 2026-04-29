/-
  LeanPP/Std/List.lean
  ----------------------------------------------------------------------------
  Mathlib-free reimplementations of `List.Sorted` and `List.Perm` for use
  in Lean++ examples that need a sortedness / permutation invariant
  without pulling in Mathlib.

  These are deliberately minimal: just enough to express the
  `requires` / `ensures` clauses on a sorting function. A real project
  would either depend on Mathlib (and `import Mathlib.Data.List.Sort`)
  or extend these with additional helper lemmas.

  Both definitions are in `LeanPP.Std.List`. Open the namespace at the
  use site or qualify names with the full path:

  ```
  open LeanPP.Std.List

  spec def insertSorted (x : Nat) (xs : List Nat) : List Nat
    requires Sorted xs
    ...
  ```
-/

namespace LeanPP.Std.List

variable {α : Type}

/-- A `List α` is `Sorted` (under `[LE α]`) if it's empty, a singleton,
    or each adjacent pair satisfies `≤`. Generalized in v0.1.7 from the
    `Nat`-only definition that shipped in v0.1.6 — `Nat` instances now
    flow through the global `[LE Nat]` instance, but `Sorted (xs : List
    Int)` and `Sorted (xs : List String)` etc. work too. -/
inductive Sorted [LE α] : List α → Prop
  | nil  : Sorted []
  | one  : ∀ x, Sorted [x]
  | cons : ∀ {x y ys}, x ≤ y → Sorted (y :: ys) → Sorted (x :: y :: ys)

/-- `Perm xs ys` says `xs` is a permutation of `ys`. The four
    constructors form the standard equivalence relation: refl on nil,
    cons-pointwise, adjacent swap, and transitivity. -/
inductive Perm {α : Type} : List α → List α → Prop
  | nil   : Perm [] []
  | cons  : ∀ x {xs ys}, Perm xs ys → Perm (x :: xs) (x :: ys)
  | swap  : ∀ x y xs, Perm (x :: y :: xs) (y :: x :: xs)
  | trans : ∀ {xs ys zs}, Perm xs ys → Perm ys zs → Perm xs zs

/-- Permutation is reflexive — useful when the implementation returns
    its argument unchanged. -/
theorem Perm.refl : ∀ (xs : List α), Perm xs xs
  | []       => Perm.nil
  | x :: xs' => Perm.cons x (Perm.refl xs')

end LeanPP.Std.List
