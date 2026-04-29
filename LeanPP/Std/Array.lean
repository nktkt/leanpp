/-
  LeanPP/Std/Array.lean
  ----------------------------------------------------------------------------
  Mathlib-free `Array` predicates. Counterpart to `LeanPP.Std.List` for
  random-access containers.

  Currently exports:
    - `LeanPP.Std.Array.SortedAsc xs` — every pair of indices `i < j`
      with `j` in range satisfies `xs[i]! ≤ xs[j]!`.

  `examples/binarySearch.leanpp` uses this. Future additions belong
  here — uniqueness, bounded-by-key, contains-membership, etc.
-/

namespace LeanPP.Std.Array

variable {α : Type}

/-- An `Array α` is non-strictly ascending under `[LE α]` if every
    pair of in-range indices `i < j` has `xs[i]! ≤ xs[j]!`. -/
def SortedAsc [LE α] [Inhabited α] (xs : Array α) : Prop :=
  ∀ i j, i < j → j < xs.size → xs[i]! ≤ xs[j]!

end LeanPP.Std.Array
