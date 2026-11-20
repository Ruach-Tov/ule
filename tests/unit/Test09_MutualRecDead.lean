/-
  Test09_MutualRecDead: Mutually recursive dead lemmas.

  Dead: dead_a and dead_b reference each other, neither reaches TARGET.
  The tool must handle cycles in the dependency graph without infinite loops.

  EXPECTED: Both dead_a and dead_b removed.
  ACCEPTANCE: File compiles with both removed.

  Properties tested: C1, C3, E5
-/

-- Live
theorem live_fact : 1 = 1 := rfl

-- TARGET
theorem target : 1 = 1 := live_fact

-- DEAD: mutual references, neither reaches target
mutual
  def dead_a : Nat → Nat
    | 0 => 1
    | n + 1 => dead_b n

  def dead_b : Nat → Nat
    | 0 => 2
    | n + 1 => dead_a n
end

-- DEAD: theorem about the mutual defs
theorem dead_about_mutual : dead_a 0 = 1 := rfl
