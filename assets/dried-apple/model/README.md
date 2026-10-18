# Dried apple slices — original Blender model

Codex-authored geometry and procedural albedo, created locally in Blender 4.5.3
LTS on 2026-10-17. No Meshy, paid generation, downloaded mesh, external texture or
borrowed vanilla geometry. The sibling original inventory icon informed the
three-slice silhouette and tan/red palette; this is real closed geometry, not a
card displaying the icon. No third-party art license is asserted here.

- `dried-apple-slices.blend`: editable master with packed texture, model mesh and
  separate camera/light studio collection.
- `B47ANCEDProvisions_DriedAppleSlices.fbx`: mesh-only static export.
- `DriedApple_Albedo.png`: opaque 256×256 albedo atlas; one material and UV channel.
- `dried-apple-model-preview.png`: Blender preview with transparent background.
- `build_model.py`: original parameterized geometry/material authoring and export.
- `validate_model.py`: independent master/FBX round-trip validation.
- `model-validation.json`: actual export dimensions, topology and SHA-256 records.
- `model-definition.example.txt`: unloaded candidate B42 ground-model definition.

The pile has 756 vertices / 1,500 triangles in three closed shells, approximately
8.91 × 7.02 × 1.49 cm. Tapered ends, shallow curls, dry tan flesh and red-brown peel
are modeled/textured. Mesh rotation and scale are identity; origin is centered on
the footprint at the lowest vertex. Every face is triangulated and nondegenerate;
UVs remain within [0,1]. The FBX contains no studio objects, rig or animation.
No automatic LOD or hand attachment is supplied; this slice is a static ground
asset. Overlapping slices are a visual pile, not a collision/physics mesh.

## Installed evidence and limits

[VERIFIED source / offline import] The installed PZ Build 42.21 / Steam build
25485521 declares `DriedApricots` using `mesh = WorldItems/DriedApricots`,
`texture = WorldItems/DriedApricot`, `scale = 0.2` in
`media/scripts/generated/models_food.txt:7697`. Its FBX 7400 file imports into a
disposable Blender scene as a single static mesh, with dimensions approximately
0.298 × 0.305 × 0.0364 m before the model-script scale and object scale 0.0254.
That reference was inspected read-only and never copied into these artifacts.
Native `DriedApricot_Hand` has its own mesh/attachment; its offsets are not reusable
proof for this differently shaped object.

Our FBX is exported forward -Z / up Y, unit scale 1, with space transform baked.
[TESTED offline, Blender 4.5.3] Reimport preserves the dimensions within 1 micrometre,
1,500 triangles, UVs, material and texture. Master inspection confirms three
outward-wound manifold shells, positive volume, no degenerate triangles, floor
origin, packed opaque atlas and matching artifact hashes. The preview was visually
inspected after refining the tips and lighting. Blender rendering is not PZ proof.

[RUNTIME GATE] PZ loading, scale/orientation on ground/table, shadows, hand alignment,
item-specific model selection, join/rejoin and save/reload remain NOT TESTED.
The native renderer's unit/axis treatment may require a model-script adjustment.
The prototype still retains the same `Base.Apple` object and vanilla visuals.
Runtime integration must first verify a per-item model override and preserve that
identity and server-owned state. Do not replace the global Apple model or register
a replacement food item just to use this art. No runtime files are changed here.
G7 and stable G8 remain BLOCKED for the gameplay feature.

## Rebuild and validate

Use a local Blender executable in a separate background factory process:

```powershell
& $blender --background --factory-startup --python-exit-code 1 --python assets/dried-apple/model/build_model.py
& $blender --background --factory-startup --python-exit-code 1 --python assets/dried-apple/model/validate_model.py
python scripts/check_versions.py --root .
```

Scripts refuse to run against an existing user scene. Rebuilding intentionally
updates these owned outputs and their hashes; FBX/Blend metadata can change
between exports. Preserve manual mesh edits as a new source revision before any
rebuild. The retained builder recreates the procedural master, not later paint or
sculpt edits. Original authoring files and exports are tracked project assets,
not release packages. No cleanup of historical artifacts is performed.

The local portable tool was obtained from
[Blender's official mirror](https://mirror.blender.org/release/Blender4.5/blender-4.5.3-windows-x64.zip)
and checked against the matching official SHA-256 list:
`6b657c8bdd3a7b65b07b9e1ae17eb4be7dd4aa23121da7f3d3354fc2551330a7`.
The tool installation is outside the mod and is not a runtime dependency.

Asset-only follow-up within `0.8.0-dev.2`; no compatibility change or new version
checkpoint. No packaging, deployment, game/server launch or Workshop publication.
