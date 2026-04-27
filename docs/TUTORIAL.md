# Lean++ Tutorial: Your First Verified Function

This tutorial walks through the Lean++ MVP from a fresh project to a
verified function, an `obligation`, a `proofplan`, a trust report, and the
`safe` profile. The goal is to give you a feel for the full workflow in
under thirty minutes.

You will need:

- A working Lean 4 toolchain (matching `lean-toolchain`).
- The `bin/leanpp` and `bin/lake++` scripts shipped with this repository.

If you only want to read about the syntax, see
[SYNTAX_RFC.md](./SYNTAX_RFC.md). If you want the philosophical story,
see [MANIFESTO.md](./MANIFESTO.md).

---

## 1. Create a new project

```sh
$ bin/leanpp new myproject
created myproject/
  ├── Main.leanpp
  ├── lakefile.lean
  ├── lean-toolchain
  └── .leanpp/
$ cd myproject
```

`bin/leanpp new` produces a Lake project with a single `Main.leanpp` and
a `.leanpp/` directory used by tooling for caches and the trust ledger.
The project's `lakefile.lean` is plain Lake — `lake++` is a wrapper.

---

## 2. Write a spec'd function

Open `Main.leanpp` and replace the contents with:

```lean
import LeanPP

#profile research

spec def abs (x : Int) : Int
  requires True
  ensures  result ≥ 0
  ensures  result = x ∨ result = -x
  by implementation
    if x ≥ 0 then x else -x
  by proof
    by auto
```

Two things are happening:

- `spec def abs` declares the function alongside its specification.
- `by auto` asks the Lean++ automation portfolio to discharge the
  generated proof obligations.

`#profile research` allows you to iterate quickly without `safe` blocking
the build on the first iteration.

---

## 3. Transpile to plain Lean

Lean++ files lower to ordinary `.lean` files. You can inspect the
lowering:

```sh
$ bin/leanpp transpile Main.leanpp
wrote .leanpp/build/Main.lean
```

Open `.leanpp/build/Main.lean` and you'll see something like:

```lean
import LeanPP

def abs (x : Int) : Int :=
  if x ≥ 0 then x else -x

@[obligation] theorem abs.spec_ensures_1
    : ∀ x : Int, abs x ≥ 0 := by auto

@[obligation] theorem abs.spec_ensures_2
    : ∀ x : Int, abs x = x ∨ abs x = -x := by auto
```

The lowered file is what the Lean 4 kernel checks. This is the source of
truth for [COMPATIBILITY.md](./COMPATIBILITY.md): a Lean++ project is
always reducible to a plain Lean project on disk.

---

## 4. Build the project

```sh
$ bin/leanpp build
[1/1] compiling Main.leanpp -> Main.lean
[1/1] lake build
ok: Main
```

Equivalently, `bin/lake++ build` will do the same thing — `lake++` is a
strict superset of `lake`. Any `lake` command works under `lake++`.

A clean build means:

1. The `.leanpp` lowering succeeded.
2. The Lean 4 kernel accepted every term.
3. Every obligation either had a proof or was discharged by `auto`.

---

## 5. Inspect open obligations

To see what specs the project has accepted and which ones are still open:

```sh
$ bin/leanpp obligations
abs.spec_ensures_1   proved   (auto)
abs.spec_ensures_2   proved   (auto)

0 open obligations.
```

Or, inside an editor, the `#obligations` command surfaces the same list
in a Lean InfoView:

```lean
#obligations
-- abs.spec_ensures_1 : ∀ x : Int, abs x ≥ 0           [proved]
-- abs.spec_ensures_2 : ∀ x : Int, abs x = x ∨ abs x = -x  [proved]
```

If you write a spec without a `by proof`, the obligation appears as
`open` and `auto`/`proofplan` won't run on it implicitly.

---

## 6. Inspect the trust ledger

```sh
$ bin/leanpp trust
profile         : research
axioms          : 0 user-declared
sorry           : 0
unsafe          : 0
@[extern]       : 0
obligations     : 2 (proved: 2, open: 0)
certificates    : 0

Trust report OK.
```

The trust ledger is the project-wide audit of every escape from the
verified core. See [TRUST_MODEL.md](./TRUST_MODEL.md) for the full
schema.

---

## 7. Add a proofplan

For a slightly more interesting example, let's add a small lemma and use
a named `proofplan` to discharge it.

Append to `Main.leanpp`:

```lean
proofplan arithFirst : tactic := by
  first
    | omega
    | simp_arith
    | decide
    | tauto

theorem abs_self (x : Int) (h : 0 ≤ x) : abs x = x := by
  unfold abs
  arithFirst
```

Rebuild:

```sh
$ bin/leanpp build
ok: Main
```

`arithFirst` is now a named, reusable plan. In larger projects you would
collect these into a single `Project.Plans` module; the proof cache and
later proof-repair tools key off plan names, so a refactor that touches
the underlying lemmas can be retargeted at the plan rather than at every
proof site.

---

## 8. Switch to `safe` profile

Change the profile directive at the top of `Main.leanpp`:

```lean
#profile safe
```

Now rebuild:

```sh
$ bin/leanpp build
ok: Main
```

Still green — no `sorry`, no unverified externals.

To see the profile bite, deliberately introduce a `sorry`:

```lean
theorem abs_neg_lemma (x : Int) : abs (-x) = abs x := by
  sorry
```

Rebuild:

```sh
$ bin/leanpp build
error: Main.leanpp:25:2: profile=safe forbids `sorry` (Main.abs_neg_lemma)
hint: switch to `#profile research` to keep iterating, or supply a proof.
```

The trust ledger flags the same problem:

```sh
$ bin/leanpp trust
profile : safe
sorry   : 1 [BLOCKING]
  - Main.abs_neg_lemma  Main.leanpp:25
```

This is the contract of `safe`: production code with no escape hatches.
See [PROFILES.md](./PROFILES.md) for the rest of the rules.

Remove the `sorry` (or supply an actual proof) before continuing.

---

## 9. Suggest with AI (preview)

If your environment has the optional AI bridge configured, you can ask
for a tactic suggestion:

```sh
$ bin/leanpp suggest Main.abs_neg_lemma
candidate 1: by simp [abs]; omega
candidate 2: by unfold abs; split <;> omega
```

The bridge **does not** install these into your file. It runs each
candidate through the Lean elaborator and reports which ones the kernel
accepts. You then choose one to commit. See
[AI_PROTOCOL.md](./AI_PROTOCOL.md) for the suggestion-only contract.

---

## 10. Where to go next

You've now seen:

- `spec def` with `requires` / `ensures` / `by proof`
- `proofplan` and `auto`
- `#profile safe`
- `bin/leanpp build`, `obligations`, `trust`
- The `.leanpp` -> `.lean` lowering

Next steps:

- **Real examples**: walk the `examples/` directory (list insertion,
  binary search, stack, queue, balanced tree subset).
- **Layered design**: read [ARCHITECTURE.md](./ARCHITECTURE.md) to see
  where each module sits.
- **Trust deep dive**: [TRUST_MODEL.md](./TRUST_MODEL.md).
- **Profile rules**: [PROFILES.md](./PROFILES.md).
- **Long-term plan**: [ROADMAP.md](./ROADMAP.md).

---

## Related

- [SYNTAX_RFC.md](./SYNTAX_RFC.md) — every construct used above
- [TRUST_MODEL.md](./TRUST_MODEL.md) — what `bin/leanpp trust` reports
- [PROFILES.md](./PROFILES.md) — `safe` vs `research` enforcement
- [AI_PROTOCOL.md](./AI_PROTOCOL.md) — `bin/leanpp suggest` contract
