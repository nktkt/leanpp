# Lean++ Surface Syntax RFC

This RFC specifies the Lean++ surface syntax — the new constructs that
appear in `.leanpp` files (and lower to ordinary Lean 4 declarations).

Each construct is described in five parts:

1. **Surface syntax** — what users write.
2. **Semantics** — what it means.
3. **Lowering** — how it is reduced to Lean 4.
4. **Example**.
5. **Status** — `MVP`, `Phase 2`, or `Phase 3`.

For the MVP scope, only `spec def`, `obligation`, `proofplan`, `auto`,
`#trust`, `#profile`, and `#obligations` are required to ship. The rest
are designed here so that the MVP doesn't paint itself into a corner.

---

## 1. `spec def`

### Surface

```lean
spec def abs (x : Int) : Int
  requires True
  ensures  result ≥ 0
  ensures  result = x ∨ result = -x
  by implementation
    if x ≥ 0 then x else -x
  by proof
    by auto
```

Optional clauses: `requires`, `ensures`, `decreases`, `invariant`, `modifies`.

The `result` keyword is bound inside `ensures` to the function's return
value.

### Semantics

`spec def` declares a function together with its specification. The
elaborator generates:

- The ordinary function definition.
- One `obligation` per `ensures` (and per loop / recursion `invariant`).
- A termination obligation if `decreases` is present.

If `by proof` is given, those obligations are discharged immediately;
otherwise they appear in `#obligations` to be solved later.

### Lowering

```
spec def f (...) : T
  requires P
  ensures  Q
  by implementation E
  by proof TAC
```
becomes

```lean
def f (...) : T := E
@[obligation] theorem f.spec_ensures : ∀ ..., P → Q[result := f ...] := by TAC
```

(Plus a `requires` precondition lemma when applicable.)

### Status

`MVP`.

---

## 2. `obligation`, `#obligations`, and `#laws`

### Surface

```lean
obligation abs_nonneg : ∀ x : Int, abs x ≥ 0

#obligations         -- enumerate every @[obligation] in the current module
#obligations MyModule  -- Phase 2: scope to one namespace
#laws                -- enumerate every @[law]-tagged theorem in the module
```

### Semantics

`obligation NAME : PROP` declares a named proof obligation that is
expected to hold. Until proved, it is recorded in the trust ledger as
`open`. It is *not* an `axiom` — the kernel does not assume it. Code that
*depends* on an open obligation is a build error in `safe` profile.

`#obligations` lists every `@[obligation]`-tagged decl in the current
module with `[solved]` / `[unsolved]` status (a decl is unsolved if its
body uses `sorryAx`). Imports are filtered out so the report focuses on
user code.

`#laws` mirrors the shape of `#obligations` for `@[law]`-tagged
theorems, marking each `[proved]` or `[open]`. Useful when surveying
which algebraic properties an instance is on the hook for.

`@[obligation]` and its synonym `@[unsolved]` are interchangeable.
The synonym exists because `obligation` is also a top-level command
keyword (`obligation NAME : PROP`), and Lean's attribute parser
refuses to parse it inside `@[...]` lists without the `«obligation»`
guillemet escape. `unsolved` is a non-keyword alias that fits
naturally — e.g. `@[law, unsolved] theorem foo : ... := by sorry`.

### Lowering

`obligation NAME : PROP` lowers to a registered metadata entry plus a
declaration template:

```lean
-- Stored in trust ledger.
-- Body remains unproved until the user supplies one or `proofplan`/`auto`
-- closes it. In safe profile, "unproved" blocks the build.
```

Concretely, MVP lowers to a `theorem NAME : PROP := by sorry` *plus* a
ledger entry; `safe` profile then rejects the resulting `sorry`. This
keeps the MVP simple while enforcing the same end-to-end guarantee.

### Status

`MVP`.

---

## 3. `proofplan`

### Surface

```lean
proofplan arithFirst : tactic := by
  first
    | omega
    | simp_arith
    | decide
    | tauto

proofplan structuralRec : tactic := by
  intros
  induction · using ·.recOn <;> arithFirst
```

Used as:

```lean
theorem foo : 2 + 2 = 4 := by arithFirst
```

### Semantics

A `proofplan` is a **named, ordered tactic combinator**. It is a Lean
tactic at heart; the value is in the *naming* and *project-level reuse*.
A `proofplan` may call other plans, fall through with `first`, do
backtracking with `try`, etc.

Project conventions: name plans by domain (`arithFirst`, `listLemmas`,
`groupLaws`). Surfacing them by name lets the trust ledger and proof
cache key off the plan, enabling repair on refactor.

### Lowering

A `proofplan NAME : tactic := tac` lowers to a Lean macro:

```lean
macro "NAME" : tactic => `(tactic| tac)
```

Plus a registered project-level catalogue entry for tooling.

### Status

`MVP` for the basic form; `Phase 2` adds plan-aware proof repair.

---

## 4. `auto` tactic

### Surface

```lean
example : 0 ≤ x ^ 2 := by auto
```

### Semantics

`auto` is a portfolio tactic that runs (in MVP):

1. `simp` (with the default set)
2. `omega`
3. `decide`
4. `tauto`

…and accepts the first that closes the goal. Phase 2 grows the portfolio
(`polyrith`, `linarith`, mathlib `norm_num`, user-registered plans).

`auto` is intentionally limited and predictable; it is not a search
oracle.

### Lowering

A built-in tactic provided by `LeanPP.Auto`. Internally just a Lean tactic
macro that runs `first | simp | omega | decide | tauto`.

### Status

`MVP`.

---

## 5. `concept` and `law`

### Surface (MVP + v0.1.8 `extends`)

The MVP `concept` body uses Lean's standard `structFields` grammar; every
field — data or proposition — is written as `name : type`. There is no
inline `law` keyword inside the body (it would conflict with the
column-sensitive parser used by Lean structure fields). To tag a
free-standing theorem as a structural law, use the `@[law]` attribute.

v0.1.8 adds an optional `extends` clause matching Lean's standard
`class extends` shape, enabling typeclass inheritance:

```lean
concept Monoid (α : Type) extends Magma α where
  e : α
  e_left : ∀ a, op e a = a
```

```lean
concept Monoid (α : Type) where
  op : α → α → α
  e  : α
  assoc      : ∀ a b c, op (op a b) c = op a (op b c)
  idLeft     : ∀ a, op e a = a
  idRight    : ∀ a, op a e = a

@[law] theorem List.append_assoc {α : Type} : ∀ xs ys zs : List α,
    (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := List.append_assoc
```

### Surface (Phase 2 target)

Phase 2 will add an inline `law` keyword that requires a custom
indent-aware parser:

```lean
concept Monoid (α : Type) where
  op : α → α → α
  e  : α
  law assoc      : ∀ a b c, op (op a b) c = op a (op b c)
  law idLeft     : ∀ a, op e a = a
  law idRight    : ∀ a, op a e = a
```

### Semantics

A `concept` is a `class`-like bundle. In the MVP, propositional fields
are no different structurally from data fields — instances supply both.
Phase 2's `law` keyword adds a tag that surfaces in the trust ledger
and lets automation pull only the law portion of an instance.

### Lowering (MVP)

```lean
class Monoid (α : Type) where
  op : α → α → α
  e  : α
  assoc   : ∀ a b c, op (op a b) c = op a (op b c)
  idLeft  : ∀ a, op e a = a
  idRight : ∀ a, op a e = a
```

(In the Phase 2 target, plus `attribute [law] Monoid.assoc Monoid.idLeft
Monoid.idRight` and a per-concept `lawSet` registry.)

### Status

`MVP` (bare-field form). Inline-`law` form: `Phase 2`.

---

## 6. `model` / `implementation ... refines ...`

### Surface

```lean
model SortedList (α : Type) [LinearOrder α] where
  contents : List α
  ensures  invariant : Sorted contents

implementation MergeSort refines SortedList where
  contents := mergeSort input
  proof    := by exact mergeSort_sorted input
```

### Semantics

Refinement: an implementation provides concrete data plus proof that it
satisfies the abstract `model`'s invariants. Lean++ generates the
refinement obligation and registers the `refines` relationship for
project-level inspection.

### Lowering

To a `structure` (the `model`) plus a `def` of the implementation plus
`theorem`s discharging the model's invariants for the implementation.

### Status

`Phase 3` for full form. `Phase 2` ships a stripped-down `refines` for
data structures.

---

## 7. `#trust`

### Surface

```lean
#trust                  -- whole current module
#trust MyAlg.sortSpec   -- transitive trust for one declaration
```

### Semantics

Walks the environment closure of the target and lists every `axiom`,
`sorry`, `unsafe`, `@[extern]`, and unreconstructed certificate it
depends on. See [TRUST_MODEL.md](./TRUST_MODEL.md).

### Lowering

A user command, implemented as an environment walk over the elaborator's
`Environment`.

### Status

`MVP` (transitive walk; Phase 2 adds caching).

---

## 8. `#profile`

### Surface

```lean
#profile safe
#profile research
#profile systems
#profile education
```

### Semantics

A file-level (or section-level) directive selecting the **profile** that
governs what is allowed in subsequent declarations. See
[PROFILES.md](./PROFILES.md).

### Lowering

Sets a scoped option (e.g. `LeanPP.profile = .safe`); various Lean++
elaborator hooks read it.

### Status

`MVP` for `safe` / `research`. `Phase 2` adds `systems` and `education`.

---

## 9. `#find theorem`

### Surface

```lean
#find theorem (h : a + b = b + a)
#find theorem about List Sorted
```

### Semantics

Semantic theorem search: returns lemma names whose statements match the
query (term shape, mentioned constants, type-class context). MVP version
is a simple name/keyword grep; Phase 2 adds a real semantic index over
mathlib + project.

### Lowering

A user command backed by `LeanPP.Project.theoremIndex`.

### Status

`Phase 2`.

---

## 10. Modifiers and small forms

| Form | Use | Status |
|------|-----|--------|
| `requires P` | Precondition clause inside `spec def`. | MVP |
| `ensures Q` | Postcondition clause; `result` bound. | MVP |
| `decreases e` | Termination measure; threaded as `termination_by e` into the generated `def`. | MVP |
| `invariant I` | Loop/recursion invariant. | Phase 2 |
| `modifies xs` | Frame condition for stateful code. | Phase 3 |
| `by implementation E` | Body of a `spec def`. | MVP |
| `by proof TAC` | Discharge for the spec's obligations. | MVP |

---

## Design notes

### Why `spec def` instead of attribute on `def`?

Putting the spec next to the function is the whole point. Attributes
(`@[ensures Q]`) work, but they hide the spec from casual reading. We
chose a keyword form because the readability win is large.

### Why `proofplan` as a first-class object?

Project-level proof maintainability requires that automation be **named
and stable**. A nameless `by first | omega | simp` is invisible to the
proof-cache and the repair tools.

### Lowering invariant

Every Lean++ surface form has a deterministic, documented lowering to
plain Lean 4. This is what makes [COMPATIBILITY.md](./COMPATIBILITY.md)
honest: a Lean++ project can always be transpiled to a pure Lean 4
project on disk.

---

## Related

- [COMPATIBILITY.md](./COMPATIBILITY.md) — additive-only rule
- [TRUST_MODEL.md](./TRUST_MODEL.md) — `obligation` / `#trust` semantics
- [TUTORIAL.md](./TUTORIAL.md) — using these constructs hands-on
- [PROFILES.md](./PROFILES.md) — what `#profile` enforces
