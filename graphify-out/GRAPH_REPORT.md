# Graph Report - Server  (2026-09-04)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 21 nodes · 43 edges · 5 communities (3 shown, 1 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a50016aa`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- manage-agent-skills.py
- validate-agent-response.py
- Path
- parse_args

## God Nodes (most connected - your core abstractions)
1. `main()` - 9 edges
2. `fail()` - 7 edges
3. `validate_skill_dir()` - 6 edges
4. `activate_profile()` - 5 edges
5. `install_catalog()` - 5 edges
6. `load_manifest()` - 4 edges
7. `main()` - 4 edges
8. `check_catalog()` - 4 edges
9. `expanded()` - 3 edges
10. `validate_manifest()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `read_response()` --calls--> `Path`  [INFERRED]
  scripts/validate-agent-response.py →   _Bridges community 1 → community 2_
- `expanded()` --calls--> `Path`  [EXTRACTED]
  scripts/manage-agent-skills.py →   _Bridges community 0 → community 2_
- `main()` --calls--> `parse_args()`  [EXTRACTED]
  scripts/manage-agent-skills.py → scripts/manage-agent-skills.py  _Bridges community 0 → community 3_

## Import Cycles
- None detected.

## Communities (5 total, 1 thin omitted)

### Community 0 - "manage-agent-skills.py"
Cohesion: 0.73
Nodes (5): expanded(), fail(), load_manifest(), main(), validate_manifest()

### Community 1 - "validate-agent-response.py"
Cohesion: 0.53
Nodes (5): main(), parse_args(), Namespace, read_response(), validate()

### Community 2 - "Path"
Cohesion: 0.70
Nodes (5): Path, activate_profile(), check_catalog(), install_catalog(), validate_skill_dir()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `read_response()` connect `validate-agent-response.py` to `Path`?**
  _High betweenness centrality (0.342) - this node is a cross-community bridge._
- **Why does `main()` connect `manage-agent-skills.py` to `Path`, `parse_args`?**
  _High betweenness centrality (0.113) - this node is a cross-community bridge._