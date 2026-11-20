/-
  Test03_SharedLemma: A lemma used by BOTH a live path and a dead path.

  shared_lemma → live_user → TARGET
  shared_lemma → dead_user (not used by TARGET)

  EXPECTED: dead_user should be removed, but shared_lemma must STAY
  (it's used by the live path).
  ACCEPTANCE: File compiles with dead_user removed but shared_lemma kept.
-/

-- Shared lemma: used by both live and dead paths
theorem shared_lemma : ∀ n : Nat, 0 + n = n := Nat.zero_add

-- Live user (reaches TARGET)
theorem live_user : 0 + 7 = 7 := shared_lemma 7

-- TARGET
theorem target : 0 + 7 = 7 := live_user

-- DEAD: uses shared_lemma but doesn't reach target
theorem dead_user : 0 + 99 = 99 := shared_lemma 99
