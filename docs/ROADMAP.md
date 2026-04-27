# Lean++ Roadmap

This document lays out the phased plan from Phase 0 (RFC) through Phase 5
(ecosystem). Each phase has a goal, a deliverables list, exit criteria,
and explicit risks. The 90-day implementation plan that delivers the MVP
is at the end.

---

## Phase summary

| Phase | Window | Theme | Outcome |
|-------|--------|-------|---------|
| 0 | 0–2 mo | RFC | Manifesto, compatibility rule, trust model, syntax RFC, MVP scope frozen. |
| 1 | 3–6 mo | MVP | `.leanpp` files, `spec`/`requires`/`ensures`, `obligation`, basic `proofplan`, `lake++` wrapper, trust ledger v0, VS Code source map. |
| 2 | 6–12 mo | Alpha | Semantic theorem search, proof cache, proof-repair suggestions, broader tactic portfolio, mathlib integration, CI report, doc generator. Real-project usable. |
| 3 | 12–18 mo | Beta | SMT-cert reconstruction, domain automation packs, verified FFI contracts, profile system completion, project-wide trust dashboard, proof and import minimization. |
| 4 | 18–24 mo | 1.0 "Kernel-Safe" | Stable Lean++ syntax, trust ledger standard, `lake++` in CI, refinement features practical, 100+ examples, education docs. |
| 5 | 2–5 yr | Ecosystem | mathlib++ overlay, verified-systems library, AI proof-assistant protocol, enterprise CI/CD, formal-spec template library, education curriculum, research notebook. |

---

## Phase 0 — RFC (months 0–2)

**Goal.** Lock down "what is Lean++" before anyone writes elaborator code.

**Deliverables.**

- [MANIFESTO.md](./MANIFESTO.md)
- [COMPATIBILITY.md](./COMPATIBILITY.md)
- [TRUST_MODEL.md](./TRUST_MODEL.md)
- [SYNTAX_RFC.md](./SYNTAX_RFC.md)
- [PROFILES.md](./PROFILES.md)
- [AI_PROTOCOL.md](./AI_PROTOCOL.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- This document.
- An MVP scope statement (the six items at the bottom of this file).

**Exit criteria.** All RFC docs reviewed; MVP scope frozen; at least one
end-to-end mock walkthrough (TUTORIAL.md) is achievable.

**Risks.** Over-design before any code. Mitigation: keep the RFC tight —
each doc is 150–500 lines and synthesises rather than catalogs.

---

## Phase 1 — MVP (months 3–6)

**Goal.** Working Lean++ for one user, end-to-end, on small examples.

**Deliverables.**

- `.leanpp` parser / transpiler (lowering to `.lean`).
- `spec def` with `requires` / `ensures` / `by implementation` / `by proof`.
- `obligation NAME : PROP` declarations.
- `#obligations` command.
- Basic `proofplan` (named tactic combinator).
- `auto` portfolio: `simp` / `omega` / `decide` / `tauto`.
- `bin/leanpp` CLI: `new`, `transpile`, `build`, `obligations`, `trust`.
- `bin/lake++` Lake wrapper.
- Trust ledger v0 (axioms / sorry / unsafe / extern enumeration).
- `#profile safe` and `#profile research` enforcement.
- VS Code source map for `.leanpp` -> `.lean` line mapping.
- Demo set: list insertion, binary search, stack, queue, balanced-tree subset.

**Exit criteria.**

- `lake++ build` works green on all demos.
- `safe` profile rejects `sorry` and ships a non-zero exit code.
- TUTORIAL.md runs reproducibly.

**Risks.**

- Elaborator complexity creeps up. **Mitigation**: lock MVP to the six
  forms (`spec def`, `requires`, `ensures`, `obligation`, `proofplan`,
  `auto`).
- Lake plugin friction. **Mitigation**: `lake++` is a wrapper, not a fork.

---

## Phase 2 — Alpha (months 6–12)

**Goal.** "Real teams can use this on a real codebase."

**Deliverables.**

- Semantic theorem index (`#find theorem`).
- Proof cache (per-project, plan-keyed).
- Refactor-aware proof repair: when a lemma's statement or name changes,
  surface candidate fixes for sites that broke.
- Tactic portfolio expansion: `polyrith`, `linarith`, `norm_num`, mathlib
  integrations.
- `lake++ ci` produces both Markdown and JSON trust reports.
- `lake++ doc` generates spec-aware documentation.
- Mathlib integration tested at scale.
- `LeanPP.Edu` first cut: improved error explanations, goal visualization.
- AI bridge MVP (`bin/leanpp suggest`) under [AI_PROTOCOL.md](./AI_PROTOCOL.md).

**Exit criteria.**

- One real third-party project uses Lean++ in CI.
- ≥60% obligation auto-solve rate on the demo set.
- ≥30% repair-suggestion success rate on injected refactors.

**Risks.**

- Mathlib evolution outpaces our integration. **Mitigation**: pin a
  mathlib hash per Lean++ release; document upgrade path.
- Proof repair regresses. **Mitigation**: keep repair behind an explicit
  command; never auto-rewrite source.

---

## Phase 3 — Beta (months 12–18)

**Goal.** Cover hard cases: SMT, FFI, big projects.

**Deliverables.**

- SMT certificate reconstruction (`LeanPP.Auto.Smt`), kernel-checked.
- Domain automation packs: arithmetic, lists, finite sets, bit-vectors.
- Verified FFI contracts (`LeanPP.Foreign`).
- Full profile system: `safe`, `research`, `systems`, `education`.
- Project-wide trust dashboard.
- Proof minimization (`lake++ minimize-proof`).
- Import minimization (`lake++ minimize-imports`).
- Initial application targets: math, algorithm verification, crypto
  protocols, compiler subsets, distributed-systems specs, hardware specs.

**Exit criteria.**

- ≥80% kernel-reconstruction rate for SMT certificates on a benchmark.
- `systems` profile usable on a real FFI-using project (e.g. a hash
  library).
- Trust dashboard runs in CI for at least three external projects.

**Risks.**

- SMT reconstruction is brittle. **Mitigation**: fall through to "log as
  unreconstructed" and keep building; never silently trust.
- FFI contracts are time sinks. **Mitigation**: ship a starter set of
  contracts for stdlib `IO`.

---

## Phase 4 — 1.0 "Kernel-Safe" (months 18–24)

**Goal.** Stable, documented, production-grade.

**Deliverables.**

- Lean++ syntax frozen (1.0 stability promise).
- Trust ledger format standardised (versioned schema).
- `lake++` in CI everywhere.
- Refinement features (`model` / `refines`) practical for state-machine
  and data-structure verification.
- 100+ curated example projects.
- Education docs: tutorials, exercises, problem sets.

**Exit criteria.**

- 1.0 release tag with stability guarantees.
- Lean 4 source compatibility audit passes 100%.
- Independent benchmarks reproduce success metrics.

**Risks.**

- Breaking-change pressure from feedback. **Mitigation**: branch a 0.x
  line for experimentation; keep 1.0 narrow.

---

## Phase 5 — Ecosystem (years 2–5)

**Goal.** Lean++ as a platform.

**Deliverables.**

- `mathlib++` overlay (non-invasive; no fork of mathlib).
- Verified-systems library: data structures, parsers, networking specs.
- AI proof-assistant protocol (open spec for AI tools to participate
  safely).
- Enterprise CI/CD integrations.
- Formal-spec template library.
- Education curriculum (course material).
- Research notebook integration.

**Exit criteria.** Multiple independent organizations shipping Lean++ in
production.

---

## 90-day implementation plan (Phase 0 → Phase 1)

Concrete sequencing for the first three months.

| Weeks | Track | Output |
|-------|-------|--------|
| 1–2 | RFC | Freeze MANIFESTO, COMPATIBILITY, TRUST_MODEL. |
| 3–4 | RFC + spike | Freeze SYNTAX_RFC, PROFILES; spike `.leanpp` parser. |
| 5–6 | MVP core | `.leanpp` -> `.lean` transpiler; `spec def` lowering. |
| 7 | MVP core | `obligation` + `#obligations` + ledger v0. |
| 8 | MVP core | `proofplan` macro + `auto` portfolio. |
| 9 | MVP CLI | `bin/leanpp new / transpile / build / obligations / trust`. |
| 10 | MVP CLI | `bin/lake++` wrapper. |
| 11 | Profiles | `#profile safe` and `#profile research` enforcement. |
| 12 | Demo + tutorial | List insertion, binary search, stack, queue, balanced-tree subset; rerun TUTORIAL.md end-to-end. |

---

## Success metrics

| Metric | Target |
|--------|--------|
| Lean 4 source compatibility | 100% |
| MVP examples | 50+ |
| `safe`-profile `sorry` count | 0 |
| Proof obligation auto-solve rate | ≥60% |
| Proof repair success rate (initial) | ≥30% |
| Trust report on CI | required for participating projects |
| External-solver kernel-reconstruction rate | ≥80% target |
| Time for a beginner to write a spec'd function | <30 min |

These metrics are tracked continuously starting Phase 2; before that
they're aspirational.

---

## Risks and mitigations (project-wide)

| Risk | Mitigation |
|------|------------|
| Too much new syntax | MVP locked to `spec`/`obligation`/`proofplan` only. |
| Soundness drift | Kernel never modified; external output always reconstructed. |
| AI hallucination | AI proposes only; nothing adopted until kernel-checked. |
| mathlib breakage | `proofplan` + semantic deps + repair. |
| Unsafe boundary unclear | Trust ledger + profile system. |
| Lake conflict | `lake++` ships as a Lake wrapper / plugin, not a fork. |
| Too research-y to be used | Start from verified data structures; engage real users early. |

---

## Team composition

A practical team to deliver Phases 1–3:

- **Minimal team (5–7 people)**:
  - 1 Lean elaborator engineer (parser / lowering / macros).
  - 1 tactic / automation engineer (`auto`, `proofplan`, portfolio).
  - 1 toolchain engineer (`lake++`, CLI, source maps).
  - 1 trust / verification engineer (ledger, profiles, FFI contracts).
  - 1 docs / DX engineer.
  - 1 product lead.
  - +1 AI / research engineer (Phase 2+).

- **Full team (12–15 people)**: add a second elaborator engineer, a
  mathlib-integration engineer, an editor / IDE engineer, an SMT-cert
  engineer, an education / curriculum lead, a community / ecosystem
  manager.

---

## Non-goals (reminder)

- Replace the Lean 4 kernel.
- Lean 3 compatibility.
- Trust AI output as proof.
- Fork mathlib.
- Claim full automation.

See [MANIFESTO.md](./MANIFESTO.md).

---

## MVP minimum scope

To ship Phase 1, exactly six items must work:

1. `.leanpp` file format and lowering.
2. `spec` / `ensures`.
3. Generated theorem obligations.
4. `proofplan`.
5. Trust ledger.
6. `lake++ build`.

Everything else can wait.

---

## Related

- [MANIFESTO.md](./MANIFESTO.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [TRUST_MODEL.md](./TRUST_MODEL.md)
- [SYNTAX_RFC.md](./SYNTAX_RFC.md)
