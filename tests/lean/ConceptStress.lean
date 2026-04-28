/-
  tests/lean/ConceptStress.lean

  Machine-checked coverage of the non-`spec def` Lean++ surface
  commands: `concept`, `model`, `implementation refines`,
  `obligation`, the `@[law]` and `@[unsolved]` tag attributes,
  and the diagnostic commands `#obligations`, `#laws`, `#trust`.

  Each block exercises one surface form. `#check` after each
  declaration confirms the macro lowered to a real Lean 4 entity
  and the generated names are reachable.
-/
import LeanPP

namespace LeanPP.Tests.ConceptStress

-- 1. `concept` with one data field.
concept Magma (α : Type) where
  op : α → α → α
#check @Magma.op

-- 2. `concept` with multiple data + Prop fields.
concept BoundedNat where
  bound : Nat
  bounded_pos : bound ≥ 1
#check @BoundedNat.bound
#check @BoundedNat.bounded_pos

-- 3. `model`: thin alias for `structure`.
model PointSpec where
  x : Nat
  y : Nat
#check @PointSpec.x
#check @PointSpec.y

-- 4. `obligation NAME : PROP` lowers to a sorry-backed theorem
-- tagged `@[obligation]`.
obligation impossibleBound : ∀ n : Nat, n ≤ 0 → n = 0
#check @impossibleBound

-- 5. `@[law]` tagging a free-standing theorem.
@[law] theorem zeroLeId : ∀ n : Nat, 0 ≤ n + 0 := by intros; omega
#check @zeroLeId

-- 6. `@[unsolved]` synonym (avoids the `obligation` keyword
-- collision inside attribute lists).
@[law, unsolved] theorem dualTagged :
    ∀ n : Nat, n ≤ 2 * n := by sorry
#check @dualTagged

-- 7. `#trust IDENT` for a focused per-decl ledger.
section
  @[law] theorem trustTarget (n : Nat) : n + 0 = n := by simp
  #trust trustTarget    -- prints; no further #check needed
end

-- 8. Project-wide diagnostics (smoke checks; no assertion beyond
-- "they don't crash").
#obligations
#laws
#trust

-- 9. `Refines` instance via the trivialRefines stub. Demonstrates
-- the `implementation refines` happy-path inside the stub class.
abbrev FooImpl : Type := Nat
abbrev FooSpec : Type := Nat
implementation FooImpl refines FooSpec by
  exact inferInstance
-- The above generates `FooImpl.refines_FooSpec`.
#check @FooImpl.refines_FooSpec

end LeanPP.Tests.ConceptStress
