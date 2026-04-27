# Lean++ Profiles

A **profile** is a project- or file-level rule set telling Lean++ which
escape hatches are allowed. The same source code can be accepted under
one profile and rejected under another. Profiles do not change Lean's
soundness; they change what counts as an acceptable build.

The four profiles are: `safe`, `research`, `systems`, `education`.

A profile is selected with:

```lean
#profile safe
#profile research
#profile systems
#profile education
```

`#profile` may appear at the top of a file or inside a section. The
default profile, when none is specified, is `research`.

---

## Profile summary

| Concern | safe | research | systems | education |
|---------|------|----------|---------|-----------|
| `sorry` | rejected | tracked | rejected | tracked, with hint |
| User `axiom` | rejected unless reviewed | tracked | tracked | tracked |
| `unsafe` | rejected without contract proof | tracked | required contract | tracked |
| `@[extern]` | rejected without verified contract | tracked | required contract | tracked |
| Unreconstructed SMT/AI cert | rejected | tracked | rejected | tracked |
| Open obligation | rejected | tracked | rejected | tracked |
| Beginner-friendly errors | normal | normal | normal | enabled |
| Goal visualization | normal | normal | normal | enabled |

"Tracked" means: the trust ledger lists it; `lake++ build` succeeds.
"Rejected" means: `lake++ build` exits non-zero with a clear error
pointing at the source.

---

## `safe`

**For**: production code, library releases, regulated / high-assurance
projects, anyone who wants to *guarantee* no escape hatches.

**Allowed**:

- All Lean 4 features that produce kernel-checked proofs.
- All Lean++ surface syntax.
- `axiom` declarations marked `@[reviewed]` (for example, conventional
  axioms like classical reasoning *only if* explicitly reviewed).
- `unsafe` and `@[extern]` declarations *with proven contracts*.

**Forbidden**:

- `sorry` anywhere in the file.
- Unreviewed `axiom`.
- `unsafe` or `@[extern]` without a verified contract.
- External-solver / AI certificates that did not reconstruct.
- Open obligations.

**Enforcement**:

- The Lean++ elaborator checks every declaration's status against the
  ledger.
- `lake++ build` exits non-zero on any violation.
- The trust ledger reports `[BLOCKING]` next to violating items.

**Example**:

```lean
#profile safe

spec def abs (x : Int) : Int
  ensures result ≥ 0
  by implementation
    if x ≥ 0 then x else -x
  by proof
    by auto

-- The following would be a build error:
-- theorem stub : 1 = 1 := by sorry
```

---

## `research`

**For**: exploratory development, mathematical experimentation,
not-yet-finished proofs. The default profile.

**Allowed**: everything (within Lean's existing rules).

**Tracked but allowed**:

- `sorry`
- User `axiom`
- `unsafe` and `@[extern]`
- Unreconstructed certificates
- Open obligations

**Forbidden**: nothing extra (only what plain Lean 4 forbids).

**Enforcement**: ledger reports counts; `lake++ build` succeeds.
`bin/leanpp trust` will surface every escape hatch so you can see what
remains to be cleaned up before promoting a file to `safe`.

**Example**:

```lean
#profile research

theorem todo_lemma : ∀ n : Nat, n + 0 = n := by
  sorry  -- ok in research; appears in trust ledger
```

---

## `systems`

**For**: code that must call the outside world — file I/O, hash
functions, hardware drivers, foreign libraries — but should still treat
those boundaries as proven.

**Allowed**: `unsafe`, `@[extern]`, FFI, but only when accompanied by a
**contract** in `LeanPP.Foreign`.

**Forbidden**:

- `sorry`.
- `unsafe` or `@[extern]` without a contract.
- Open obligations.

**Enforcement**: every `unsafe` / `@[extern]` declaration must come with
a `LeanPP.Foreign.contract` linking it to a Lean-level pre/post-condition.
The build fails if a contract is missing.

**Example**:

```lean
#profile systems

@[extern "leanpp_fast_hash"]
unsafe def fastHash : ByteArray → UInt64 := fun _ => 0

-- contract required:
LeanPP.Foreign.contract fastHash where
  pre  := True
  post := fun _ _ => True   -- replace with the real spec
  proved := by sorry        -- not allowed; supply proof

-- Without the contract or with `sorry` in `proved`, build fails.
```

See [TRUST_MODEL.md](./TRUST_MODEL.md) for the FFI / `unsafe` rules.

---

## `education`

**For**: learners, classrooms, tutorials, beginner-friendly
environments.

**Allowed**: as `research`.

**Extras**:

- Beginner-friendly error explanations (`LeanPP.Edu` rewrites Lean
  errors with hints and pointers).
- Goal visualization in editor / CLI: pretty-printed proof state, named
  hypotheses, suggested next tactics.
- `sorry` with extra UI: the editor highlights a `sorry` as "open
  exercise" rather than "dangerous escape hatch".

**Enforcement**: identical to `research` for soundness purposes; only
the UX differs.

**Example**:

```lean
#profile education

theorem add_zero (n : Nat) : n + 0 = n := by
  sorry  -- shown as "open exercise"; UI suggests `rfl` or `simp`
```

---

## How a profile change affects the trust ledger

Switching profile changes the **status column** of the ledger and
whether the build succeeds. Consider a project with:

- 1 `sorry` in a draft file.
- 1 `@[extern]` without a contract.
- 0 unreviewed axioms.

Under each profile:

| Profile | sorry | extern | Build |
|---------|-------|--------|-------|
| safe | BLOCKING | BLOCKING | fails |
| research | tracked | tracked | succeeds |
| systems | BLOCKING | BLOCKING | fails |
| education | tracked (as exercise) | tracked | succeeds |

The same source file flips between green and red depending on profile.
This is the entire point: profiles let you say *"this code is for
research; that code is for production"* in one line.

---

## Per-file vs project-wide profiles

- `#profile X` at the top of a file applies to the whole file.
- `#profile X` inside a `section ... end` applies to that section only.
- A project-wide default can be set in `lakefile.lean` (Phase 2):

  ```lean
  -- lakefile.lean
  package myproject where
    leanppProfile := .safe
  ```

When both are present, the file-level `#profile` wins.

---

## Walk-through: enforcing `safe`

1. Author writes `Main.leanpp` with `#profile safe` and a `spec def`.
2. `bin/leanpp build` runs the lowering and Lake.
3. The elaborator emits one `obligation` per `ensures`.
4. `auto` (or a `proofplan`) discharges the obligation.
5. The trust ledger records: `obligations: 1 (proved: 1, open: 0)`.
6. No `sorry`, no `unsafe`, no `@[extern]` — build is green.
7. CI runs `lake++ ci` and publishes the trust report.

If at step 4 `auto` fails:

1. The obligation is left open.
2. `safe` rejects open obligations.
3. The build fails with a pointer to the spec.
4. The author either supplies a proof, switches to `#profile research`
   to keep iterating, or relaxes the spec.

---

## Picking a profile

| Situation | Recommended profile |
|-----------|---------------------|
| Library you intend to publish | `safe` |
| Math research project | `research` |
| Code that talks to file system / hardware | `systems` |
| Teaching material | `education` |
| Day-to-day prototyping | `research` |
| CI build for a release | `safe` |

A common pattern is: develop under `research`, gate releases under
`safe`. The Lean++ project itself does this.

---

## Related

- [TRUST_MODEL.md](./TRUST_MODEL.md) — the ledger that profiles read
- [SYNTAX_RFC.md](./SYNTAX_RFC.md) — `#profile` directive
- [TUTORIAL.md](./TUTORIAL.md) — `#profile safe` in action
- [MANIFESTO.md](./MANIFESTO.md) — why profiles exist
