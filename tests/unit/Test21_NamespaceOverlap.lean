/-
  Test21_NamespaceOverlap: Same lemma name in different namespaces.

  Tests that the tool resolves names correctly with qualified paths
  and doesn't confuse Foo.helper with Bar.helper.

  Live: A.helper (used by TARGET)
  Dead: B.helper (same unqualified name, different namespace, not used)

  EXPECTED: B.helper removed. A.helper preserved.
  ACCEPTANCE: File compiles with B.helper removed.

  Properties tested: E11, G7
  NOTE: G7 says TARGET names are unambiguous. This tests that
  NON-TARGET names can be ambiguous without breaking the tool.
-/

namespace A

theorem helper : 1 + 1 = 2 := by decide

end A

namespace B

-- DEAD: same name as A.helper but different namespace, not used by TARGET
theorem helper : 3 + 3 = 6 := by decide

end B

-- TARGET: uses A.helper, not B.helper
theorem target : 1 + 1 = 2 := A.helper
