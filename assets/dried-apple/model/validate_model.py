"""Independent Blender round-trip checks; no game/runtime claims."""
import bpy
import bmesh
import hashlib
import json
from pathlib import Path
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parent
assert bpy.app.background and not bpy.data.filepath, 'Use a disposable factory scene'
report = json.loads((root / 'model-validation.json').read_text())
for name, digest in report['files'].items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
bpy.ops.wm.open_mainfile(filepath=str(root / 'dried-apple-slices.blend'))
models = [o for o in bpy.context.scene.objects if o.type == 'MESH']
assert len(models) == 1
model = models[0]
assert len(model.data.polygons) == report['triangles'] == 1500
assert not list(bpy.data.armatures) and not list(bpy.data.actions)
atlas = next(i for i in bpy.data.images if i.name == 'DriedApple_Albedo')
assert tuple(atlas.size) == (256, 256) and atlas.packed_file is not None
assert all(a == 1 for a in list(atlas.pixels)[3::4]), 'Albedo must be opaque'
assert atlas.filepath == '//DriedApple_Albedo.png'
assert min(v.co.z for v in model.data.vertices) >= -1e-8
bm = bmesh.new()
bm.from_mesh(model.data)
assert all(e.is_manifold for e in bm.edges)
unseen = set(bm.verts)
volumes = []
shell_trees = []
while unseen:
    visited = {unseen.pop()}
    queue = list(visited)
    while queue:
        v = queue.pop()
        for e in v.link_edges:
            other = e.other_vert(v)
            if other not in visited:
                visited.add(other)
                unseen.discard(other)
                queue.append(other)
    # The component's triangles have consistently outward winding.
    shell_faces = {f for v in visited for f in v.link_faces}
    signed = sum(f.verts[0].co.dot(f.verts[1].co.cross(f.verts[2].co)) / 6 for f in shell_faces)
    assert signed > 0
    volumes.append(signed)
    shell_trees.append(BVHTree.FromPolygons([v.co for v in bm.verts],
        [[v.index for v in f.verts] for f in shell_faces], all_triangles=True))
assert len(volumes) == 3
assert all(not a.overlap(b) for i, a in enumerate(shell_trees) for b in shell_trees[i+1:]), 'Intersecting slice surfaces'
bm.free()
source_dimensions = sorted(model.dimensions)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(root / 'B47ANCEDProvisions_DriedAppleSlices.fbx'))
objects = list(bpy.context.scene.objects)
assert len(objects) == 1 and objects[0].type == 'MESH', 'Studio leaked into export'
mesh = objects[0].data
assert len(mesh.polygons) == 1500 and all(len(p.vertices) == 3 for p in mesh.polygons)
assert len(mesh.materials) == 1 and len(mesh.uv_layers) == 1
assert all(abs(a - b) < 1e-6 for a, b in zip(source_dimensions, sorted(objects[0].dimensions)))
images = [i for i in bpy.data.images if i.source == 'FILE' and i.name.startswith('DriedApple_Albedo')]
assert images and tuple(images[0].size) == (256, 256), 'Missing texture after import'
assert all(0 <= uv.uv.x <= 1 and 0 <= uv.uv.y <= 1 for uv in mesh.uv_layers.active.data)
print('PASS master hashes, packed opaque atlas, three outward closed shells, floor origin, no rig/animation')
print('PASS independent BVH check: slice surfaces do not intersect')
print('PASS independent FBX reimport: one mesh, 1500 triangles, UVs, single material/texture, dimensions within 1 micrometre')
print('Native PZ SP/dedicated model display/scale/attachment NOT TESTED; no deployment')
