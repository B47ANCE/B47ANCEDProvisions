# B47ANCE’d Provisions Testing

Project Version: 0.8.0-dev.1

## Native-hook follow-up — October 17, 2026

Audit baseline: merged `77771cbf27c0b0ea1b5812c23798c53e8f37b1a3` / 0.8.0-dev.1.
Documentation and offline tooling only; no new version iteration or gameplay.
See [decision](FRUIT_DRYING_NATIVE_HOOKS.md) and [evidence](FRUIT_DRYING_HOOK_EVIDENCE.json).

Additional exact command (Python with isolated development-only jawa 2.2.0):

```powershell
python scripts/check_native_drying_hooks.py --game-root 'E:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid' --steam-build 25485521
```

- [TESTED: offline static] Seven packaged class fingerprints match; loose classes
  match where present. Expected native callback/output/destruction call order,
  per-item OnTest path, inert recipe test, native job ModData serialization and
  absence of a declared setTime match. This confirms limitations, not gameplay.
- [TESTED: offline Lua 5.1] The six existing suites and load/syntax checks PASS;
  no production runtime file changes. Version consistency remains PASS at 0.8.0-dev.1.
- [TESTED: offline] The 18 design and 12 preview fingerprints still match. The
  fresh Windows checkout converts the project preview text to CRLF; its checker
  accepts an LF-normalized match to the original recorded hash. Installed game
  files/classes remain byte-exact. A content edit still fails the project hash.
- [RUNTIME GATE] Live Lua hooks, duration binding, pre-output validation/food aging,
  resource synchronization, cancellation, save/restart and dedicated contention
  remain NOT TESTED or unresolved. Production blocked; G7/stable G8 BLOCKED.

No native game/server execution, package, deployment or publication.

## Read-only preview checkpoint — October 17, 2026

Version 0.8.0-dev.1 adds a client-only inspection capability. Gameplay and all
production drying gates remain unchanged. This section records current checks;
the original 0.7.0 design/rename results below retain their original scope.

Executed with bundled Python 3.12 and isolated Lupa 2.8 / Lua 5.1 tooling:

```powershell
$provisionsPython = 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
# Use the developer-local isolated Lupa directory on PYTHONPATH, as in the prior audit.
& $provisionsPython scripts/check_versions.py --root .
& $provisionsPython scripts/run_checks.py
& $provisionsPython scripts/check_fruit_drying_evidence.py --game-root 'E:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid' --steam-build 25485521
& $provisionsPython scripts/check_fruit_drying_evidence.py --preview --game-root 'E:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid' --steam-build 25485521
git diff --check
```

- [TESTED: offline Lua 5.1] Six suites PASS: the five existing suites plus the
  conservative preview, menu, localization, bounded scan, stale activation,
  client/server loading and speed-safe window regression suite. Real production
  load graph, syntax and retained-key checks PASS.
- [TESTED: offline] Canonical/current version consistency PASS; historical identity
  and API audits remain at 0.7.0. Old 18 evidence fingerprints still match;
  preview-specific source/native/module fingerprints match separately.
- [VERIFIED: source] The new module has only getter/UI/event calls. It exits on a
  server, uses no inventory/gameplay mutators, does not read/allocate getModData,
  and contains no job/recipe/network operations. Existing shared gameplay modules
  are unchanged except the canonical API version constant.
- [TESTED: offline] EN UI keys and sandbox toggle names/tooltips are present;
  unknown/throwing getters are not treated as clean flags. No other locale is
  claimed translated; vanilla EN fallback requires native confirmation.
- [RUNTIME GATE] SP/dedicated UI appearance, actual getter dispatch, rack variants,
  split-screen, font scale, Escape/controller focus/scrolling and unchanged speed
  remain NOT TESTED. This is local presentation only; the broader project's G7
  and stable G8 remain BLOCKED / NOT TESTED for production drying.

No packaging, deployment, Workshop upload, game/server launch or new CI workflow.
See [prototype](FRUIT_DRYING_PREVIEW.md) for user flow, sandbox behavior and limits.

## Historical 0.7.0 fruit-drying design/API audit — October 17, 2026

Documentation/tooling-only checkpoint from main commit
`93400d5cd607925f132aaf591fbfd32cd3f048ec`; canonical VERSION and all runtime
files remain unchanged. A separate clean worktree on `docs/fruit-drying-api-audit`
preserves the original merged feature checkout. Startup freshness at this new
branch's baseline: PASS, origin/main identical, ahead/behind 0/0, clean.

Installed source: Build 42.21 / Steam build 25485521. See
[audit](FRUIT_DRYING_API_AUDIT.md), [design](FRUIT_DRYING_DESIGN.md) and
[fingerprints](FRUIT_DRYING_EVIDENCE.json). The evidence is static/local-source,
not a pristine-Steam certificate, Lua invocation test, SP run or dedicated run.

Commands executed using the bundled Python 3.12 interpreter below. Lupa 2.8
was installed in an isolated audit-tool directory outside this repository because
the refreshed bundle lacked it; it is a development test dependency, never a mod
runtime dependency. Put that developer-local directory on PYTHONPATH to reproduce.

```powershell
$provisionsPython = 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $provisionsPython scripts/check_versions.py --root .
& $provisionsPython scripts/run_checks.py
& $provisionsPython scripts/probe_preservation_audit.py
& $provisionsPython scripts/check_fruit_drying_evidence.py --game-root 'E:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid' --steam-build 25485521
git diff --check
```

- [TESTED: offline] Version consistency PASS at 0.7.0; no current package exists.
- [TESTED: offline Lua 5.1] Five existing suites, real production loaders, syntax,
  identity and retained-key checks PASS. No new native behavior is tested by them.
- [TESTED: offline Lua 5.1] Audit probes reproduce a function retained in a receipt,
  a 240-hour gap credited as 168 hours with last marker 240, and observations
  saturated at 64. The next-hour advance credits 1 hour; lost catch-up is not retained.
  These are recorded limitations, not requirements to preserve bugs forever.
- [TESTED: offline] All 18 local source/class fingerprints and line ranges match.
- [VERIFIED: source review] The overview separates foundation, planned and blocked
  work and binds the reviewed description to 0.7.0 plus the current source digest.
- [RUNTIME GATE] Native recipe discovery/hooks, whole-item checks, age/nutrient
  mapping, settings snapshots, cancellation, loaded/unloaded processing and
  save/restart/join behavior remain UNKNOWN / NOT TESTED. G7 BLOCKED; stable G8 BLOCKED.

No production registration/mutation, package, deployment, publication or game/server
launch. Existing API/key contracts and historical evidence are preserved. No new
CI workflow or hosted check is added. Source audit completion does not declare a
project G6 PASS. Proposed later implementation target 0.8.0-dev.1 is planning only.

## Rename validation

Run `python scripts/check_versions.py --root .` and `python scripts/run_checks.py`.
The Lua harness requires `lupa.lua51`; each suite uses an isolated Lua 5.1 VM.
These commands perform offline checks only and never launch the game.

The five pre-rename suites passed at 0.6.0 before edits. The versioned sections
below retain prior host-test descriptions, not current native-runtime proof.
See [identity migration](IDENTITY_MIGRATION.md) for rename evidence and open gates.

### Recorded results — October 16, 2026

Executed from `C:\Users\willi\Desktop\Work\Project Zomboid\Mod Repositories\B47ANCEDProvisions`
using the bundled Python (the Windows Store `python` alias is unavailable):

```powershell
$provisionsPython = 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $provisionsPython scripts/check_versions.py --root .
& $provisionsPython scripts/run_checks.py
```

- [TESTED: offline] Version checker PASS for VERSION, 11 declared current mirrors
  and current changelog. No current package exists; artifact validation deferred.
- [TESTED: offline Lua 5.1] All five existing suites PASS: API, food inspection,
  appliance transactions, preservation processes and production load graph.
- [TESTED: offline Lua 5.1] Real shared/server/client loaders and every Lua source
  compile; retained API, sandbox, translation and persistence identifiers PASS.
- [TESTED: offline] Workshop authoring text/metadata consistency and actual paragraph
  breaks PASS. No active-source case collisions or Java/JAR/class/DLL files found.
- [TESTED: offline] SHA-256 comparisons against the pre-edit snapshot preserved all
  175 historical/archive/staging, artwork, Workshop-ID and upload/checksum files.
  All seven Lua source bodies match their original text except the API version
  constant. The snapshot remains outside the project in this chat's local artifact
  directory; no archive content, historical filename or upload checksum was rewritten.
- [UNKNOWN: original local rename] The exact startup command below returned UNKNOWN,
  "not a git repository". That original local step had no commit/push or backup;
  subsequent onboarding is recorded separately below.
- [RUNTIME GATE] SP and dedicated multiplayer NOT TESTED. G7 BLOCKED and
  stable-release G8 BLOCKED. No package, deployment or Workshop upload performed.

Read-only startup command executed before edits (user subsequently authorized local work):

```powershell
& 'C:\Users\willi\.codex\b47anced-team\tools\Test-PZRepositoryFreshness.ps1' -Repository 'C:\Users\willi\Desktop\Work\Project Zomboid\Mod Repositories\foodWorks'
```

### Public GitHub onboarding

User-authorized public repository: `B47ANCE/B47ANCEDProvisions`. `gh api user --jq .login`
confirmed owner B47ANCE; `gh repo view B47ANCE/B47ANCEDProvisions --json nameWithOwner,url,visibility`
confirmed PUBLIC visibility. No pre-existing repository or Git history was replaced.
An initial ignore-rules commit establishes main; the complete rename is reviewed
through `chore/provisions-0.7.0-rename` and a PR before any main merge.

The freshness helper was rerun against the renamed absolute project path. Before
the source commit, HEAD and origin/main matched with ahead/behind 0/0; REVIEW
represented the known, inspected project files awaiting their initial source commit,
not stale ancestry. No unfinished Git operation was present. After pushing, verify
`git rev-parse HEAD` matches `git ls-remote origin refs/heads/chore/provisions-0.7.0-rename`.
Exact pushed commit and PR identity are reported by the delivery, not embedded
as a self-referencing SHA in this commit.

The public-file audit covers staged source, tests, docs, metadata and artwork.
Shared `.agents`/`.codex` junctions, local SteamCMD upload marker, staging backups,
ZIPs, caches, local settings and diagnostics are excluded. A credential-pattern
scan plus staged-diff/path review found no suspected credentials; this is an
offline audit, not a claim that a hosted secret-scanning service ran.
`git diff --cached --check`, `scripts/check_versions.py --root .` and
`scripts/run_checks.py` are required again before the source commit.
No CI workflow/checks are configured; SP/dedicated gates remain unchanged.

## Version 0.6.0 preservation process framework

Host coverage proves exact registered input reservation, stable station/food
identity, eligibility rejection, duplicate begin, bounded elapsed advancement,
cadence observations, ready state, spoilage, cancellation/release, replay-safe
completion, and uncertain-output quarantine. The test definition is a synthetic
fixture, not gameplay content. Native persistence, inventories, item aging,
output creation, interruption, unloaded time, save/reload, and multiplayer remain
open for the first approved process.

## Version 0.5.0 appliance transaction foundation

Host coverage proves exact power-then-water reservation ordering, one process
commit, water-then-power finalization, operation replay, full rollback after a
declared no-output rejection, and quarantine after an ambiguous process call.
It also verifies the production loader installs the coordinator once.

No production appliance process is registered. A first-party vertical slice
must test exact appliance and fluid identity, input/output inventory ownership,
timed-action interruption, process exception recovery, save/reload in every
transaction phase, missing/removed resources, hosted late join, and dedicated
authority before EXT-07 can be called native-complete.
