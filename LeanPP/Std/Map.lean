/-
  LeanPP/Std/Map.lean
  ----------------------------------------------------------------------------
  The shared `Map` concept. Several examples implement this same
  abstract spec on different carriers (`BST`, `AssocMap`); promoting
  it to the stdlib lets every implementation reference the *same*
  type-class so a single `def f {M} [Map α β M] (m : M) ...` body can
  run against any of them.

  The concept records only the operations. Algebraic laws
  (`find_empty`, `find_insert_eq`, `find_insert_neq`) are tagged via
  `@[law]` on the *instance* side, since their proof obligations
  depend on the carrier.
-/
import LeanPP.Spec

namespace LeanPP.Std

-- `Map α β M`: a key-value store keyed by `α`, valued in `β`,
-- represented by carrier type `M`. The three operations are
-- `empty`, `find`, and `insert`. Specialized examples
-- (`BST`, `AssocMap`, ...) provide instances.
--
-- (A `/--` docstring isn't accepted before `concept` — the Lean
-- parser only attaches docstrings to recognized builtins, and
-- `concept` is a `command_elab`-defined custom command.)
concept Map (α : Type) (β : Type) (M : Type) where
  empty   : M
  find    : α → M → Option β
  insert  : α → β → M → M

end LeanPP.Std
