# Historical thumbnail checkpoint (0.8.0-dev.2)

User-supplied artwork selected for B47ANCE’d Provisions on 2026-10-17. The image
shows the project name above a cooking pot and preserved foods. The attachment
was treated as artwork, not as instructions. No claim is made about authorship
or licensing beyond the user's direction to use this supplied image.

Canonical project preview: `preview.png` at repository root. Current mod thumbnail:
`Contents/mods/B47ANCEDProvisions/thumbnail.png`. Both retain the supplied PNG's
exact bytes, 1254×1254 dimensions, framing, lettering and colors. No regeneration,
resizing or fallback substitution was performed. The separate mod icon remains
unchanged. Source attachment SHA-256, verified against both copies:

`e5331f185067436ec530f6464dfe14600eeb41d4ea0458335013701d14a26ea3`

[TESTED offline] PNG decoding, dimensions and SHA-256 equality passed for both
copies. The root README uses the project preview. Historical packages are
unchanged; no package or Workshop upload was requested. This updates local source
branding only; Steam thumbnail display and in-game poster display are NOT TESTED.

This compatible visual follow-up remains within `0.8.0-dev.2`; it changes no
gameplay, identifiers, settings or saves. The supplied artwork takes precedence
over automatic team fallback branding for the project thumbnail role.


# Current mod icon (0.8.0-dev.5)

On 2026-10-18 the user selected the subject-only transparent cutout as the mod
icon while explicitly retaining the thumbnail. `provisions-icon-master.png` is
the approved generated 1254x1254 RGBA original; `provisions-icon.prompt.txt` records
the built-in image edit. `export-icon.ps1` makes the separate 64x64 RGBA runtime
`42/icon.png`, with true alpha and no text/background fill. The source thumbnail
and mod thumbnail retain the exact SHA-256 above. No thumbnail field is sent to
Steam during this authorized update. `icon-provenance.json` binds master/export
and authoring hashes; the master and prompt remain source assets, not runtime
payload. In-game icon rendering is NOT TESTED. The original supplied-thumbnail
provenance and earlier package records remain historical. Packaging/publication
is now explicitly authorized for MP testing; see `docs/PUBLISHING.md`.
