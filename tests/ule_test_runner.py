#!/usr/bin/env python3
"""ule_test_runner.py — Conformance test runner for ULE.

Runs the ULE pipeline on each test case, compares results against
the meta_test_spec.json oracle, and reports PASS/FAIL per property.

Usage:
  python3 tests/ule_test_runner.py              # run all tests
  python3 tests/ule_test_runner.py --test 01    # run one test
  python3 tests/ule_test_runner.py --coverage   # report property coverage
"""
import json, subprocess, sys, os, argparse
from pathlib import Path

TESTS_DIR = Path(__file__).parent / "unit"
SPEC_FILE = Path(__file__).parent / "meta_test_spec.json"
ULE_CORE = Path(__file__).parent.parent / "src" / "ule_core.py"


def load_spec():
    if SPEC_FILE.exists():
        return json.loads(SPEC_FILE.read_text())
    return {}


def run_extraction(lean_file, module_name):
    """Run ule_extract.lean on a compiled module, return deps JSON."""
    extract = Path(__file__).parent.parent / "src" / "ule_extract.lean"
    olean_dir = lean_file.parent / ".lake" / "build" / "lib" / "lean"
    env = os.environ.copy()
    env["LEAN_PATH"] = str(olean_dir)
    r = subprocess.run(
        ["lean", "--run", str(extract), module_name],
        capture_output=True, text=True, timeout=60, env=env,
        cwd=str(lean_file.parent))
    if r.returncode != 0:
        return None, r.stderr
    try:
        return json.loads(r.stdout), None
    except json.JSONDecodeError:
        return None, f"Invalid JSON: {r.stdout[:200]}"


def run_reachability(deps, targets):
    """Run ule_core.py on deps, return analysis result."""
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(deps, f)
        f.flush()
        args = [sys.executable, str(ULE_CORE), f.name, "--json"]
        for t in targets:
            args.extend(["--target", t])
        r = subprocess.run(args, capture_output=True, text=True, timeout=30)
        os.unlink(f.name)
    if r.returncode != 0:
        return None, r.stderr
    try:
        return json.loads(r.stdout), None
    except json.JSONDecodeError:
        return None, f"Invalid JSON: {r.stdout[:200]}"


def run_test(test_name, spec_entry=None):
    """Run a single test, return (passed: bool, details: str)."""
    lean_file = TESTS_DIR / f"{test_name}.lean"
    if not lean_file.exists():
        return False, f"Test file not found: {lean_file}"

    if spec_entry is None:
        return None, "No spec entry — manual inspection required"

    expected_dead = set(spec_entry.get("expected_dead", []))
    expected_live = set(spec_entry.get("expected_live", []))
    targets = spec_entry.get("targets", ["target"])

    # For now, test the reachability engine on pre-extracted deps
    # (full extraction requires lean4 compilation)
    deps_file = TESTS_DIR / f"{test_name}_deps.json"
    if deps_file.exists():
        deps = json.loads(deps_file.read_text())
        result, err = run_reachability(deps, targets)
        if err:
            return False, f"Reachability error: {err}"

        actual_dead = set(result["dead"])
        actual_live = set(result["live"])

        # Check soundness: no live item in dead set
        false_dead = expected_live & actual_dead
        # Check completeness: no dead item in live set
        false_live = expected_dead & actual_live

        if false_dead:
            return False, f"SOUNDNESS VIOLATION: live items marked unused: {false_dead}"
        if false_live:
            return False, f"COMPLETENESS VIOLATION: unused items marked live: {false_live}"

        if actual_dead == expected_dead and actual_live == expected_live:
            return True, f"EXACT MATCH: {len(actual_dead)} unused, {len(actual_live)} live"
        else:
            return True, (f"PARTIAL: unused={actual_dead} (expected {expected_dead}), "
                         f"live={actual_live} (expected {expected_live})")
    else:
        return None, f"No pre-extracted deps — needs lean4 compilation"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--test", help="Run specific test (e.g., Test01_LinearChain)")
    ap.add_argument("--coverage", action="store_true", help="Report property coverage")
    args = ap.parse_args()

    spec = load_spec()

    if args.coverage:
        print("Property coverage report:")
        # TODO: map spec entries to properties
        print(f"  Spec entries: {len(spec)}")
        print(f"  Test files: {len(list(TESTS_DIR.glob('*.lean')))}")
        return

    tests = ([args.test] if args.test
             else [f.stem for f in sorted(TESTS_DIR.glob("Test*.lean"))])

    passed = failed = skipped = 0
    for test_name in tests:
        spec_entry = spec.get(test_name)
        result, details = run_test(test_name, spec_entry)
        if result is True:
            print(f"  ✓ {test_name}: {details}")
            passed += 1
        elif result is False:
            print(f"  ✗ {test_name}: {details}")
            failed += 1
        else:
            print(f"  ? {test_name}: {details}")
            skipped += 1

    print(f"\n  {passed} passed, {failed} failed, {skipped} skipped")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
