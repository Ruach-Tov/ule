/-
  Test10_SorryDep: sorry'd lemmas in the dependency chain.

  PRINCIPLE: sorry doesn't affect liveness. A sorry'd lemma is live if TARGET
  depends on it. The tool must treat sorry as OPAQUE — liveness comes from
  the dependency graph, not proof completeness.

  USE CASE: A disproof might deliberately construct a chain leading to False
  with sorry as the frontier — removing the sorry'd lemma would destroy the
  proof structure being developed.

  Case A: sorry_lemma is live (TARGET depends on it despite sorry)
  Case B: sorry_target_dep is live (TARGET itself uses sorry, dep is still live)
  Dead: dead_sorry (sorry'd but not in TARGET's chain)

  EXPECTED: dead_sorry removed. sorry_lemma AND sorry_target_dep PRESERVED.
  ACCEPTANCE: File compiles with dead_sorry removed.

  Properties tested: S1, E6
-/

-- Live (despite sorry): TARGET depends on this
theorem sorry_lemma : ∀ n : Nat, n < n + 1 := by
  intro n
  sorry

-- Live: used by the sorry-bearing target below
theorem sorry_target_dep : 1 + 1 = 2 := by decide

-- TARGET A: uses sorry_lemma (a sorry'd dependency is still live)
theorem target : 5 < 6 := sorry_lemma 5

-- TARGET B: the target ITSELF uses sorry, but its dependencies are still live
-- (Think: a disproof in progress — the sorry is the frontier)
theorem target_frontier : 1 + 1 = 2 ∧ False := by
  constructor
  · exact sorry_target_dep
  · sorry

-- DEAD: also sorry'd but not used by either target
theorem dead_sorry : ∀ n : Nat, n ≤ n := by
  intro n
  sorry
