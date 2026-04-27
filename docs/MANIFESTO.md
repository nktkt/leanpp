# Lean++ Manifesto

> **Lean++** is an upper-compatible environment over **Lean 4** that adds
> specification, proof automation, proof maintainability, verified software
> engineering, and AI assistance — while preserving kernel soundness.
>
> (Lean++ = Lean 4 + 仕様記述 + 証明自動化 + 証明保守性 + verified software
> engineering + AI支援を、kernel健全性を保ったまま統合した上位互換環境。)

Lean++ is to Lean 4 what C++ was to C: not a new core, but an engineering
layer on top of an existing one. The Lean kernel remains the single arbiter
of truth. Everything Lean++ adds — specs, obligations, plans, automation,
AI suggestions — must ultimately be reduced to a Lean term that the kernel
can check.

This document states what Lean++ is, what it adds, and what it deliberately
refuses to be.

---

## Four Principles

### 1. Kernel-Safe

The Lean kernel is never modified, patched, or bypassed. Every theorem ever
accepted by Lean++ is a theorem accepted by the unmodified Lean 4 kernel.
External tools (SMT solvers, AI models, decision procedures) may *propose*
proofs, but their output is always reconstructed into a kernel-checkable
proof term before being trusted.

See: [TRUST_MODEL.md](./TRUST_MODEL.md).

### 2. Source-Compatible

Lean++ is a strict superset of Lean 4 in the source-code sense. Every
existing `.lean` file is a valid Lean++ input. Adopting Lean++ never
requires rewriting Lean code, breaking imports, or forking mathlib. Lean++
extends; it does not replace.

See: [COMPATIBILITY.md](./COMPATIBILITY.md).

### 3. Engineering-First

Lean++ is the **C++ of proof engineering**. Its goal is not to magically
discharge proofs but to make **large, long-lived verified projects**
sustainable: writing specifications, generating obligations, repairing
proofs after refactors, surveying trust at the project level, and bounding
the unverified surface.

We do not promise full automation. We promise *less proof bit-rot*.

### 4. AI as Suggestion

Lean++ integrates AI assistants under one rule: AI proposes, the kernel
disposes. Anything an AI returns — tactic scripts, lemma lists, term
sketches — is treated as a *candidate* that must be elaborated and checked
by Lean. AI output is never accepted as proof on its own. There is no path
by which an unverified AI suggestion ends up in the trusted base.

See: [AI_PROTOCOL.md](./AI_PROTOCOL.md).

---

## What Lean++ Adds to Lean 4

Lean++ adds six engineering capabilities over plain Lean 4. None of them
expand the trusted base.

| # | Capability | What it means |
|---|-----------|---------------|
| 1 | Spec writing | `spec def` with `requires` / `ensures` / `decreases` / `invariant` clauses written next to the function. |
| 2 | Obligation generation | The compiler emits a checkable list of proof obligations (`obligation NAME : PROP`) from each spec. |
| 3 | Proof automation | `proofplan` named tactic combinators and an `auto` portfolio (`simp` / `omega` / `decide` / `tauto` and more). |
| 4 | Proof preservation | Project-level proof cache, refactoring-aware repair suggestions, semantic theorem index. |
| 5 | Trust visibility | Trust ledger of `sorry` / `axiom` / `unsafe` / `extern` / unreconstructed certificates, surfaced via `#trust` and `lake++ trust`. |
| 6 | Safe AI | Suggestion-only AI protocol with mandatory kernel reconstruction and a hallucination guard. |

These map directly onto four engineering goals:

1. **Write specs naturally** — closer to the function, not buried in
   theorem files.
2. **Auto-generate proof obligations** — humans don't track them by hand.
3. **Keep proofs from breaking** — repair, replay, and replace.
4. **Make dependencies, trust boundaries, and unsolved parts visible** —
   no silent `sorry` reaches production.

See: [ARCHITECTURE.md](./ARCHITECTURE.md), [SYNTAX_RFC.md](./SYNTAX_RFC.md).

---

## What Lean++ Is NOT

Lean++ deliberately refuses several attractive temptations.

- **Not a new kernel.** We will never replace, fork, or patch the Lean 4
  kernel.
- **Not Lean 3 compatible.** We don't carry Lean 3 syntax; Lean 4 is the
  baseline.
- **Not an AI oracle.** AI output is not proof. Period.
- **Not a mathlib fork.** Lean++ uses mathlib unchanged. Any "mathlib++"
  in Phase 5 is a *non-invasive overlay*, not a fork.
- **Not a full-automation tool.** We do not promise that you can stop
  thinking. We promise that the proofs you do write will survive longer.

See: [TRUST_MODEL.md](./TRUST_MODEL.md), [PROFILES.md](./PROFILES.md).

---

## Profiles

Different users need different rules. Lean++ ships four profiles:

- `safe` — full verification mode, no `sorry`, no unverified externals.
- `research` — `sorry` allowed but tracked.
- `systems` — FFI / `unsafe` allowed at the cost of contracts and
  boundary proofs.
- `education` — beginner-friendly errors and goal visualization.

A single `#profile safe` directive at the top of a file changes what is
accepted and what the trust ledger reports.

See: [PROFILES.md](./PROFILES.md).

---

## Where to go next

- **What the spec/syntax actually looks like:** [SYNTAX_RFC.md](./SYNTAX_RFC.md)
- **How soundness is preserved:** [TRUST_MODEL.md](./TRUST_MODEL.md)
- **What you can and can't change:** [COMPATIBILITY.md](./COMPATIBILITY.md)
- **The 6-layer architecture:** [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Hands-on first project:** [TUTORIAL.md](./TUTORIAL.md)
- **Profile rules:** [PROFILES.md](./PROFILES.md)
- **AI usage policy:** [AI_PROTOCOL.md](./AI_PROTOCOL.md)
- **Multi-year plan:** [ROADMAP.md](./ROADMAP.md)

---

## Related

- [TRUST_MODEL.md](./TRUST_MODEL.md) — kernel soundness, certificates, trust ledger
- [COMPATIBILITY.md](./COMPATIBILITY.md) — Lean 4 source-compatibility rules
- [ROADMAP.md](./ROADMAP.md) — phases 0–5 and success metrics
