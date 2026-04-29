/-
  LeanPP/Std/Option.lean
  ----------------------------------------------------------------------------
  Mathlib-free `Option` helpers for use in Lean++ specs that return
  optional values. Several examples (`BST.find`, `AssocMap.find`,
  `Queue.pop`, `simpleParser.parseNat`) hit the same handful of
  identities; this module provides them once.

  Currently exports:

    - `isSome_of_eq_some`     — coerce `o = some _` to `o.isSome = true`.
    - `eq_none_of_not_isSome` — turn `¬ o.isSome` into `o = none`.
    - `bind_some_eq`          — `(some a).bind f = f a`.
    - `bind_none_eq`          — `(none : Option α).bind f = none`.
    - `map_id_eq`             — `o.map id = o`.

  All under `LeanPP.Std.Option`. Open the namespace at the use site
  or qualify by full path.
-/

namespace LeanPP.Std.Option

variable {α β γ : Type}

theorem isSome_of_eq_some {o : Option α} {a : α} (h : o = some a) :
    o.isSome = true := by
  cases o
  · cases h
  · rfl

theorem eq_none_of_not_isSome {o : Option α} (h : ¬ o.isSome = true) :
    o = none := by
  cases o
  · rfl
  · exact absurd rfl h

theorem bind_some_eq (a : α) (f : α → Option β) :
    (some a).bind f = f a := rfl

theorem bind_none_eq (f : α → Option β) :
    (none : Option α).bind f = none := rfl

theorem map_id_eq (o : Option α) : o.map id = o := by
  cases o <;> rfl

end LeanPP.Std.Option
