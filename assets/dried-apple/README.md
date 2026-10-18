# Dried apple inventory art

Original generated art for B47ANCE’d Provisions: three curled dried apple slices,
muted red peel and golden flesh. Created with OpenAI's built-in image generator
on 2026-10-17; no third-party image or vanilla artwork was used as input or copied.
The full generation prompt and SHA-256 provenance are retained beside the files.
No third-party reuse license is asserted by this record.

- `dried-apple-master.png`: retained, editable raster master with true alpha.
- `Item_B47ANCEDProvisions_DriedAppleSlices.png`: 64×64 RGBA inventory export.
- `export.ps1`: repeatable Windows/System.Drawing size export, preserving alpha.
- `prompt.txt`: generation specification; not a guarantee of identical regeneration.
- `provenance.json`: dimensions, alpha coverage and hashes from offline inspection.

Run `powershell -NoProfile -File assets/dried-apple/export.ps1` from the repository
to export again. The master has no layer structure; paint edits should retain a
new source revision. The export is an authoring artifact, outside the authoritative
runtime tree. No atlas coordinates or animation frames are required for this
single loose icon; its pivot is centered in the square canvas.

[VERIFIED source] Installed Build 42.21 / Steam build 25485521 uses `Icon = Apple`
and `Icon = DriedApricots` in `media/scripts/generated/items/food.txt`. In
`media/lua/client/ISUI/ISInventoryPane.lua:2300`, inventory rendering reads
`item:getTex()` and fits the icon in a box capped at 32 pixels. A 64-pixel export
is this asset's authoring target, not a claim that all vanilla icons share that
size. The installed `media/texturepacks/UI2.pack` was inspected read-only; the two
item names were not found as plain text, so atlas bounds were not inferred.

[TESTED offline, Windows] PNG dimensions, nonempty real alpha, transparent edges,
small-size visual readability, and source/export hashes were checked. The art
uses an isolated silhouette with no text, packaging or baked checkerboard.

Runtime hookup is pending: the current process keeps the same `Base.Apple` object
and vanilla texture. Applying this icon must preserve that identity, persistence
and multiplayer authority, and must first verify a per-item visual route. Never
replace the global Apple texture to apply this asset. No new item, recipe, model
or gameplay setter is introduced here. [RUNTIME GATE] Native SP/dedicated display,
join/rejoin and save/reload are NOT TESTED; G7 and stable G8 remain BLOCKED.

This is an asset-only follow-up within `0.8.0-dev.2`, with no compatibility change
and no separate version checkpoint. No packaging, deployment or publication.
