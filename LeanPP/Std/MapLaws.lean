/-
  LeanPP/Std/MapLaws.lean
  ----------------------------------------------------------------------------
  Companion to `LeanPP.Std.Map`. Bundles the algebraic laws that
  any "real" Map carrier should satisfy into a single named Prop.

  A class-style `concept MapLaws ... [Map α β M] where ...` was
  attempted first but stuck on typeclass synthesis: the law bodies
  could not see the `[Map α β M]` constraint declared at the class
  header, and `concept` (in v0.1.7) does not yet support `extends`.
  Defining `MapLaws` as a plain Prop conjunction sidesteps the
  issue while still letting projects state and prove the laws as
  one named obligation.

  Phase 2 plan: extend the `concept` macro with `extends` syntax
  so MapLaws can become a typeclass that downstream code can
  request via `[MapLaws α β M]`. Until then, downstream code that
  needs the laws should require an explicit `MapLaws α β M`
  argument.

  Currently exports:

    - `LeanPP.Std.MapLaws α β M [Map α β M] : Prop`
        — conjunction of `find_empty`, `find_insert_eq`,
          `find_insert_neq`.
-/
import LeanPP.Std.Map

namespace LeanPP.Std

/-- `MapLaws α β M`: conjunction of the three lookup-after-insert
    identities a Map carrier should satisfy. Stated as a `Prop`
    rather than a `class` because `concept` doesn't yet support
    `extends`-style typeclass inheritance (Phase 2). The
    `Map.find` / `Map.empty` / `Map.insert` calls have to thread
    the carrier explicitly via named arguments because `concept`'s
    generated class declares `α β M` as explicit positional
    parameters. -/
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
