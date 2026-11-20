/-
  Test13_MultipleTargets: Two target theorems with different dependency chains.

  target_a uses chain_a
  target_b uses chain_b
  dead_lemma used by neither

  EXPECTED: dead_lemma removed. Both chains preserved.
  ACCEPTANCE: File compiles with dead_lemma removed.

  Properties tested: E10

  NOTE: Tool must accept a LIST of roots, not just one.
  Convention: targets are target_a and target_b (the tool is told both are roots).
-/

-- Chain A (live for target_a)
theorem chain_a : 1 + 1 = 2 := by decide

-- Chain B (live for target_b)
theorem chain_b : 3 + 3 = 6 := by decide

-- TARGET A
theorem target_a : 1 + 1 = 2 := chain_a

-- TARGET B
theorem target_b : 3 + 3 = 6 := chain_b

-- DEAD: not used by either target
theorem dead_lemma : 9 + 9 = 18 := by decide
