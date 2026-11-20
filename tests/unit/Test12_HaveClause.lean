/-
  Test12_HaveClause: Lemma used inside a `have` clause in TARGET's proof.

  The dependency appears inside the proof term, not at the top level.

  Live: inner_fact (used in a `have` inside TARGET)
  Dead: dead_fact (not used anywhere in TARGET)

  EXPECTED: dead_fact removed. inner_fact preserved.
  ACCEPTANCE: File compiles with dead_fact removed.

  Properties tested: S1, E9
-/

-- Live: used inside TARGET's proof via `have`
theorem inner_fact : 2 + 3 = 5 := by decide

-- TARGET: uses inner_fact in a `have` clause
theorem target : 5 = 5 := by
  have h := inner_fact
  rfl

-- DEAD
theorem dead_fact : 7 + 7 = 14 := by decide
