# B47ANCE’d Provisions identity migration

Project Version: 0.7.0

User-authorized local rename on October 16, 2026:

| Surface | Before | After |
| --- | --- | --- |
| Display name | foodWorks | B47ANCE’d Provisions |
| Project and mod folders | foodWorks | B47ANCEDProvisions |
| Mod ID | foodWorks | B47ANCEDProvisions |
| Project version | 0.6.0 metadata baseline | 0.7.0, canonical VERSION |
| Workshop item | 3788591331 | 3788591331 |

## Compatibility boundary

The Lua global `foodWorks`, `require "foodWorks/..."` module paths, registered
provider identifiers, sandbox option `foodWorks.EnableFoodInspection`, translation
keys, and `foodWorks.applianceTransaction.v1` / `foodWorks.applianceOperations.v1`
save keys remain unchanged. Only the API version constant changes in Lua.
The sandbox page's display value uses the new branding. No gameplay, networking,
configuration defaults, persistence behavior, item mutation, or authority changes.

Deployment must replace the old enabled Mod ID with `B47ANCEDProvisions`, including
dedicated server/launcher configuration where applicable. Do not load both copies:
they share API keys and event registration. No live installation or server files
were changed. There is no automatic save migration or native compatibility claim.

## Evidence and open gates

- [VERIFIED] Local source and metadata inventory; old Mod ID folder removed by
  bounded rename; Workshop item and all artwork preserved.
- [TESTED: offline Lua 5.1] All five existing suites passed before edits at 0.6.0.
- [TESTED: offline Lua 5.1] Repeatable post-rename suites, real production loaders,
  Lua syntax, exact module-path case, identity and legacy key checks are available
  through `scripts/run_checks.py`; final results are recorded in TESTING.md.
- [VERIFIED] Subsequent user-authorized onboarding created public repository
  [B47ANCE/B47ANCEDProvisions](https://github.com/B47ANCE/B47ANCEDProvisions).
  Rename branch: `chore/provisions-0.7.0-rename`, targeting `main` through a PR.
  The original local-only rename had no Git backup; it is not retroactively
  treated as a historical Git commit. See TESTING.md for onboarding checks.
- [RUNTIME GATE] SP identity discovery, sandbox page rendering, previous-save load,
  inspection menu, native enable-list transition and duplicate-copy prevention.
- [RUNTIME GATE] Dedicated startup, join/rejoin, late join, save/reload and restart.
  G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED. No current package exists.

Historical archives, staging backups, old checksum/upload records, artwork and
research remain unchanged. Prior evidence never becomes current runtime proof.
Workshop descriptions and changenotes are authoring files only: no upload occurred.
