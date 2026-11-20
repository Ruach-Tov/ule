/-
  Test11_SimpAttribute: Lemma used via @[simp] attribute in tactic proof.

  EDGE CASE: A @[simp] lemma may be used by `simp` tactic inside TARGET's
  proof without appearing as an explicit reference in the term. The tool must
  detect this through Lean's Environment API, not text search.

  Live: simp_lemma (used by simp tactic in TARGET)
  Dead: dead_simp_lemma (also @[simp] but not used in TARGET's proof)

  EXPECTED: dead_simp_lemma removed. simp_lemma preserved.
  ACCEPTANCE: File compiles with dead_simp_lemma removed.

  Properties tested: S1, E8
  NOTE: Whether @[simp] lemmas not explicitly used by TARGET's proof are "live"
  depends on tool design. Conservative: keep all @[simp]. Aggressive: trace usage.
  This test expects AGGRESSIVE (trace actual simp usage).
-/

@[simp]
theorem simp_lemma : ∀ n : Nat, n + 0 = n := Nat.add_zero

-- TARGET: uses simp_lemma via simp tactic
theorem target : 42 + 0 = 42 := by simp

-- DEAD: @[simp] but not used in target's proof
@[simp]
theorem dead_simp_lemma : ∀ n : Nat, 0 * n = 0 := Nat.zero_mul
