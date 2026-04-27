# Lean++ Trust Model

Lean++ adds substantial machinery — specs, automation, AI, external
solvers — on top of Lean 4. None of it is allowed to expand the trusted
base. This document defines exactly what is trusted, what isn't, and how
the boundary is enforced and audited.

---

## The Reconstruction Principle

Lean++ obeys one rule when integrating any external prover, decision
procedure, or AI:

> No external claim is ever accepted as a theorem. Only the Lean 4 kernel
> can accept theorems.

The pipeline for any external evidence is:

```
external solver / AI / oracle
            │
            ▼
   certificate / proof hint
            │
            ▼
   Lean++ reconstruction
            │
            ▼
       Lean proof term
            │
            ▼
       kernel check
            │
            ▼
   accepted theorem (or rejection)
```

If any step fails, the conclusion is **not** added to the environment. It
is added to the trust ledger as `unreconstructed` so the user knows.

---

## Trusted base

The trusted base of a Lean++ project is exactly the trusted base of Lean 4:

1. The Lean 4 kernel.
2. Lean 4's built-in axioms (`Classical.choice`, `propext`, `Quot.sound`).
3. Any `axiom` declarations the user has written (which the trust ledger
   reports).
4. Any `@[extern]` / `unsafe` boundaries (which the trust ledger reports).
5. The compiler / build pipeline (Lean 4's, unmodified).

Lean++ tooling — the elaborator extensions, transpiler, automation
portfolio, AI bridge, `lake++` — is **not** in the trusted base. If any of
it is buggy, the worst case is "Lean++ failed to produce a proof", not
"Lean++ accepted a false theorem".

---

## Trust ledger

Every Lean++ project has a project-wide **trust ledger**, produced by
`lake++ trust` (or `bin/leanpp trust`). It enumerates everything that
expands or might expand the trusted base.

### Output format

The ledger is a structured report (TOML / JSON) with sections:

```toml
[profile]
active = "safe"

[axioms]
# user-declared axioms
- name = "MyTheory.Postulate"
  module = "MyTheory.Foundations"
  reviewed = true

[sorry]
# every `sorry` in the source
- module = "Algorithms.SortDraft"
  line = 42
  status = "blocking"   # rejected by safe profile

[unsafe]
# uses of `unsafe`
- name = "Foreign.fastHash"
  module = "Foreign.Hash"
  contract = "Foreign.HashContract"
  contract_proved = false

[extern]
# @[extern] declarations
- name = "IO.FS.readBinFile"
  contract = "stdlib"
  contract_proved = true

[obligations]
- name = "abs_nonneg"
  status = "proved"
- name = "binary_search_correct"
  status = "open"

[certificates]
# external solver certificates
- source = "z3"
  goal = "Arith.bound_lemma_3"
  reconstructed = true
- source = "ai-suggest"
  goal = "Algorithms.merge_termination"
  reconstructed = false   # ledger only; never trusted
```

### What invalidates trust (per profile)

| Item | safe | research | systems | education |
|------|------|----------|---------|-----------|
| `sorry` | rejected | tracked | rejected | tracked |
| Unverified `axiom` | rejected | tracked | tracked | tracked |
| Unreconstructed certificate | rejected | tracked | tracked | tracked |
| `unsafe` without contract | rejected | tracked | rejected | tracked |
| `@[extern]` without verified contract | rejected | tracked | rejected | tracked |
| AI suggestion that failed reconstruction | rejected | tracked | rejected | tracked |

In the `safe` profile, "rejected" means `lake++ build` exits non-zero.

See [PROFILES.md](./PROFILES.md) for full profile semantics.

---

## `#trust` and `#trust TARGET`

Lean++ exposes a command-level view of the ledger:

```lean
#trust                       -- ledger for the whole current module
#trust MySort.sortCorrect    -- recursive trust for one declaration
```

For a target declaration, `#trust` walks the environment closure of the
declaration and reports any `axiom`, `sorry`, `unsafe`, `extern`, or
`unreconstructed` certificate it depends on. This is the MVP
implementation: a transitive environment walk, no separate database
required.

Phase 2+ adds an indexed cache so the walk is incremental.

---

## Certificate reconstruction

Lean++ accepts external evidence only via reconstruction:

| Source | Certificate form | Reconstruction |
|--------|------------------|----------------|
| SMT (e.g. Z3, cvc5) | Proof certificate (LFSC / DRAT / lean tactic script) | `LeanPP.Auto.Smt.reconstruct` re-checks the cert and emits a Lean term. |
| Decision procedures (`omega`, `polyrith`, ...) | A built-in tactic in mathlib / Lean 4 | Already kernel-checked; safe by construction. |
| AI assistant | Tactic script, lemma list, or term | Lean elaborates and the kernel checks. |
| Hand-written `axiom` | (none) | Not reconstructed. Listed in ledger; rejected by `safe`. |

Reconstruction is **mandatory** for any non-tactic external evidence to
count as proof. Phase 3 targets ≥80% kernel-reconstruction rate for
SMT-style certificates; failures are surfaced, not silently dropped.

---

## AI policy

AI is a *suggestion oracle*, never a trust source. Specifically:

1. AI returns one of: a tactic script, a list of candidate lemma names, a
   skeleton proof term, or a refactor suggestion.
2. The Lean++ AI bridge feeds that candidate into the Lean elaborator. The
   kernel either accepts the resulting term or doesn't.
3. If the kernel rejects the candidate, the AI suggestion is discarded
   and *not* recorded in the environment. The trust ledger logs the
   attempt with `reconstructed = false` (research/education profiles) or
   the build is rejected (safe profile).
4. There is **no** path by which an AI suggestion enters the trusted base
   without kernel checking.

See [AI_PROTOCOL.md](./AI_PROTOCOL.md).

---

## Verified FFI / `unsafe` boundaries

Some real systems must call out: file I/O, hash functions, hardware. The
Lean++ rule is:

- `@[extern]` and `unsafe` declarations are allowed.
- They must be paired with a **contract**: a Lean-level pre/post-condition
  characterising what the external function is *assumed* to provide.
- The trust ledger records the contract and whether it has been proved
  consistent (e.g., wrapper proofs).
- Profile `systems` enforces that every `@[extern]` / `unsafe` carries a
  contract.
- Profile `safe` further forbids `unsafe` without a contract proof.

See `LeanPP.Foreign` (Phase 1+) and [PROFILES.md](./PROFILES.md).

---

## Trust on CI

`lake++ ci` produces a trust report as a build artefact. The Phase 2 goal
is that **every Lean++ project on CI publishes a trust report**. The
report is human-readable Markdown plus a machine-readable JSON.

Phase 3 introduces a project-wide trust dashboard tracking:

- Number of `sorry` over time.
- Reconstructed-certificate ratio.
- Open obligations.
- Unverified axioms / extern boundaries.

---

## Threat model

We explicitly defend against:

- **Buggy Lean++ tactics**: cannot create false theorems; worst case is
  failed elaboration.
- **Buggy AI**: cannot create false theorems; rejected by reconstruction.
- **Buggy SMT solver**: cannot create false theorems; rejected by
  reconstruction.
- **Forgotten `sorry`**: cannot ship in safe profile; reported in others.
- **Hidden `axiom`**: surfaced by `#trust`.

We do not defend against:

- A compromised Lean 4 kernel (out of scope; that is Lean's threat model).
- A compromised host OS / compiler toolchain (out of scope).
- Malicious patches to `lake++` itself (mitigation: distribute as a Lake
  plugin with reproducible builds; out of scope for the trust model).

---

## Related

- [MANIFESTO.md](./MANIFESTO.md) — kernel-safe principle
- [PROFILES.md](./PROFILES.md) — per-profile enforcement
- [AI_PROTOCOL.md](./AI_PROTOCOL.md) — AI suggestion / reconstruction
- [SYNTAX_RFC.md](./SYNTAX_RFC.md) — `#trust`, `obligation`, etc.
