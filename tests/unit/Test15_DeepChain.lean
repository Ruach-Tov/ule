/-
  Test15_DeepChain: Deeply nested live dependency chain (20 levels).

  Tests that the tool handles deep transitive closures without
  stack overflow or performance issues.

  Live: chain_0 through chain_19 → TARGET
  Dead: dead_deep (not in the chain)

  EXPECTED: dead_deep removed. All 20 chain links preserved.
  ACCEPTANCE: File compiles with dead_deep removed.

  Properties tested: S1, E12
-/

theorem chain_0 : 0 = 0 := rfl
theorem chain_1 : 0 = 0 ∧ 1 = 1 := ⟨chain_0, rfl⟩
theorem chain_2 : (0 = 0 ∧ 1 = 1) ∧ 2 = 2 := ⟨chain_1, rfl⟩
theorem chain_3 : ((0 = 0 ∧ 1 = 1) ∧ 2 = 2) ∧ 3 = 3 := ⟨chain_2, rfl⟩
theorem chain_4 : True := by trivial
theorem chain_5 : True ∧ True := ⟨chain_4, chain_4⟩
theorem chain_6 : True := chain_5.1
theorem chain_7 : True ∧ True := ⟨chain_6, trivial⟩
theorem chain_8 : True := chain_7.1
theorem chain_9 : True ∧ True := ⟨chain_8, trivial⟩
theorem chain_10 : True := chain_9.1
theorem chain_11 : True ∧ True := ⟨chain_10, trivial⟩
theorem chain_12 : True := chain_11.1
theorem chain_13 : True ∧ True := ⟨chain_12, trivial⟩
theorem chain_14 : True := chain_13.1
theorem chain_15 : True ∧ True := ⟨chain_14, trivial⟩
theorem chain_16 : True := chain_15.1
theorem chain_17 : True ∧ True := ⟨chain_16, trivial⟩
theorem chain_18 : True := chain_17.1
theorem chain_19 : True ∧ True := ⟨chain_18, trivial⟩

-- TARGET: end of the 20-level chain
theorem target : True := chain_19.1

-- DEAD: not part of the chain
theorem dead_deep : 999 = 999 := rfl
