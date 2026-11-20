/-
  Test20_BuildFails: Input that parses but fails to build (violates G2).

  Valid syntax, but type error — disposition is "fails", not ∈ {sorry, succeeds}.
  The tool should REJECT this input.

  EXPECTED: Tool reports error (input doesn't build). No output produced.
  This is a NEGATIVE TEST.

  Properties tested: G2 violation handling
-/

-- Valid syntax, but type error
theorem target : 1 + 1 = 3 := by decide
