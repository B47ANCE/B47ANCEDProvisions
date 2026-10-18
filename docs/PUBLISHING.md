# Workshop MP test distribution

Project Version: 0.8.0-dev.5

The user authorized the new subject-only mod icon, unchanged thumbnails, merging
all open project PRs and publication after checks. PRs 1–4 are merged. This is an
MP testing upload to existing Workshop item `3788591331`, App ID `108600`, Mod ID
`B47ANCEDProvisions`; it is not a stable-release approval. G7 remains BLOCKED /
NOT TESTED and stable G8 remains BLOCKED. No local deployment or game/server launch.

Canonical source remains `Contents/mods/B47ANCEDProvisions`, root `VERSION`,
`WORKSHOP_DESCRIPTION.txt` (Steam BBCode), `WORKSHOP_CHANGE_NOTE.txt` and the
`workshop.txt` description mirror. Existing authoring formats are preserved.
Only the newest selected changenote entry is sent, with real paragraph breaks.
Description/changenote carry the exact MP testing notice. No automated GitHub CI
uploads, new Workshop item, visibility change or Steam desktop restart is included.

The original repository had no current packager/uploader. `scripts/workshop_package.py`
now creates an immutable package from committed Git blobs, staged payload and
source/package SHA-256 provenance. Existing dist archives/backups are untouched.
`Publish-Workshop.ps1` checks fresh public-source ancestry, clean versioned source,
artifact versions and exact stage/ZIP/source/VDF parity, then invokes the supplied
verified SteamCMD with cached login. No password/token/Steam Guard input is stored.
Local tool paths and cached account selection stay outside Git.

## Commands

Use the existing development Python dependencies (Lupa Lua 5.1, Pillow and Jawa).

```powershell
python scripts/check_versions.py --root .
python scripts/run_checks.py
python scripts/check_branding.py
python -m unittest discover -s tests -p test_workshop_package.py
python scripts/check_sweet_preserves.py --game-root '<installed game root>' --steam-build 25485521
python scripts/check_preservation_expansion.py --game-root '<installed game root>' --steam-build 25485521
python scripts/check_apple_drying_evidence.py --game-root '<installed game root>' --steam-build 25485521
python scripts/check_native_drying_hooks.py --game-root '<installed game root>' --steam-build 25485521
python scripts/check_fruit_drying_evidence.py --game-root '<installed game root>' --steam-build 25485521
python scripts/check_fruit_drying_evidence.py --preview --game-root '<installed game root>' --steam-build 25485521

# After source is committed and merged; refuse to replace an existing output directory.
python scripts/workshop_package.py --build dist/current
python scripts/workshop_package.py --verify dist/current
python scripts/check_versions.py --root . --release
```

For pre-merge package verification use a new ignored `dist/validation/<commit>/`
directory. Rebuild from the exact merged main commit into a new `dist/current` for
publication; a merge commit has different provenance even when its source tree is
unchanged. The ZIP filename contains the canonical version. `SOURCE.json` inside
the package binds version, source commit and per-file hashes; the external
`release-provenance.json` additionally binds the final package SHA-256, target game
build, IDs and actual validation status. No secret, logs, authoring sources or tests
are placed inside the runtime `Contents` tree.

The uploader VDF sends only App ID, existing item ID, content, title, description
and selected changenote. It deliberately omits `previewfile` and `visibility` so
the existing Workshop thumbnail and visibility remain unchanged. Both committed
project thumbnail PNGs are also checked against their original SHA-256; the new
64×64 transparent icon is separate. Steam documents these optional-update semantics
in the [SteamCMD integration guide](https://partner.steamgames.com/doc/features/workshop/implementation).

## Actual validation boundaries

`docs/RELEASE_STATUS.json` records offline/SP/dedicated scope. Native callback
limitation checks remain negative evidence for the unused callback route, not a
claim that the alternative server action is blocked. All applicable source, API,
version, authority, secrets/case/localization and package-integrity checks must pass
before upload. No static success proves in-game dispatch, Linux behavior or MP.

At preparation, the public Steam details API returns result 9 for this known
existing item. Public page/description/thumbnail verification is therefore unavailable;
the target identity remains the existing project-owned ID, never a new item.
Cached authentication must prove it can update that item, and SteamCMD must report
successful upload/commit. Record upload outcome separately from runtime evidence.

Historical packages/provenance are retained for recovery; no automatic rollback is
performed. New jam/jelly item types and non-Apple drying jobs have no downgrade
migration. Subscription download/install, startup, join/rejoin, heat interruption,
synchronization, duplicate completion, food/container use, persistence and restart
tests remain required on disposable SP and dedicated saves. Steam desktop restart
requires a fresh affirmative reply after confirmed upload success; it is separate
from publication and never proves subscribed content synchronization.
