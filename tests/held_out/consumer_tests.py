#!/usr/bin/env python3
"""held_out_tests.py — Independent consumer-perspective tests for ULE.

These tests verify the SAME properties as the unit tests but are written
independently, as if by a careful user of the public repository. They test
the PUBLIC interface (ule_core.py) without knowledge of internal implementation.

Purpose: verify that what we pull from the public repo passes not only its
own tests but also tests written from a consumer's perspective.
"""
import json, subprocess, sys, os, tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
ULE_CORE = REPO_ROOT / "src" / "ule_core.py"


def run_ule(deps, targets):
    """Run ule_core.py as a consumer would."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(deps, f)
        f.flush()
        args = [sys.executable, str(ULE_CORE), f.name, "--json"]
        for t in targets:
            args.extend(["--target", t])
        r = subprocess.run(args, capture_output=True, text=True, timeout=30,
                        cwd=str(REPO_ROOT))
        os.unlink(f.name)
    return json.loads(r.stdout) if r.returncode == 0 else None


def test_S1_transitive_deps_preserved():
    """S1: Every lemma used transitively by TARGET is preserved."""
    deps = {
        "axiom_base": [],
        "helper_1": ["axiom_base"],
        "helper_2": ["helper_1"],
        "my_theorem": ["helper_2"],
        "unrelated": ["axiom_base"],
    }
    r = run_ule(deps, ["my_theorem"])
    assert r is not None, "ULE failed to run"
    assert "unrelated" in r["dead"], "S1: unrelated should be unused"
    assert "helper_1" in r["live"], "S1: transitive dep helper_1 must be live"
    assert "helper_2" in r["live"], "S1: direct dep helper_2 must be live"
    assert "axiom_base" in r["live"], "S1: deep transitive dep must be live"
    print("  ✓ S1: transitive deps preserved")


def test_S6_target_always_preserved():
    """S6: The TARGET theorem itself is always preserved."""
    deps = {"target": [], "other": []}
    r = run_ule(deps, ["target"])
    assert "target" in r["live"], "S6: target must be in live set"
    assert "target" not in r["dead"], "S6: target must NOT be in unused set"
    print("  ✓ S6: target always preserved")


def test_C1_unreachable_removed():
    """C1: Every theorem NOT in transitive closure is removed."""
    deps = {
        "target": ["needed"],
        "needed": [],
        "island_a": ["island_b"],
        "island_b": ["island_a"],
        "orphan": [],
    }
    r = run_ule(deps, ["target"])
    for d in ["island_a", "island_b", "orphan"]:
        assert d in r["dead"], f"C1: {d} should be unused"
    print("  ✓ C1: unreachable items removed")


def test_C3_dead_chains_entirely_removed():
    """C3: Dead chains are entirely removed."""
    deps = {
        "target": ["live_helper"],
        "live_helper": [],
        "dead_root": ["dead_mid"],
        "dead_mid": ["dead_leaf"],
        "dead_leaf": [],
    }
    r = run_ule(deps, ["target"])
    for d in ["dead_root", "dead_mid", "dead_leaf"]:
        assert d in r["dead"], f"C3: {d} in dead chain should be unused"
    print("  ✓ C3: dead chains entirely removed")


def test_C4_using_live_not_being_live():
    """C4: Items that depend on live items but aren't depended on are unused."""
    deps = {
        "target": ["shared"],
        "shared": [],
        "parasitic": ["shared"],  # uses shared but target doesn't use parasitic
    }
    r = run_ule(deps, ["target"])
    assert "parasitic" in r["dead"], "C4: parasitic (uses live but unused by target) should be unused"
    assert "shared" in r["live"], "C4: shared (used by target) should be live"
    print("  ✓ C4: using live ≠ being live")


def test_I1_idempotence():
    """I1: Running twice produces same output."""
    deps = {
        "target": ["a"],
        "a": ["b"],
        "b": [],
        "dead": [],
    }
    r1 = run_ule(deps, ["target"])
    # Simulate second run: input is the same deps (idempotent)
    r2 = run_ule(deps, ["target"])
    assert r1["dead"] == r2["dead"], "I1: unused set must be identical across runs"
    assert r1["live"] == r2["live"], "I1: live set must be identical across runs"
    print("  ✓ I1: idempotent")


def test_E3_all_unused_except_target():
    """E3: When only TARGET exists meaningfully, everything else is unused."""
    deps = {
        "target": [],
        "a": [],
        "b": ["a"],
        "c": ["b"],
    }
    r = run_ule(deps, ["target"])
    assert r["dead_count"] == 3, f"E3: expected 3 unused, got {r['dead_count']}"
    assert r["reachable_from_target"] == 1, "E3: only target should be live"
    print("  ✓ E3: all unused except target")


def test_E4_nothing_unused():
    """E4: When everything is reachable, nothing is unused."""
    deps = {
        "target": ["a", "b"],
        "a": ["c"],
        "b": ["c"],
        "c": [],
    }
    r = run_ule(deps, ["target"])
    assert r["dead_count"] == 0, f"E4: expected 0 unused, got {r['dead_count']}"
    print("  ✓ E4: nothing unused when all reachable")


def test_E5_mutual_recursion_dead():
    """E5: Mutually recursive unused items are both removed."""
    deps = {
        "target": ["helper"],
        "helper": [],
        "cycle_a": ["cycle_b"],
        "cycle_b": ["cycle_a"],
    }
    r = run_ule(deps, ["target"])
    assert "cycle_a" in r["dead"], "E5: cycle_a should be unused"
    assert "cycle_b" in r["dead"], "E5: cycle_b should be unused"
    print("  ✓ E5: mutual recursion unused items removed")


def test_E10_multiple_targets():
    """E10: Multiple targets — union of their deps is live."""
    deps = {
        "target_1": ["helper_1"],
        "target_2": ["helper_2"],
        "helper_1": [],
        "helper_2": [],
        "dead": [],
    }
    r = run_ule(deps, ["target_1", "target_2"])
    assert "helper_1" in r["live"], "E10: helper_1 (dep of target_1) must be live"
    assert "helper_2" in r["live"], "E10: helper_2 (dep of target_2) must be live"
    assert "dead" in r["dead"], "E10: dead should be unused"
    print("  ✓ E10: multiple targets union")


def test_elimination_percentage():
    """Verify elimination percentage calculation."""
    deps = {
        "target": ["a"],
        "a": [],
        "b": [],
        "c": [],
        "d": [],
    }
    r = run_ule(deps, ["target"])
    assert r["elimination_pct"] == 60.0, f"Expected 60.0%, got {r['elimination_pct']}%"
    print("  ✓ Elimination percentage correct")


def main():
    print("=== HELD-OUT CONSUMER TESTS ===\n")
    tests = [
        test_S1_transitive_deps_preserved,
        test_S6_target_always_preserved,
        test_C1_unreachable_removed,
        test_C3_dead_chains_entirely_removed,
        test_C4_using_live_not_being_live,
        test_I1_idempotence,
        test_E3_all_unused_except_target,
        test_E4_nothing_unused,
        test_E5_mutual_recursion_dead,
        test_E10_multiple_targets,
        test_elimination_percentage,
    ]

    passed = failed = 0
    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"  ✗ {test.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"  ✗ {test.__name__}: EXCEPTION: {e}")
            failed += 1

    print(f"\n  {passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
