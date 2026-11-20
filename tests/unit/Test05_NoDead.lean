/-
  Test05_NoDead: All lemmas are live. Nothing should be removed.

  Every theorem is part of the chain leading to TARGET.

  EXPECTED: No lemmas removed (tool should report "nothing dead").
  ACCEPTANCE: Output file identical to input file.
-/

theorem fact_a : 1 + 1 = 2 := by decide
theorem fact_b : 2 * 2 = 4 := by decide
theorem fact_c : 1 + 1 = 2 ∧ 2 * 2 = 4 := ⟨fact_a, fact_b⟩

-- TARGET: uses everything
theorem target : (1 + 1 = 2 ∧ 2 * 2 = 4) := fact_c
