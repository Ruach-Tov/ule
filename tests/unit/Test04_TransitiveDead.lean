/-
  Test04_TransitiveDead: A chain of dead lemmas, none reaching TARGET.

  Live: simple_fact → TARGET
  Dead chain: dead_root → dead_middle → dead_leaf (all dead)

  EXPECTED: All three dead lemmas should be removed.
  ACCEPTANCE: File compiles with the entire dead chain removed.
-/

-- Live
theorem simple_fact : True := trivial

-- TARGET
theorem target : True := simple_fact

-- DEAD CHAIN: none reach target
theorem dead_root : 1 = 1 := rfl
theorem dead_middle : 1 = 1 ∧ 2 = 2 := ⟨dead_root, rfl⟩
theorem dead_leaf : 1 = 1 ∧ 2 = 2 ∧ 3 = 3 := ⟨dead_middle.1, dead_middle.2, rfl⟩
