/-
  Test01_LinearChain: Simple linear dependency chain with dead lemma.

  Live chain: base_fact → step_one → step_two → TARGET
  Dead: dead_lemma (well-formed, checks, but never used by TARGET)

  EXPECTED: dead_lemma should be identified and removed.
  ACCEPTANCE: File compiles with dead_lemma removed.
-/

-- Live chain
theorem base_fact : 1 + 1 = 2 := by decide

theorem step_one : 2 + 2 = 4 := by decide

theorem step_two : 4 + 4 = 8 := by decide

-- TARGET: the final theorem the proof chain supports
theorem target : 1 + 1 = 2 ∧ 2 + 2 = 4 ∧ 4 + 4 = 8 :=
  ⟨base_fact, step_one, step_two⟩

-- DEAD: well-formed, checks, but not used by target
theorem dead_lemma : 3 + 3 = 6 := by decide
