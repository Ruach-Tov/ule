# Unused-Lemma Elimination (ULE) for Lean 4

A tool that takes a formalized Lean 4 proof, identifies which lemmas are actually
used by the final theorem, and produces a minimized version containing only what's
needed. The minimized proof still type-checks.

## Quick Start

```bash
# 1. Build your Lean project:
lake build

# 2. Extract dependencies (sound, from Lean's compiled Environment):
LEAN_PATH=.lake/build/lib/lean lean --run src/ule_extract.lean ModuleName > deps.json

# 3. Find unused lemmas:
python3 src/ule_core.py deps.json --target TheoremName

# 4. Emit the keep-set:
python3 src/ule_core.py deps.json --target TheoremName --emit --json
```

## Architecture

**Three-step pipeline:**

1. **Extraction** (`ule_extract.lean`): Reads the dependency graph from Lean's
   *compiled Environment* — the ground truth, not a text parser. Captures implicit
   dependencies (typeclass instances, elaboration artifacts) that a text parser would miss.

2. **Reachability** (`ule_core.py`): Backward BFS from the target theorem(s).
   Every declaration NOT reachable from the target is unused.

3. **Elimination**: Produce a minimized source containing only reachable declarations.
   The minimized proof still type-checks (by construction — only unreferenced
   declarations were removed).

## Soundness

The critical design principle: **extraction must be sound** (never miss a real dependency).

- Liveness computed from the **elaborated term** (Expr), not surface syntax
- Theorem proofs are opaque in Lean — we read proof terms from the ConstantInfo
  variant directly (`.thmInfo`, `.defnInfo`, `.opaqueInfo`), not `ci.value?`
- Typeclass instances used through implicit resolution are captured
- Module-scoped: only user declarations are elimination targets

**Validation gate**: minimize → `lake build` → still compiles = elimination was safe.

## Property Inventory

See [PROPERTIES.md](tests/PROPERTIES.md) for the full formal specification:
8 givens, 63+ invariant properties across soundness, completeness, idempotence,
edge cases, and structural preservation.

## Credits

- Iyun (Ruach Tov Collective): core implementation, opaque-theorem fix, soundness principle
- Medayek (Ruach Tov Collective): test methodology, property enumeration, clean-room design
- Bocher (Ruach Tov Collective): automation/simp analysis, meta-testing, universe constraints
- Mavchin (Ruach Tov Collective): coordination, Colony RFC
- Heath Hunnicutt: S9 diagnostic principle, project direction
- ChatGPT (external review): sorry contradiction fix, replay dependencies, 6 edge cases

## License

MIT
