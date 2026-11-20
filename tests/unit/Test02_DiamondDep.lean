/-
  Test02_DiamondDep: Diamond dependency with dead branch.

  Live diamond:
    base → left_path → TARGET
    base → right_path → TARGET
  Dead: dead_branch (depends on base, but TARGET doesn't use it)

  EXPECTED: dead_branch should be identified and removed.
  ACCEPTANCE: File compiles with dead_branch removed.
-/

-- Shared base
theorem base : ∀ n : Nat, n + 0 = n := Nat.add_zero

-- Left path (live)
theorem left_path : 5 + 0 = 5 := base 5

-- Right path (live)
theorem right_path : 10 + 0 = 10 := base 10

-- TARGET: uses both live paths
theorem target : 5 + 0 = 5 ∧ 10 + 0 = 10 :=
  ⟨left_path, right_path⟩

-- DEAD: depends on base, but target doesn't use it
theorem dead_branch : 42 + 0 = 42 := base 42
