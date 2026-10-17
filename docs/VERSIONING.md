# Project versioning

Current development version: 0.8.0-dev.2.

The current 0.8.0-dev.2 checkpoint is a compatible gameplay addition within the
0.8.0 MINOR line: server-owned in-place apple drying, three sandbox controls and
new independently versioned v1 job/index keys. Existing Lua/API/sandbox/save
identifiers remain intact. The same Apple becomes the saved dried result; no new
food type or native recipe replaces the prior design candidate. Native SP and
dedicated evidence remain NOT TESTED; no stable release is approved.

Historical baseline: the October 17 design/API audit remains bound to its historical 0.7.0 baseline.
The user then requested the read-only prototype: a compatible new inspection
capability classified MINOR at 0.8.0-dev.1. Its preview evidence remains historical,
not a current version mirror or new gameplay proof. Production drying and 0.8.0 distribution remain subject to the documented
gates. This checkpoint adds presentation only, with no shared state, new gameplay
settings, persistence schema change or active recipe. The original identity/audit
records retain their actual versions instead of being relabeled as current proof.

Root `VERSION` is the sole authority. `version-inventory.json` declares exact
current mirrors; it is not another authority. See [VERSION_POLICY.md](VERSION_POLICY.md).

## Approved legacy migration

On October 16, 2026, the user approved a local rename from foodWorks and explicit
adoption of 0.7.0. The previous README, mod.info, info.txt, Lua constant, roadmap
and current Workshop text agreed on 0.6.0; no canonical VERSION, version checker,
changelog, Git metadata or remote existed. No former canonical version is invented.

This is a 0.y.z MINOR identity checkpoint: changing Mod ID requires an explicit
launcher/server enable-list change. It adds no gameplay feature. Public Lua/API,
sandbox and persistence identifiers stay compatible; native save compatibility
is unproven. The expected next distribution is 0.7.0, subject to required gates;
this is not stable-release approval.

## Source and artifacts

- Authoritative source: `Contents/mods/B47ANCEDProvisions`; no parallel source tree.
- Tests: `tests/`; read-only validation entry points: `scripts/`.
- Current Workshop authoring: root description, changenote, workshop.txt and artwork.
- Existing Workshop item: `3788591331`; public source repository:
  [B47ANCE/B47ANCEDProvisions](https://github.com/B47ANCE/B47ANCEDProvisions).
- Historical output: existing `dist/` archives and staging-backups, SHA256SUMS.txt,
  and .steamcmd-last-upload.sha256. Preserve exact bytes and original names.
- Future current packages: `dist/current/B47ANCEDProvisions-<VERSION>-workshop-ready.zip`,
  with root VERSION and the declared mod.info member. This is a declared contract,
  not an existing generator or authorization to package. No build/uploader script
  exists within this project; a future packaging workflow must read VERSION.

## Commands

`python scripts/check_versions.py --root .` checks current declared mirrors.
`python scripts/run_checks.py` requires `lupa.lua51` and runs offline checks.
`python scripts/check_versions.py --root . --release` also requires current artifacts
and must fail while no current package exists. It never establishes runtime proof.

The configured framework junction is broken on this machine. The existing team
policy and dependency-free checker were copied unchanged from local
`B47ANCEDPower/docs/VERSION_POLICY.md` and `B47ANCEDPower/scripts/check_versions.py`;
that project was not modified. No new framework installation or update was attempted.

The initial local rename had no Git repository and was NOT BACKED UP. The user
subsequently authorized public repository onboarding and commit/push of this same
0.7.0 iteration. The authenticated owner and public visibility were verified as
`B47ANCE`; source work uses `chore/provisions-0.7.0-rename` and a PR against `main`.
The bootstrap main commit contains only the reviewed ignore rules. Verify the
feature branch's local SHA against `git ls-remote origin` after each push.
No stable tag, main merge, branch-protection change or Workshop upload is authorized
by this onboarding. G7 and stable G8 remain BLOCKED; a SemVer without a prerelease
suffix does not imply runtime readiness. No CI workflow is configured yet; current
validation is offline and peer review remains pending.
