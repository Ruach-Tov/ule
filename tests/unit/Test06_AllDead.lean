/-
  Test06_AllDead: TARGET has no dependencies — everything else is dead.

  TARGET is self-contained (trivial). All other lemmas are dead.

  EXPECTED: All lemmas except target removed.
  ACCEPTANCE: File compiles with only target remaining.
-/

-- All dead
theorem orphan_a : 1 + 1 = 2 := by decide
theorem orphan_b : 2 + 2 = 4 := by decide
theorem orphan_c : orphan_a = orphan_a := rfl

-- TARGET: self-contained, no dependencies
theorem target : True := trivial
