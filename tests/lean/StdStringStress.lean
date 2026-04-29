/-
  tests/lean/StdStringStress.lean

  Machine-checked coverage of `LeanPP.Std.String`. Pins
  `isDigit` / `digitOf?` evaluation and the two correspondence
  lemmas.
-/
import LeanPP

open LeanPP.Std.String

namespace LeanPP.Tests.StdStringStress

-- isDigit returns `true` for '0'..'9', `false` otherwise.
example : isDigit '0' = true  := by decide
example : isDigit '5' = true  := by decide
example : isDigit '9' = true  := by decide
example : isDigit 'a' = false := by decide
example : isDigit ' ' = false := by decide
example : isDigit '/' = false := by decide  -- character just below '0'
example : isDigit ':' = false := by decide  -- character just above '9'

-- digitOf? returns the numeric value for digits, none otherwise.
example : digitOf? '0' = some 0 := by decide
example : digitOf? '5' = some 5 := by decide
example : digitOf? '9' = some 9 := by decide
example : digitOf? 'x' = none   := by decide

-- digitOf?_isDigit is the forward direction.
example {c : Char} {d : Nat} (h : digitOf? c = some d) :
    isDigit c = true := digitOf?_isDigit h

-- digitOf?_none_iff is the no-digit ↔ isDigit-false equivalence.
example {c : Char} (h : isDigit c = false) :
    digitOf? c = none := digitOf?_none_iff.mpr h

example {c : Char} (h : digitOf? c = none) :
    isDigit c = false := digitOf?_none_iff.mp h

-- All exported lemmas exist with the documented types.
#check @isDigit
#check @digitOf?
#check @digitOf?_isDigit
#check @digitOf?_none_iff

end LeanPP.Tests.StdStringStress
