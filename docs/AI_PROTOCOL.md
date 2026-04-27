# Lean++ AI Protocol

Lean++ uses AI assistants under one binding rule:

> **AI proposes, the kernel disposes.**

AI never adds anything to the trusted base. It can speed up the search
for proofs and refactors, but every artefact it produces is treated as
an unverified candidate until the Lean 4 kernel checks it.

This document is the contract between AI integrations and the rest of
Lean++. It is short on purpose: the policy is meant to be unambiguous.

For the broader soundness story see [TRUST_MODEL.md](./TRUST_MODEL.md).

---

## Two bedrock principles

1. **Suggestion-only.** AI never writes into the environment directly.
   AI output is *always* a candidate that must be elaborated and
   kernel-checked.
2. **Reconstruction required.** AI output is accepted only as a Lean
   term, tactic script, or named-lemma list that, when elaborated, the
   Lean 4 kernel approves. A failed reconstruction is logged and
   rejected; it is never silently ignored.

These are non-negotiable. Any AI integration that violates either is
non-conformant.

---

## What AI may return

The Lean++ AI bridge accepts AI responses in one of four canonical
forms:

| Form | Example | Reconstruction step |
|------|---------|---------------------|
| Tactic script | `by simp [List.append_assoc]; omega` | Run as a tactic; kernel checks resulting term. |
| Lemma list | `[List.append_assoc, Nat.add_comm, ...]` | Try `simp [...]` / `exact?` with this set. |
| Proof term | `fun h => h.symm.trans rfl` | Elaborate and type-check directly. |
| Refactor patch | A unified diff of `.leanpp` source | Apply in scratch buffer, rebuild, observe result. |

Anything else is rejected at the bridge.

---

## The suggestion pipeline

```
user request (e.g. "prove this lemma" or `bin/leanpp suggest`)
                    │
                    ▼
              AI assistant
                    │   returns one or more candidates
                    ▼
   ┌─── Lean++ AI bridge: validate shape ───┐
   │  reject anything that isn't one of the │
   │  four canonical forms above            │
   └──────────────────┬─────────────────────┘
                      │
                      ▼
   ┌─── Elaborator: try each candidate ─────┐
   │  in a sandbox elaboration context      │
   └──────────────────┬─────────────────────┘
                      │
                      ▼
   ┌─── Kernel: type-check the result ──────┐
   │  the only step that can return         │
   │  "accepted"                            │
   └──────────────────┬─────────────────────┘
                      │
       ┌──────────────┼──────────────┐
       ▼                             ▼
   accepted: report to user      rejected: log to ledger as
   (does *not* edit source       `reconstructed = false`;
   automatically; the user       provide diagnostic to AI for
   confirms before applying)     a follow-up suggestion
```

Concrete behaviours:

- The AI bridge is a *read-mostly* tool. It does not modify project
  source files unless the user explicitly accepts a candidate.
- Every kernel rejection produces a structured failure that can be fed
  back to the AI for a retry. This is the *hallucination feedback
  loop*.
- Successful candidates are presented to the user with the exact term
  that the kernel accepted, so the user knows what is being adopted.

---

## Hallucination guard

LLMs hallucinate. The hallucination guard makes that benign.

- Any candidate whose tactic script fails to make progress is rejected.
- Any candidate whose tactic script closes the goal but produces a term
  the kernel later rejects is rejected. (This is rare given Lean's
  design but possible across mathlib version drift.)
- Any candidate that references nonexistent lemmas is rejected.
- Any rejected candidate is logged with the diagnostic and may be
  shown to the user under `#profile education`.

A failed reconstruction never appears in the trusted environment. It
only appears in the trust ledger as `reconstructed = false` for
auditing, and only in non-`safe` profiles. Under `#profile safe`, a
failed AI suggestion that *the user explicitly committed to source* is
a build error.

See [PROFILES.md](./PROFILES.md) for the per-profile rules.

---

## What AI is **not** allowed to do

- AI may not write to the trust ledger directly.
- AI may not declare `axiom`, `unsafe`, or `@[extern]`.
- AI may not bypass `#profile safe` enforcement.
- AI may not add a `sorry` to a `safe`-profile file.
- AI may not produce a candidate that uses `axiom` declarations the
  user has not already accepted.
- AI output is **never** counted as proof. Even a kernel-accepted AI
  candidate is treated as an ordinary Lean term — its provenance is
  recorded ("source = ai-suggest") but it confers no extra trust.

---

## Editor / CLI surface

The MVP integration ships as `bin/leanpp suggest`:

```sh
$ bin/leanpp suggest Main.abs_neg_lemma
candidate 1: by simp [abs]; omega          [accepted]
candidate 2: by unfold abs; split <;> omega [accepted]
candidate 3: by linarith                    [rejected: no progress]
```

The editor (Phase 2) wraps this with an inline panel. Either way:

- No source file is modified.
- The user picks a candidate; their editor inserts the chosen tactic.
- The chosen tactic is rebuilt as part of the normal Lean elaboration —
  the AI bridge has no further role.

---

## Logging and audit

Every AI invocation is logged in `.leanpp/ai-log.json` (or the
project's configured location):

```json
{
  "goal": "Main.abs_neg_lemma",
  "model": "external-ai-v1",
  "candidates": [
    { "form": "tactic", "script": "by simp [abs]; omega", "accepted": true },
    { "form": "tactic", "script": "by linarith", "accepted": false,
      "reason": "no progress" }
  ],
  "selected": null
}
```

This log is referenced by the trust ledger. It does not constitute
trust; it is metadata for auditing.

---

## Why this design

The naive alternative — letting AI insert text into source — fails three
ways:

1. AI hallucinates lemma names; users commit them; mathlib upgrades
   break the build later.
2. AI invents `axiom`s to "prove" things; trust silently expands.
3. AI bypasses profile rules because text is just text.

The Lean++ design ensures none of those are possible. The kernel is the
only thing that admits theorems. AI lives strictly outside that
boundary.

---

## Related

- [TRUST_MODEL.md](./TRUST_MODEL.md) — reconstruction principle
- [PROFILES.md](./PROFILES.md) — per-profile AI rules
- [MANIFESTO.md](./MANIFESTO.md) — "AI as suggestion" principle
- [TUTORIAL.md](./TUTORIAL.md) — `bin/leanpp suggest` walkthrough
