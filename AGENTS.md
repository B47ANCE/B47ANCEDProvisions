# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Read the current global rules at C:\Users\willi\.codex\AGENTS.md before work.
Team skills are installed at C:\Users\willi\.agents\skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

## Project identity

- Display name: B47ANCE’d Provisions; Mod ID: `B47ANCEDProvisions`.
- Workshop item: `3788591331`; authoritative source: `Contents/mods/B47ANCEDProvisions`.
- Canonical version: root `VERSION`; policy: `docs/VERSION_POLICY.md`;
  inventory: `version-inventory.json`; checks: `scripts/check_versions.py` and
  `scripts/run_checks.py` (offline Lua 5.1 through lupa).
- Preserve the legacy `foodWorks` Lua namespace/module paths, sandbox/translation
  identifiers and persistence keys. The identity change does not authorize
  breaking these compatibility contracts.
- `dist/` pre-rename packages/staging, checksum/upload records and original API
  research are historical. No package is current unless explicitly generated and
  validated under the current-artifact contract. No automatic deploy or publish.
- Public repository: `https://github.com/B47ANCE/B47ANCEDProvisions`.
  The user authorized repository creation and commit/push of the 0.7.0 rename.
  Use feature branches and PRs before merging main; verify each pushed SHA.
  Local shared-tool junctions, upload markers and generated archives remain ignored.
