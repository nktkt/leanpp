# Lean++ Architecture

Lean++ is a stack of layers added on top of Lean 4. Each layer is
reducible to the layer below it, and the kernel is at the bottom. This
document describes the layers, what each one owns, and how a `.leanpp`
file flows through them.

The design rule is simple:

> **The Lean 4 kernel is at the bottom of every chain. Nothing above it
> may extend the trusted base.**

---

## The 6-layer diagram

```
┌────────────────────────────────────────────────────────────┐
│ UX layer                                                   │
│   VS Code  •  notebook  •  dashboard  •  AI assistants     │
├────────────────────────────────────────────────────────────┤
│ Project layer                                              │
│   lake++  •  proof cache  •  CI  •  trust ledger           │
├────────────────────────────────────────────────────────────┤
│ Automation layer                                           │
│   proof plans  •  tactic orchestration  •  SMT cert        │
├────────────────────────────────────────────────────────────┤
│ Spec layer                                                 │
│   requires  •  ensures  •  invariant  •  refinement        │
├────────────────────────────────────────────────────────────┤
│ Language layer                                             │
│   macros  •  elaborators  •  DSLs  •  annotations          │
├────────────────────────────────────────────────────────────┤
│ Lean 4                                                     │
│   kernel  •  elaborator  •  compiler  •  Lake  •  Std      │
├────────────────────────────────────────────────────────────┤
│ mathlib  •  domain libraries                               │
└────────────────────────────────────────────────────────────┘
```

The arrows point downward at runtime: every Lean++ feature ultimately
reduces to a Lean 4 declaration that the kernel checks.

---

## Layer by layer

### Lean 4 (and mathlib / domain libraries)

The bottom layer is unmodified Lean 4: kernel, elaborator, compiler,
Lake, and `Std`. Above it sit mathlib and any domain libraries. Lean++
imports them as a normal client.

This layer is the **only** trusted layer. See
[COMPATIBILITY.md](./COMPATIBILITY.md) and
[TRUST_MODEL.md](./TRUST_MODEL.md) for the contract.

### Language layer

The thinnest Lean++ layer. It provides:

- Macros and elaborator extensions for `.leanpp` surface syntax.
- The `.leanpp` -> `.lean` transpiler.
- DSL hooks (`@[law]`, `@[obligation]`, `#profile`, ...).
- Source maps so editor errors point back to original lines.

This layer **never** modifies the kernel or `Expr`. Its outputs are
ordinary Lean 4 terms.

### Spec layer

`requires`, `ensures`, `decreases`, `invariant`, `modifies`, `model`,
`refines`. The spec layer:

- Takes the structured spec attached to a `spec def`.
- Generates `obligation` declarations for each post-condition,
  termination measure, and refinement claim.
- Connects implementations to abstract models via `refines`.

The spec layer is *static metadata*: it does not run anything. Its
output is more declarations for the language layer to lower.

See [SYNTAX_RFC.md](./SYNTAX_RFC.md) for the constructs.

### Automation layer

Where proofs actually get done:

- `proofplan` (named tactic combinators, project-wide).
- `auto` portfolio tactic.
- SMT-certificate ingestion and reconstruction (Phase 3).
- Tactic orchestration: which plans / tactics try which obligations.

The automation layer's only job is to *propose* tactic scripts. The
elaborator and kernel decide whether they work. A failed tactic produces
an open obligation, never a false theorem.

### Project layer

Cross-file, cross-build concerns:

- `lake++` — Lake wrapper / plugin. Subcommands include `build`,
  `proof-cache`, `trust`, `ci`, `explain-broken-proof`,
  `minimize-imports`, `theorem-index`.
- Proof cache (per-project, plan-keyed; Phase 2).
- Trust ledger (axioms, sorry, unsafe, extern, certificates, obligations).
- CI integration: trust report as a build artefact.
- Theorem index (`#find theorem`; Phase 2).

The project layer is what makes Lean++ feel like an *engineering*
environment rather than a per-file tool.

### UX layer

Everything that interacts with humans:

- VS Code extension (built on Lean's existing LSP) with Lean++-aware
  hovers, source maps, obligation panels.
- Notebook integration (Phase 5).
- Trust dashboard (Phase 3).
- AI assistant bridge (`bin/leanpp suggest`; see
  [AI_PROTOCOL.md](./AI_PROTOCOL.md)).

The UX layer is *advisory* — it never accepts proofs on its own. It can
only ask the layers below to elaborate and check.

---

## How a `.leanpp` file flows through the layers

```
┌──── Author writes Main.leanpp (UX layer) ──────────────────┐
│   `spec def`, `proofplan`, `#profile safe`                 │
└──────────────────────┬─────────────────────────────────────┘
                       │
                       ▼
┌──── Language layer parses .leanpp ─────────────────────────┐
│   surface syntax recognised; profile recorded              │
└──────────────────────┬─────────────────────────────────────┘
                       │
                       ▼
┌──── Spec layer expands specs into obligations ─────────────┐
│   one `obligation` per `ensures`/invariant/decreases       │
└──────────────────────┬─────────────────────────────────────┘
                       │
                       ▼
┌──── Automation layer attempts proofs ──────────────────────┐
│   `auto` and named `proofplan`s try each obligation        │
└──────────────────────┬─────────────────────────────────────┘
                       │
                       ▼
┌──── Language layer lowers to plain .lean ──────────────────┐
│   `def`, `theorem`, attributes; written under .leanpp/build│
└──────────────────────┬─────────────────────────────────────┘
                       │
                       ▼
┌──── Lean 4 elaborator + kernel checks every term ──────────┐
│   the only step that can accept a theorem                  │
└──────────────────────┬─────────────────────────────────────┘
                       │
                       ▼
┌──── Project layer audits and reports ──────────────────────┐
│   trust ledger, proof cache, CI report                     │
└────────────────────────────────────────────────────────────┘
```

If any step fails:

- A parse error is a Lean++ error (with source map back to `.leanpp`).
- An obligation that no tactic closes appears as `open` in the ledger.
- A profile violation (e.g. `sorry` under `safe`) is a build error.
- A kernel rejection is a kernel error, surfaced verbatim.

---

## Where each LeanPP module sits

The Lean++ standard library is split by layer.

| Module | Layer | Phase |
|--------|-------|-------|
| `LeanPP.Spec` | Spec | MVP |
| `LeanPP.Refine` | Spec | Phase 2/3 |
| `LeanPP.Auto` | Automation | MVP (basic), Phase 2/3 (portfolio) |
| `LeanPP.Trust` | Project | MVP |
| `LeanPP.Foreign` | Project / Automation | Phase 3 |
| `LeanPP.Project` | Project | MVP / Phase 2 |
| `LeanPP.Edu` | UX / Language | Phase 2 |
| `LeanPP.AI` | UX / Automation | Phase 2 |

Module responsibilities:

- **`LeanPP.Spec`** — `requires`, `ensures`, `invariant`, `modifies`
  syntax + obligation generation.
- **`LeanPP.Refine`** — `model`, `implementation ... refines ...`,
  refinement obligations.
- **`LeanPP.Auto`** — `auto` portfolio, `proofplan` infrastructure,
  proof search hooks, SMT cert reconstruction (Phase 3).
- **`LeanPP.Trust`** — trust ledger, `sorry`/`axiom`/`unsafe` tracking,
  `#trust`.
- **`LeanPP.Foreign`** — verified FFI boundary, `@[extern]` contract
  framework, runtime assumption catalogue.
- **`LeanPP.Project`** — dependency graph, proof-cache metadata, CI
  reports, theorem index.
- **`LeanPP.Edu`** — beginner error explanations, guided proof mode.
- **`LeanPP.AI`** — suggestion protocol, proof reconstruction wrapper,
  hallucination guard.

---

## Why kernel-at-the-bottom preserves soundness

A typical extension to a proof system can become unsound in three ways:

1. By patching the kernel to accept new terms.
2. By accepting external results without rechecking them.
3. By introducing new axioms that aren't tracked.

Lean++ defends against all three by construction:

1. The kernel is **never patched** — only Lean 4 itself ships kernel
   code.
2. External results (SMT certificates, AI suggestions) are
   **reconstructed** into Lean terms; the kernel decides.
3. New axioms are visible in the **trust ledger**, and `safe` profile
   forbids unverified ones.

Every layer above the kernel is therefore "soundness-irrelevant" — a bug
there can break elaboration or fail a build, but cannot certify a false
theorem. This is the entire reason the architecture is shaped this way.

See [TRUST_MODEL.md](./TRUST_MODEL.md) for the formal version.

---

## Tooling boundary

The CLI tools `bin/leanpp` and `bin/lake++` belong to the project / UX
layers. They orchestrate the pipeline above but never bypass it. In
particular:

- `bin/leanpp transpile` is a pure language-layer operation.
- `bin/leanpp build` invokes Lean 4 via Lake; the kernel is the final
  judge.
- `bin/leanpp trust` and `bin/leanpp obligations` are read-only views of
  the ledger and environment.
- `bin/leanpp suggest` (Phase 2) calls AI but routes any candidate
  through the elaborator + kernel before reporting "accepted".

---

## Related

- [MANIFESTO.md](./MANIFESTO.md) — kernel-safe principle
- [COMPATIBILITY.md](./COMPATIBILITY.md) — additive-only extension
- [TRUST_MODEL.md](./TRUST_MODEL.md) — soundness story
- [SYNTAX_RFC.md](./SYNTAX_RFC.md) — surface syntax this layer handles
- [TUTORIAL.md](./TUTORIAL.md) — flow in practice
