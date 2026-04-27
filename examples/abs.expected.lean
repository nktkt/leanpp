-- Generated from abs.leanpp by leanpp-transpile (HAND-WRITTEN reference for docs).
-- Demonstrates the lowering target: ordinary Lean 4 def + theorem.
--
-- The Lean++ source file is `abs.leanpp` in this directory.
-- A `spec def NAME ... ensures POST by implementation BODY proof PROOF` block
-- lowers to:
--   1. an ordinary `def NAME ... := BODY`
--   2. one `theorem NAME.ensures_k ... := PROOF` per `ensures` clause
--   3. (optionally) a registration call into the LeanPP trust ledger so
--      `#trust NAME` and `#obligations` can find it.

import LeanPP
open LeanPP

#profile safe

def abs (x : Int) : Nat :=
  if x < 0 then Int.natAbs (-x) else Int.natAbs x

namespace abs

theorem ensures_1 (x : Int) : abs x ≥ 0 := by
  unfold abs
  split <;> exact Nat.zero_le _

end abs

-- Trust-ledger registration. The stdlib provides `LeanPP.registerSpec`
-- as a no-op (or attribute) in the MVP; later phases will record provenance.
-- #eval LeanPP.registerSpec ``abs #[``abs.ensures_1]
