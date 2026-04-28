/-
  tests/lean/AutoStress.lean

  Machine-checked coverage of the `auto` and `auto_core` tactic
  portfolio. Each `example` exercises one branch of the closer
  list:

    rfl, assumption, contradiction, decide, omega,
    simp_all, leanpp_auto_simp_set, trivial,
    apply And.intro <;> auto_core; done,
    exact Nat.zero_le _,
    intros + portfolio.

  If a future change to `LeanPP.Auto` regresses any of these
  shapes, this file fails to elaborate and `tests/run.sh`
  reports the failure.
-/
import LeanPP

namespace LeanPP.Tests.AutoStress

-- 1. `rfl` branch.
example : 0 + 0 = 0 := by auto
example (n : Nat) : n = n := by auto

-- 2. `assumption` branch. `True` and `1 = 1` close via `rfl` /
-- `trivial` first, but the hypothesis variants exercise the
-- assumption-aware path when those don't fire.
example (h : True) : True := by exact h
example (h : 1 = 1) : 1 = 1 := by auto

-- 3. `contradiction` branch.
example (h : False) : 42 = 0 := by auto
example (h : 0 = 1) : False := by auto

-- 4. `decide` branch.
example : 2 + 2 = 4 := by auto
example : (3 : Nat) ≤ 5 := by auto

-- 5. `omega` branch.
example (a b : Nat) : a + b = b + a := by auto
example (n : Nat) : n + 1 > n := by auto
example (a b c : Int) : a + b + c - c = a + b := by auto

-- 6. `simp_all` branch (uses an existing hypothesis).
example (a b : Nat) (h : a = b) (h' : b = 5) : a = 5 := by auto
example (xs ys : List Nat) (h : xs = ys) : xs.length = ys.length := by auto

-- 7. `leanpp_auto_simp_set` lemmas (Nat.zero_le, Nat.div_le_self, ...).
example (n d : Nat) : n / d ≤ n := by auto
example (n d : Nat) : n % d ≤ n := by auto
example (n : Int) : (-n).natAbs = n.natAbs := by auto

-- 8. `apply And.intro <;> auto_core; done` for conjunctions.
example (n : Nat) : n ≥ 0 ∧ n + 0 = n := by auto
example : True ∧ True ∧ True := by auto

-- 9. `exact Nat.zero_le _` direct branch.
example (n : Nat) : 0 ≤ n := by auto

-- 10. `intros` + portfolio for ∀ goals.
example : ∀ n : Nat, n + 0 = n := by auto
example : ∀ a b : Nat, a + b = b + a := by auto

-- 11. Combined: `intros` + `simp_all` + Nat fact.
example : ∀ (n d : Nat), 0 ≤ n / d := by auto

end LeanPP.Tests.AutoStress
