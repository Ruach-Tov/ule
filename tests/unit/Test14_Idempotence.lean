/-
  Test14_Idempotence: Already-minimal file. Tool should be a no-op.

  This file IS the expected output of running the tool on itself.
  Running the tool twice must produce identical output both times.

  EXPECTED: Output identical to input.
  ACCEPTANCE: diff input output → empty.

  Properties tested: I1, I2, E2
-/

-- Live chain (minimal — no dead items)
theorem fact_one : Nat.succ 0 = 1 := rfl

-- TARGET: direct dependency
theorem target : Nat.succ 0 = 1 := fact_one
