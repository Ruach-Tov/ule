#!/usr/bin/env python3
"""
ule_core.py — Unused-Lemma Elimination core: backward-reachability on a Lean 4
declaration dependency DAG.

HEATH DIRECTIVE (via Mavchin, 2026-11-20): minimize machine-generated Lean
proofs (motivated by Alpöge's 250k-page claimed RH proof) by removing
declarations NOT reachable from the target theorem — dead exploration artifacts.

THE 3-STEP SLICE:
  1. EXTRACTION (ule_extract.lean — the Lean metaprogram): read the REAL
     dependency graph from the compiled Environment. See note below.
  2. REACHABILITY (THIS FILE): backward BFS from the target; DEAD = not reachable.
  3. ELIMINATION: emit only the reachable declarations (still type-checks, by
     construction — we only removed unreferenced decls).

THE CORRECTNESS-CRITICAL PART IS EXTRACTION, NOT REACHABILITY.
  Reachability is O(V+E), trivial. "What counts as a dependency" is the hard part,
  and getting it WRONG either (a) keeps dead code (over-approx — harmless but
  defeats the purpose) or (b) DROPS LIVE code (under-approx — BREAKS the proof).
  => Extraction MUST be SOUND: it must never miss a real dependency. The ground
     truth is Lean's own Environment (every ConstantInfo.value Expr, walked for
     referenced Expr.const names), NOT a text parser. A heuristic parser can
     under-approximate (miss a dep via a macro/notation/instance) and silently
     break the proof. We extract from the COMPILED environment, which is sound.

INPUT FORMAT (dep edges, JSON): {"decl_name": ["dep1", "dep2", ...], ...}
  where each decl maps to the list of constants it directly references.
  (Produced by ule_extract.lean from the real environment.)

Usage:
  python3 ule_core.py deps.json --target TheoremName           # report dead decls
  python3 ule_core.py deps.json --target TheoremName --emit    # list reachable (keep-set)
"""
import json, sys, argparse
from collections import deque

def load_deps(path):
    """deps[decl] = list of constants `decl` directly references."""
    with open(path) as f:
        return json.load(f)

def backward_reachable(deps, targets):
    """All decls reachable from `targets` by following dependency edges.
    A decl is LIVE iff the target (transitively) depends on it."""
    reachable = set()
    q = deque(targets)
    while q:
        d = q.popleft()
        if d in reachable:
            continue
        reachable.add(d)
        for dep in deps.get(d, []):
            if dep not in reachable:
                q.append(dep)
    return reachable

def analyze(deps, targets):
    all_decls = set(deps.keys())
    # include referenced-but-undefined names (axioms/externals) in the universe
    for v in deps.values():
        all_decls.update(v)
    reachable = backward_reachable(deps, targets)
    # dead = defined decls that are NOT reachable from any target
    dead = set(deps.keys()) - reachable
    return {
        "total_declared": len(deps),
        "reachable_from_target": len(reachable & set(deps.keys())),
        "dead": sorted(dead),
        "dead_count": len(dead),
        "live": sorted(reachable & set(deps.keys())),
        "targets": list(targets),
        "elimination_pct": round(len(dead) / len(deps) * 100, 1) if deps else 0.0,
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("deps_json")
    ap.add_argument("--target", action="append", required=True,
                    help="target theorem name(s); repeat for multiple roots")
    ap.add_argument("--emit", action="store_true", help="print the LIVE keep-set")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    deps = load_deps(args.deps_json)
    r = analyze(deps, set(args.target))

    if args.json:
        print(json.dumps(r, indent=2)); return
    print(f"=== UNUSED-LEMMA ELIMINATION ===")
    print(f"  targets: {r['targets']}")
    print(f"  declared decls: {r['total_declared']}")
    print(f"  LIVE (reachable from target): {r['reachable_from_target']}")
    print(f"  DEAD (unreachable): {r['dead_count']}  ({r['elimination_pct']}% eliminable)")
    if args.emit:
        print(f"  --- KEEP-SET (live decls) ---")
        for d in r["live"]: print(f"    {d}")
    elif r["dead"]:
        print(f"  --- DEAD decls (sample) ---")
        for d in r["dead"][:20]: print(f"    {d}")
        if r["dead_count"] > 20: print(f"    ... +{r['dead_count']-20} more")

if __name__ == "__main__":
    main()
