/-
  ule_extract.lean — SOUND dependency extraction for Unused-Lemma Elimination.

  Reads the dependency graph from Lean's COMPILED Environment (the ground truth),
  NOT a text parser. For each declaration DEFINED IN THE TARGET MODULE, walks its
  value Expr and type Expr collecting referenced constants (Expr.getUsedConstants).
  This captures implicit deps a text parser would MISS: typeclass instances,
  auto-bound implicits, deps from elaboration/macro expansion — because we read
  what the kernel actually recorded, not the surface syntax.

  Soundness by construction: getUsedConstants gives exactly the constants the
  elaborated term references. If TARGET uses an instance implicitly, that
  instance's name IS in the elaborated Expr -> captured -> LIVE.

  MODULE SCOPING: we extract only decls defined IN the target module (via
  getModuleIdxFor? == the target module's index), so the graph is the user's
  own declarations, not the thousands of imported Lean/Std builtins. Deps that
  point OUT of the module (to builtins) are kept as edges (so reachability is
  correct) but builtins are not themselves nodes to eliminate.

  Output: JSON {decl: [deps...]} restricted to module-local decls, with edges to
  module-local deps only (the self-contained user graph). Consumed by ule_core.py.

  Usage: LEAN_PATH=<dir> lean --run ule_extract.lean <ModuleName>
-/
import Lean
open Lean

def exprDeps (e : Expr) : NameSet :=
  e.getUsedConstants.foldl (·.insert ·) {}

def nameToJson (n : Name) : String := "\"" ++ toString n ++ "\""

def main (args : List String) : IO Unit := do
  let modName := (args.head?.getD "Main").toName
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := modName }] {} (trustLevel := 1024)
  -- find the module index for the TARGET module (the one we care about)
  let some targetIdx := env.getModuleIdx? modName
    | IO.eprintln s!"module {modName} not found in env"; return
  -- the set of decls DEFINED in the target module (user's own declarations)
  let mut localDecls : NameSet := {}
  for (n, _) in env.constants.toList do
    if n.isInternal then continue
    if env.getModuleIdxFor? n == some targetIdx then
      localDecls := localDecls.insert n
  -- extract deps for each local decl; keep only edges to OTHER local decls
  -- (builtins are external; we don't eliminate them, and reachability through
  --  them is irrelevant since they're always present)
  let mut parts := #[]
  for (n, ci) in env.constants.toList do
    if !localDecls.contains n then continue
    let mut deps : NameSet := exprDeps ci.type
    -- CRITICAL: ci.value? returns `none` for THEOREMS (proofs are opaque by
    -- default for performance). We must read the proof term from the variant
    -- directly, or we silently MISS every theorem's proof deps -> under-approx
    -- -> drop live lemmas -> BREAK the proof. Soundness depends on this.
    let valExpr? : Option Expr := match ci with
      | .thmInfo tv  => some tv.value
      | .defnInfo dv => some dv.value
      | .opaqueInfo ov => some ov.value
      | _ => ci.value?   -- fallback (covers any other value-bearing kinds)
    if let some v := valExpr? then
      for d in (exprDeps v) do deps := deps.insert d
    let localEdges := deps.toList.filter (fun d => d != n && localDecls.contains d)
    let dsJson := String.intercalate ", " (localEdges.map nameToJson)
    parts := parts.push (nameToJson n ++ ": [" ++ dsJson ++ "]")
  IO.println ("{" ++ String.intercalate ",\n " parts.toList ++ "}")
