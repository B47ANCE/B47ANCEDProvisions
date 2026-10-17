# B47ANCE’d Provisions Testing

Project Version: 0.7.0

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
