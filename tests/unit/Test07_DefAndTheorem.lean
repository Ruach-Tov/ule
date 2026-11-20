/-
  Test07_DefAndTheorem: Definitions (def/noncomputable def) used by TARGET.

  A definition is live if used in the proof chain, even though it's not a theorem.

  Live: helper_def (a function used in TARGET's proof)
  Dead: dead_def (a function not used by TARGET)

  EXPECTED: dead_def and dead_about_dead removed. helper_def stays.
  ACCEPTANCE: File compiles with dead items removed.
-/

-- Live definition: used in TARGET's proof
def helper_def (n : Nat) : Nat := n * 2

-- Live theorem: uses helper_def
theorem helper_property : helper_def 5 = 10 := rfl

-- TARGET: uses helper_property
theorem target : helper_def 5 = 10 := helper_property

-- DEAD definition: not used by TARGET
def dead_def (n : Nat) : Nat := n * 3

-- DEAD theorem about dead definition
theorem dead_about_dead : dead_def 5 = 15 := rfl
