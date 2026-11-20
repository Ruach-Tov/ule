/-
  Test19_InvalidSyntax: Input with syntax errors (violates G1).

  The tool should REJECT this input with a clear error message,
  not produce a corrupted or partial output.

  EXPECTED: Tool reports error (input doesn't parse). No output produced.
  This is a NEGATIVE TEST — we're testing error handling, not elimination.

  Properties tested: G1 violation handling
-/

-- This is intentionally broken Lean syntax
theorem target : 1 + = 2 := by decide
theorem unclosed_paren ( : Nat := 5
