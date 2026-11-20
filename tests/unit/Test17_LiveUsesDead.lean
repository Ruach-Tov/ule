/-
  Test17_LiveUsesDead: A dead lemma that USES a live lemma.

  This tests property C4: "Dead items that depend on live items are still removed."
  Using a live item doesn't make you live — only being USED BY TARGET makes you live.

  Live: shared_base → TARGET
  Dead: dead_user_of_live (uses shared_base, but TARGET doesn't use dead_user_of_live)

  EXPECTED: dead_user_of_live removed. shared_base preserved.
  ACCEPTANCE: File compiles with dead_user_of_live removed.

  Properties tested: C4, S1
-/

-- Live: used by TARGET
theorem shared_base : ∀ n : Nat, n = n := fun _ => rfl

-- TARGET
theorem target : 42 = 42 := shared_base 42

-- DEAD: uses a live lemma, but that doesn't make it live
theorem dead_user_of_live : 100 = 100 := shared_base 100
