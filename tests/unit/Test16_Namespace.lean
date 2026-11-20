/-
  Test16_Namespace: Items inside namespaces and sections.

  The tool must preserve namespace/section structure for live items
  and handle qualified names correctly.

  Live: MyNamespace.helper → TARGET (outside namespace, uses qualified name)
  Dead: MyNamespace.dead_in_ns

  EXPECTED: MyNamespace.dead_in_ns removed. MyNamespace.helper preserved.
  Namespace structure preserved.
  ACCEPTANCE: File compiles with dead items removed.

  Properties tested: S7, P3, P5
-/

namespace MyNamespace

-- Live: used by TARGET via qualified name
theorem helper : 2 + 2 = 4 := by decide

-- DEAD: inside namespace but not used by TARGET
theorem dead_in_ns : 3 + 3 = 6 := by decide

end MyNamespace

-- TARGET: uses MyNamespace.helper
theorem target : 2 + 2 = 4 := MyNamespace.helper
