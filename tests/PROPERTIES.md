# Unused-Lemma-Elimination Tool: Property Inventory

## GIVENS (preconditions — what the tool may assume about its input)

G1: Input is valid Lean 4 syntax (parses without syntax errors)
G2: Input builds successfully with disposition ∈ {sorry, succeeds}
    - "sorry" = compiles with sorry warnings (incomplete proofs)
    - "succeeds" = compiles cleanly with no warnings
    - NOT accepted: input that fails to build (type errors, unresolved names, etc.)
G3: At least one TARGET theorem is specified by name
G4: Every specified TARGET exists in the input file
G5: Input is a single file (multi-file/import-chain elimination is out of scope)
G6: Input uses standard Lean 4 (no custom plugins/macros that alter the Environment)
G7: TARGET names are unambiguous within the file (no overloaded target names)
G8: The build environment (toolchain version, lake manifest) is pinned. Disposition
    comparison across toolchains is meaningless. The minimized file is verified
    under the SAME toolchain as the original. (Bocher)

The tool is NOT required to:
- Fix syntax errors (violates G1)
- Handle files that don't build (violates G2)
- Guess which theorem is the target (violates G3)
- Operate across file boundaries (violates G5)

If a given is violated, the tool SHOULD report an error, not produce wrong output.

## CORRECTNESS PROPERTIES (the tool must satisfy ALL, given G1-G8)

### Soundness (never remove anything live)
S1: Every lemma used (directly or transitively) by TARGET is preserved
S2: Every definition used by a preserved lemma is preserved
S3: Every typeclass instance resolved by a preserved lemma is preserved
S4: Every axiom/import used by a preserved lemma is preserved
S5: The minimized file builds without errors under the pinned configuration.
    Disposition ∈ {sorry, succeeds} applies to RETAINED declarations only.
S5b: For each RETAINED declaration, its direct use of sorryAx in its type
     or value is preserved. (Bocher, corrected per ChatGPT)
S5c: For each TARGET, its transitive dependence on sorryAx is preserved.
     A target can inherit a hole from a helper even when its own proof
     contains no sorry. (ChatGPT)
S6: The TARGET theorem is always preserved (never removed)
S7: Namespace/section openers needed by preserved items are preserved
S8: For every preserved proof that invokes `simp`, the simp set in the
    minimized file still closes the goal. (Bocher)
S9: When --lint-simp is passed, a dead lemma with simp-eligible shape
    (equational, iff) but no @[simp] tag produces a warning.
S10: Each target resolves to its original fully qualified declaration, remains
     a theorem, and has the same elaborated type. Preserve universe parameters,
     binder order, implicitness, instance binders, and named arguments. (ChatGPT)
S11: The transitive axiom dependencies per target are identical before and after.
     Compare via #print axioms. Include sorryAx, user axioms, and axioms from
     native evaluation. Two targets can exchange deps while the union stays
     the same — compare PER TARGET. (ChatGPT)
S12: A target may not silently switch to a different proof. Compare original
     and rebuilt declaration dependencies for each retained proof. Lean's proof
     irrelevance makes definitional equality of proof witnesses too weak for
     this check. (ChatGPT)

### Attribute/Metadata Liveness (Bocher)
A1: An item live only via attribute-driven automation (implicit, easy to
    overlook) is detected as live. Quantifies over: @[simp], @[instance],
    @[ext], @[norm_num], @[coe], @[reducible]. (Bocher)
A2: A dead lemma's attributes are removed with the lemma. (Bocher)

### Elaboration-Level Dependencies (Bocher, expanded per ChatGPT)
D1: Liveness is computed on the elaborated term (Expr) AND on replay
    dependencies. A declaration can be needed for replay even when absent
    from the mathematical witness (e.g. `change GoalAlias` needs GoalAlias
    to elaborate even though the proof term is True.intro). (Bocher,
    corrected per ChatGPT)
D2: Removing a dead item must not change universe unification for a live item.
    Test the observable universe interface: a client supplying target.{u,v}
    retains the same interpretation. Test with u ≠ v to catch parameter
    swaps. (Bocher, sharpened per ChatGPT)
D3: A notation used by a live proof is live. A notation used only by dead
    proofs is dead. (Bocher)
D4: Source-command ownership: the unit of removal is a whole source command,
    not individual declarations. An inductive command generates constructors,
    recursors, projections, equation theorems — retain the command as a unit.
    A target can use a constructor without naming its producing command.
    C1-C2 operate on source commands, not individual generated names. (ChatGPT)

### Completeness (remove everything dead)
C1: Every source command NOT needed to replay any TARGET's transitive
    dependencies is removed. (Revised per D4: operates on source commands.)
C2: Applies to definitions, abbreviations, and notation commands. (Revised per D4.)
C3: Dead chains (A→B→C, none reaching TARGET) are entirely removed
C4: Dead items that depend on live items are still removed (using live ≠ being live)

### Idempotence
I1: Running the tool twice produces the same output as running it once.
    Reachability is computed once on the ORIGINAL dependency graph. The tool
    computes the least fixed point in O(V+E), including cycles. I1 constrains
    the observable result of a second invocation. (Resolved per ChatGPT:
    one-pass on original graph, not iterative re-elaboration.)
I2: Running the tool on an already-minimal file is a no-op

### Validation
V1: The minimized source is validated from a fresh Lean process at the original
    logical module path, with the same imports, dependency revisions, and build
    options. The candidate cannot pick up the original module's compiled artifact.
    A timeout or resource limit means the candidate is unverified. (ChatGPT)

### Edge Cases
E1: Empty file (no theorems) → output is empty file
E2: File with only TARGET and no other items → output equals input
E3: File where ALL items except TARGET are dead → only TARGET remains
E4: File where NOTHING is dead → output equals input
E5: Mutual recursion: two lemmas that reference each other, both dead
E6: sorry'd proof: a lemma with `sorry` that TARGET depends on is LIVE.
    sorry is OPAQUE for liveness — only the dependency graph matters.
    Use case: disproof construction with sorry as the frontier.
    NOTE: a sorry'd declaration's STATEMENT can still mention local
    definitions that must survive. (Sharpened per ChatGPT)
E7: Typeclass instance used only implicitly (instance resolution, no explicit reference)
E8: Lemma used in a tactic (simp lemma, @[simp] attribute)
E9: Lemma used in a `have` clause inside TARGET's proof
E10: Multiple TARGET theorems (tool should accept list of roots)
E11: Duplicate names in different namespaces (shouldn't confuse the tool)
E12: Deeply nested dependencies (100+ levels deep — performance)
E13: A local macro expands to `exact helper` — replay needs the macro rule.
     Test a macro used in the STATEMENT as well as one used in the proof. (ChatGPT)
E14: `attribute [local simp] f` followed by `attribute [-simp] g` — a command
     that REMOVES a rule can be live. A1 must cover changes to automation
     tables, their order, and their scope. (ChatGPT)
E15: A tactic queries whether a declaration exists, then emits True.intro.
     The returned term contains no record of the query. Document when the tool
     conservatively retains source or reports it cannot certify completeness. (ChatGPT)
E16: A section variable enters the target through `include`, or an instance
     occurs only in its statement. Walking only the proof body misses part
     of the theorem's interface. (ChatGPT)
E17: Two equal-priority instances or two proofs of the same proposition in scope.
     Deletion can change which witness is selected while the file stays green.
     Test with different axiom deps AND identical axiom deps to test S11 and
     S12 independently. (ChatGPT)
E18: A retained #check, #guard_msgs, or anonymous example refers to an otherwise
     dead lemma. The tool must decide: are these validation roots or removable
     development artifacts? Either policy is coherent; leaving it implicit
     makes C1 ambiguous. (ChatGPT)

### Structural Preservation
P1: Output is valid Lean 4 syntax
P2: Import statements are preserved (even if some imports become unused)
P3: Order of preserved items is maintained (declaration order matters in Lean)
P4: Comments adjacent to preserved items are preserved (best-effort)
P5: Section/namespace structure is preserved

### Diagnostics (opt-in, does not affect output)
S9: When --lint-simp is passed, a dead lemma with simp-eligible shape
    (equational, iff) but no @[simp] tag produces a warning.

## META-TESTING ARCHITECTURE (Bocher, applying the property-mutation closure)

M1: Every S-property needs a mutation that makes the tool WRONGLY REMOVE a live
    item. One seeded mutation per liveness channel: instance-only use, simp-only
    use, macro-only use, have-clause use, elaboration-level-only use, replay-only
    use (GoalAlias pattern).
M2: Every C-property needs a seeded-dead mutation: plant provably-dead items in
    live-looking positions (dead lemma named like a live one, dead item between
    two live ones in a section).
M3: The I-properties need a FIXPOINT mutation: a file where removal CREATES new
    deadness (A live-only-via-B, B dead). Verifies tool computes reachability
    on the original graph. (Resolved: one-pass on original graph.)
M4: Performance property E12 should be a measured budget (N declarations, depth D,
    time < f(N,D)) or it will never fail and thus never be meta-tested.

## ANCHORING FIXTURES (ChatGPT — the two tests that force spec clarity)

1. GoalAlias: Forces the tool to explain why something may survive despite
   being absent from the mathematical witness (replay dependency).
2. abandoned:False:=sorry + target:True:=trivial: Forces the tool to explain
   why a warning may disappear while the target's trust assumptions remain
   exactly preserved (sorry disposition applies to retained decls only).

## TEST CASE MATRIX

Each property × test pattern = one test case.
Each test case has: input file, expected dead set, expected live set, acceptance.
Each test case has a META-TEST: mutate the expected output and verify the test catches it.

## COVERAGE TARGETS

- Property coverage: 100% (every property has ≥1 test)
- Pattern coverage: 100% (every structural pattern exercised)
- Meta-test coverage: 100% (every test demonstrates it can fail)
- Boundary coverage: properties tested at their boundaries
- Mutation coverage: systematic mutation of tool output to verify detection

## CREDITS

- medayek: test case design, property enumeration, clean-room methodology
- Bocher (Ruach Tov Collective): S5b/S8, A1/A2, D1/D2/D3, M1-M4, G8,
  cascade-deadness spec gap, simp-set interaction analysis
- ChatGPT (external review): S10/S11/S12, S5/S5b/S5c sorry contradiction fix,
  D1 replay-dependency correction, D4 source-command ownership, V1 independent
  rebuild, E13-E18, GoalAlias and abandoned anchoring fixtures, cascade-deadness
  resolution (one-pass on original graph)
