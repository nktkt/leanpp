/-
  LeanPP/Trust.lean
  ----------------------------------------------------------------------------
  Trust ledger primitives.

  This module exposes:
    * `register_option leanpp.profile` — current trust profile.
    * `#profile <name>` — switch profile.
    * `#trust` — print a trust-ledger snapshot.
    * `@[obligation]` attribute — mark a theorem as a verification obligation.
    * `@[law]` attribute — mark a theorem as a structure law.
    * `#assertSafe` — guardrail used in the `safe` profile.
-/
import Lean

namespace LeanPP.Trust

open Lean

/-- Registered Lean option that holds the current trust profile. -/
register_option leanpp.profile : String := {
  defValue := "research"
  descr    := "Lean++ trust profile (safe | research | systems | education)"
}

/-- Validate a profile name. -/
def validProfiles : List String :=
  ["safe", "research", "systems", "education"]

/-- The set of "baseline" axioms always considered acceptable. -/
def baselineAxioms : List Name :=
  [`Classical.choice, `Quot.sound, `propext]

/-! ### Attributes -/

/-- A tag attribute marking a theorem as an unsolved verification obligation.
    The CLI's `leanpp obligations` command scans for these. -/
initialize obligationAttr : TagAttribute ←
  registerTagAttribute `obligation
    "marks a theorem as a Lean++ verification obligation"

/-- A tag attribute marking a theorem as a `concept` law. -/
initialize lawAttr : TagAttribute ←
  registerTagAttribute `law
    "marks a theorem as a structure law of a Lean++ `concept`"

/-- A tag attribute marking a definition as `verified extern` (FFI). -/
initialize verifiedExternAttr : TagAttribute ←
  registerTagAttribute `verified_extern
    "marks a declaration as a Lean++ verified-extern (FFI) entry"

/-! ### Profile command -/

/-- `#profile safe` — set the active Lean++ trust profile. -/
syntax (name := profileCmd)
  "#profile" ("safe" <|> "research" <|> "systems" <|> "education") : command

/-- Find the first atom in a syntax tree (used to extract the chosen
    keyword from an alternation node). -/
private partial def firstAtom (s : Syntax) : String :=
  if s.isAtom then s.getAtomVal
  else
    let rec go (xs : List Syntax) : String :=
      match xs with
      | [] => ""
      | x :: rest =>
        let r := firstAtom x
        if r != "" then r else go rest
    go s.getArgs.toList

open Elab Command in
@[command_elab profileCmd]
def elabProfile : CommandElab := fun stx => do
  let prof : String := firstAtom stx[1]
  if !validProfiles.contains prof then
    logWarning s!"unknown profile '{prof}', expected one of {validProfiles}"
  else
    modifyScope fun sc =>
      { sc with opts := leanpp.profile.set sc.opts prof }
    logInfo s!"LeanPP profile set to '{prof}'"

/-! ### Ledger snapshot -/

/-- A summary of trust-relevant declarations in the current environment. -/
structure Snapshot where
  axiomsExtra    : Array Name := #[]    -- axioms beyond the baseline
  sorryDecls     : Array Name := #[]    -- defs/theorems containing `sorryAx`
  unsafeDecls    : Array Name := #[]    -- `unsafe def`s
  externDecls    : Array Name := #[]    -- declarations with `@[extern]`
  obligations    : Array Name := #[]    -- declarations tagged `@[obligation]`
  laws           : Array Name := #[]    -- declarations tagged `@[law]`
  deriving Inhabited

/-- True if the constant's body uses `sorryAx`. -/
private def usesSorry (_env : Environment) (c : ConstantInfo) : Bool :=
  match c.value? (allowOpaque := true) with
  | some e => e.hasSorry
  | none   => c.type.hasSorry

/-- True for decls that originate in the *current* module (not imports).
    The trust ledger uses this to ignore Lean core / Std / library noise so
    the report focuses on user code. -/
private def isCurrentModule (env : Environment) (n : Name) : Bool :=
  env.getModuleIdxFor? n |>.isNone

/-- Compute a snapshot of trust-relevant data for the current module. -/
def snapshot : CoreM Snapshot := do
  let env ← getEnv
  let mut snap : Snapshot := {}
  for (n, c) in env.constants.toList do
    -- skip internal / compiler-generated names and decls from imports.
    if n.isInternal then continue
    if !isCurrentModule env n then continue
    match c with
    | .axiomInfo _ =>
        if !baselineAxioms.contains n then
          snap := { snap with axiomsExtra := snap.axiomsExtra.push n }
    | _ =>
        if usesSorry env c then
          snap := { snap with sorryDecls := snap.sorryDecls.push n }
        if c.isUnsafe then
          snap := { snap with unsafeDecls := snap.unsafeDecls.push n }
        if Compiler.getImplementedBy? env n |>.isSome then
          snap := { snap with externDecls := snap.externDecls.push n }
        if obligationAttr.hasTag env n then
          snap := { snap with obligations := snap.obligations.push n }
        if lawAttr.hasTag env n then
          snap := { snap with laws := snap.laws.push n }
  return snap

private def fmtList (label : String) (xs : Array Name) : String :=
  if xs.isEmpty then s!"  {label}: 0"
  else
    let names := xs.toList.map (·.toString) |>.take 8
    let extra := if xs.size > 8 then s!" (+{xs.size - 8} more)" else ""
    let joined := String.intercalate ", " names
    s!"  {label}: {xs.size} — {joined}{extra}"

/-- `#trust` — print a trust-ledger snapshot. -/
syntax (name := trustCmd) "#trust" : command

/-- `#trust IDENT` — print a focused trust-ledger entry for one declaration.
    Inspects the named const for `sorryAx` / unsafety / external bindings
    plus any axioms transitively reachable from its definition. -/
syntax (name := trustTargetCmd) "#trust" ident : command

open Elab Command in
@[command_elab trustCmd]
def elabTrust : CommandElab := fun _ => do
  let snap ← liftCoreM snapshot
  let prof := leanpp.profile.get (← getOptions)
  let parts : List String :=
    [ "Trust Ledger (LeanPP MVP)"
    , s!"  kernel: Lean 4 (unmodified)"
    , s!"  profile: {prof}"
    , s!"  baseline axioms: Classical.choice, Quot.sound, propext"
    , fmtList "extra axioms"  snap.axiomsExtra
    , fmtList "sorry decls"   snap.sorryDecls
    , fmtList "unsafe decls"  snap.unsafeDecls
    , fmtList "extern decls"  snap.externDecls
    , fmtList "obligations"   snap.obligations
    , fmtList "laws"          snap.laws ]
  logInfo (String.intercalate "\n" parts)

/-- Collect axiom names transitively reachable from a constant's definition. -/
private def axiomsOf (env : Environment) (n : Name) : Array Name := Id.run do
  let mut visited : NameSet := {}
  let mut axs : Array Name := #[]
  let mut stack : Array Name := #[n]
  while h : stack.size > 0 do
    let x := stack.back
    stack := stack.pop
    if !visited.contains x then
      visited := visited.insert x
      match env.find? x with
      | none => pure ()
      | some (.axiomInfo _) => axs := axs.push x
      | some c =>
        match c.value? (allowOpaque := true) with
        | none => pure ()
        | some val =>
          -- Collect referenced const names from `val`, then push the
          -- unvisited ones onto the stack. We can't mutate `stack`
          -- inside the foldConsts callback because the closure captures
          -- the value at creation time, so we accumulate into a fresh
          -- array first.
          let refs := val.foldConsts (#[] : Array Name) (fun nm acc => acc.push nm)
          for nm in refs do
            if !visited.contains nm then stack := stack.push nm
  pure axs

private def yesNo (b : Bool) : String := if b then "yes" else "no"

open Elab Command in
@[command_elab trustTargetCmd]
def elabTrustTarget : CommandElab := fun stx => do
  match stx with
  | `(#trust $n:ident) => do
      let env ← getEnv
      let resolved ← liftCoreM (Lean.realizeGlobalConstNoOverload n)
      let some c := env.find? resolved
        | throwError s!"#trust: unknown declaration `{resolved}`"
      let usesSorry :=
        match c.value? (allowOpaque := true) with
        | some e => e.hasSorry
        | none   => c.type.hasSorry
      let usesUnsafe := c.isUnsafe
      let isExternDecl := isExtern env resolved
      let allAx := axiomsOf env resolved
      let extraAx := allAx.filter fun a => !baselineAxioms.contains a
      let hasObligation := obligationAttr.hasTag env resolved
      let hasLaw        := lawAttr.hasTag env resolved
      let prof := leanpp.profile.get (← getOptions)
      let parts : List String :=
        [ s!"Trust Ledger: {resolved}"
        , s!"  kernel:     Lean 4 (unmodified)"
        , s!"  profile:    {prof}"
        , s!"  sorry:      {yesNo usesSorry}"
        , s!"  unsafe:     {yesNo usesUnsafe}"
        , s!"  extern:     {yesNo isExternDecl}"
        , s!"  obligation: {yesNo hasObligation}"
        , s!"  law:        {yesNo hasLaw}"
        , fmtList "axioms"  extraAx
        , s!"  baseline axioms: Classical.choice, Quot.sound, propext" ]
      logInfo (String.intercalate "\n" parts)
  | _ => throwUnsupportedSyntax

/-! ### #assertSafe -/

/-- `#assertSafe` — fails (as an error) if any user-namespace declaration in
    the current environment uses `sorryAx`. Intended for use in the `safe`
    profile and CI guardrails. -/
syntax (name := assertSafeCmd) "#assertSafe" : command

open Elab Command in
@[command_elab assertSafeCmd]
def elabAssertSafe : CommandElab := fun _ => do
  let snap ← liftCoreM snapshot
  if snap.sorryDecls.isEmpty && snap.axiomsExtra.isEmpty then
    logInfo "LeanPP: #assertSafe — environment is sorry/axiom-clean."
  else
    let names := (snap.sorryDecls ++ snap.axiomsExtra).toList.map (·.toString)
    throwError "LeanPP: #assertSafe failed — non-baseline declarations:\n  {names}"

end LeanPP.Trust
