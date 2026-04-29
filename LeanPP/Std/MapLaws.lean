/-
  LeanPP/Std/MapLaws.lean
  ----------------------------------------------------------------------------
  Companion to `LeanPP.Std.Map`. Bundles the algebraic laws that any
  "real" Map carrier should satisfy.

  Two surfaces are exposed:

    1. `MapLaws α β M : Prop` (v0.1.7) — a plain Prop conjunction
       that any project can `intro` and prove field-by-field. Lives
       in `LeanPP.Std`.

    2. `concept MapLaws extends Map ...` (v0.1.8) — a typeclass
       version using v0.1.8's new `concept extends` clause. Lives
       in `LeanPP.Std.MapLawsClass` to avoid colliding with the
       Prop above. Downstream code that wants a synthesized
       constraint asks for `[MapLawsClass α β M]`; the parent
       `[Map α β M]` is propagated automatically through `extends`.

  Phase 2 has the option to deprecate the Prop and unify on the
  class once the example suite has fully-proved instances.
-/
import LeanPP.Std.Map

namespace LeanPP.Std

/-! ### Prop conjunction (v0.1.7) -/

/-- `MapLaws α β M`: conjunction of the three lookup-after-insert
    identities a Map carrier should satisfy. Stated as a `Prop`
    rather than a `class` because v0.1.7's `concept` macro did not
    yet support `extends`-style typeclass inheritance. v0.1.8 adds
    the class form below; the Prop is kept for backward
    compatibility. -/
def MapLaws (α β M : Type) [Map α β M] : Prop :=
  (∀ (k : α),
      Map.find (α := α) (β := β) (M := M) k
        (Map.empty (α := α) (β := β) (M := M))
      = (none : Option β))
  ∧ (∀ (k : α) (v : β) (m : M),
      Map.find (α := α) (β := β) (M := M) k
        (Map.insert (α := α) (β := β) (M := M) k v m)
      = some v)
  ∧ (∀ (k k' : α) (v : β) (m : M), k ≠ k' →
      Map.find (α := α) (β := β) (M := M) k
        (Map.insert (α := α) (β := β) (M := M) k' v m)
      = Map.find (α := α) (β := β) (M := M) k m)

end LeanPP.Std

/-! ### Typeclass version using `concept extends` (v0.1.8) -/

namespace LeanPP.Std.MapLawsClass

open LeanPP.Std

-- The `concept extends` clause was added to LeanPP.Spec in v0.1.8.
-- This is the first stdlib use of the new feature: a `concept`
-- that derives from another concept (the parent `Map α β M`).
-- Instances of `MapLawsClass` are searchable via `[MapLawsClass
-- α β M]` and Lean automatically provides the parent `[Map α β M]`
-- through the inherited `toMap` field.
concept MapLawsClass (α : Type) (β : Type) (M : Type) extends Map α β M where
  find_empty :
    ∀ (k : α),
      Map.find (α := α) (β := β) (M := M) k
        (Map.empty (α := α) (β := β) (M := M))
      = (none : Option β)
  find_insert_eq :
    ∀ (k : α) (v : β) (m : M),
      Map.find (α := α) (β := β) (M := M) k
        (Map.insert (α := α) (β := β) (M := M) k v m)
      = some v
  find_insert_neq :
    ∀ (k k' : α) (v : β) (m : M), k ≠ k' →
      Map.find (α := α) (β := β) (M := M) k
        (Map.insert (α := α) (β := β) (M := M) k' v m)
      = Map.find (α := α) (β := β) (M := M) k m

end LeanPP.Std.MapLawsClass
