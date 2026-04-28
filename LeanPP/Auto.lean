/-
  LeanPP/Auto.lean
  ----------------------------------------------------------------------------
  The `auto` tactic and `proofplan` macro.

  `auto` is a portfolio tactic: it runs a sequence of cheap closers and
  succeeds on the first one that closes the goal. Since Mathlib / aesop are
  not available, we use only Lean 4 core tactics:
    rfl, assumption, decide, omega, simp_all, contradiction.
-/
import Lean

namespace LeanPP

open Lean Elab Tactic

/-- The set of safe Nat / Int simp lemmas the `auto` portfolio pulls in
    via its `simp` fallback. Inlined as a syntax helper rather than a
    `register_simp_attr` so applying it to existing core lemmas does
    not need a separate compilation unit. Phase 2 will switch to a
    `register_simp_attr leanpp_auto` user-extensible set. -/
syntax "leanpp_auto_simp_set" : tactic
macro_rules
  | `(tactic| leanpp_auto_simp_set) =>
      `(tactic| simp (config := { decide := true })
                  [Nat.zero_le, Nat.le_refl, Nat.add_zero, Nat.zero_add,
                   Nat.div_le_self, Nat.mod_le, Nat.div_mul_le_self,
                   Int.natAbs_neg])

/-- The portfolio of cheap closers, factored out so it can be reused
    after a `try intros` step. Tries each in order; succeeds at the
    first one that closes the goal. -/
syntax (name := autoCoreTac) "auto_core" : tactic

elab_rules : tactic
  | `(tactic| auto_core) => do
    evalTactic (← `(tactic|
      first
        | rfl
        | assumption
        | contradiction
        | decide
        | omega
        | (simp_all (config := { decide := true }); done)
        | (leanpp_auto_simp_set; done)
        | trivial
        -- `; done` is mandatory after `<;>` because the combinator can
        -- leave subgoals open without erroring; without it `first` would
        -- accept the partial state and downstream `sorry` fallback
        -- would not fire, producing "unsolved goals" failures instead.
        | (apply And.intro <;> auto_core; done)
        | (exact Nat.zero_le _)))

/-- `auto` — portfolio of core Lean 4 closers. Tries the bare-goal
    portfolio first; if that fails, introduces any leading universals
    / implications and retries. -/
syntax (name := autoTac) "auto" : tactic

elab_rules : tactic
  | `(tactic| auto) => do
    evalTactic (← `(tactic|
      first
        | auto_core
        | (intros; auto_core)))

/-- `auto?` — same as `auto` but never fails (turns failure into a no-op). -/
syntax (name := autoTryTac) "auto?" : tactic

elab_rules : tactic
  | `(tactic| auto?) => do
    evalTactic (← `(tactic| try auto))

/-! ## proofplan

  Surface form (simplified for MVP):

  ```
  proofplan myPlan
    strategy:
      normalize algebra
      rewrite using my_lemma
      close by simp
  ```

  This lowers to a `macro_rules`-style alias that, when invoked by name as
  a string-literal tactic, runs the expanded sequence.

  For MVP we keep the implementation simple: each `proofplan` declaration
  emits a `def`-shaped marker plus a `macro` that expands to the sequence.
-/

/-- A single strategy step. -/
declare_syntax_cat leanpp_plan_step

syntax "normalize" "algebra"                       : leanpp_plan_step
syntax "rewrite" "using" ident                     : leanpp_plan_step
syntax "rewrite" "using" "[" ident,* "]"           : leanpp_plan_step
syntax "close" "by" "simp"                         : leanpp_plan_step
syntax "close" "by" "auto"                         : leanpp_plan_step
syntax "close" "by" "omega"                        : leanpp_plan_step
syntax "close" "by" "decide"                       : leanpp_plan_step

/-- Top-level `proofplan` command. -/
syntax (name := proofplanCmd)
  "proofplan" ident "strategy" ":" (colGt leanpp_plan_step)* : command

/-- Helper: lower one plan step to a `tactic` syntax. -/
private def stepToTactic : Syntax → MacroM (TSyntax `tactic)
  | `(leanpp_plan_step| normalize algebra) =>
      `(tactic| try simp)
  | `(leanpp_plan_step| rewrite using $i:ident) =>
      `(tactic| try simp [$i:ident])
  | `(leanpp_plan_step| rewrite using [ $is:ident,* ]) => do
      -- `simp` only accepts a `simpLemma` list, not bare idents. Splice
      -- each ident as its own `try simp [i]` step and chain them.
      let mut steps : Array (TSyntax `tactic) := #[]
      for i in is.getElems do
        steps := steps.push (← `(tactic| try simp [$i:ident]))
      `(tactic| ($[$steps];*))
  -- Closing steps tolerate the case where an earlier step already closed
  -- the goal: if there are no goals, succeed; otherwise apply the closer.
  | `(leanpp_plan_step| close by simp) =>
      `(tactic| first | done | simp_all | simp)
  | `(leanpp_plan_step| close by auto) =>
      `(tactic| first | done | auto)
  | `(leanpp_plan_step| close by omega) =>
      `(tactic| first | done | omega)
  | `(leanpp_plan_step| close by decide) =>
      `(tactic| first | done | decide)
  | _ => `(tactic| skip)

open Command in
@[command_elab proofplanCmd]
def elabProofPlan : CommandElab := fun stx => do
  match stx with
  | `(proofplanCmd| proofplan $name:ident strategy : $steps:leanpp_plan_step*) => do
      -- Lower each step to a tactic syntax, then combine sequentially.
      -- Steps that don't close the goal are wrapped in `try`; the final
      -- `close by ...` step is expected to do the actual closing.
      let mut tacs : Array (TSyntax `tactic) := #[]
      for s in steps do
        let t ← liftMacroM (stepToTactic s)
        tacs := tacs.push t
      let combined ← `(tactic| ($[$tacs];*))
      -- Register `<name>` as a tactic alias. The outer quote constructs a
      -- `macro "<name>" : tactic => <body>` command; the body itself is a
      -- nested quote `(tactic| <combined>)` whose `$combined` antiquotation
      -- splices the planned tactic syntax tree into the macro at command-
      -- registration time, so the macro expansion is constant.
      let nmStr := name.getId.toString
      let nameTok : TSyntax `str := Syntax.mkStrLit nmStr
      let bodyTerm ← `(`(tactic| $combined))
      let macroCmd ← `(macro $nameTok:str : tactic => $bodyTerm:term)
      elabCommand macroCmd
      -- Also emit a marker `def` so the trust ledger / theorem index can
      -- later enumerate registered plans.
      let stubName := mkIdent (name.getId.appendAfter "_plan_marker")
      elabCommand (← `(/-- Lean++ proofplan marker. -/ def $stubName : Unit := ()))
  | _ => Lean.Elab.throwUnsupportedSyntax

end LeanPP
