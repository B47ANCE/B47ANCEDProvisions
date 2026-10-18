"""Original local Blender authoring. Run in a disposable --background --factory-startup process."""
import bpy
import bmesh
import hashlib
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
if not bpy.app.background or bpy.data.filepath:
    raise RuntimeError('Use a new background factory scene, never an existing user file')
for obj in list(bpy.context.scene.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
collection = bpy.data.collections.new('Dried apple - export mesh only')
scene.collection.children.link(collection)

def enum_set(owner, name, value):
    prop = owner.bl_rna.properties[name]
    valid = [entry.identifier for entry in prop.enum_items]
    if value not in valid:
        raise RuntimeError(f'{name}: {value} absent from {valid}')
    setattr(owner, name, value)

# A purpose-authored albedo atlas, not a photograph or a projected icon.
# Bottom 76% is warm flesh; the upper strip is muted red peel.
size = 256
image = bpy.data.images.new('DriedApple_Albedo', width=size, height=size, alpha=True)
pixels = []
for y in range(size):
    v = y / (size - 1)
    for x in range(size):
        u = x / (size - 1)
        grain = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
        grain = (grain - math.floor(grain)) - 0.5
        wrinkles = math.sin(u * 116 + math.sin(v * 35) * 1.7)
        fibres = math.sin(v * 91 + math.sin(u * 29) * 3.1)
        if v < 0.76:
            tone = 0.045 * grain + 0.018 * wrinkles + 0.017 * fibres
            edge = 0.08 * (abs(v - 0.38) / 0.38) ** 3
            rgb = (0.63 + tone - edge, 0.39 + tone - edge, 0.17 + tone * 0.7 - edge * 0.7)
        else:
            tone = 0.035 * grain + 0.018 * fibres
            rgb = (0.22 + tone, 0.035 + tone * 0.6, 0.018 + tone * 0.4)
        pixels.extend((*[max(0, min(1, c)) for c in rgb], 1.0))
image.pixels.foreach_set(pixels)
image.filepath_raw = str(ROOT / 'DriedApple_Albedo.png')
enum_set(image, 'file_format', 'PNG')
image.save()
material = bpy.data.materials.new('DriedApple_SingleAtlas')
material.use_nodes = True
principled = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
principled.inputs['Roughness'].default_value = 0.86
principled.inputs['Metallic'].default_value = 0
texture = material.node_tree.nodes.new('ShaderNodeTexImage')
texture.image = image
material.node_tree.links.new(texture.outputs['Color'], principled.inputs['Base Color'])

vertices, faces, texcoords = [], [], []
segments, radial_steps = 20, 5
for slice_index, (angle, dx, dy, dz) in enumerate([
    (-0.30, -0.006, -0.018, 0.0038),
    (0.30, 0.010, -0.002, 0.0062),
    (0.85, -0.010, 0.011, 0.0086),
]):
    start = len(vertices)
    stride = radial_steps + 1
    layer_size = (segments + 1) * stride
    def idx(side, i, j):
        return start + side * layer_size + i * stride + j
    for side in range(2):
        for i in range(segments + 1):
            theta = 0.18 + (math.pi - 0.36) * i / segments
            for j in range(radial_steps + 1):
                q = [0, 0.23, 0.47, 0.71, 0.92, 1][j]
                taper = math.sin(math.pi * i / segments) ** 0.65
                breadth = 0.0008 + 0.0202 * taper
                radius = 0.038 - breadth * (1 - q)
                px = radius * math.cos(theta)
                py = radius * math.sin(theta) * 0.83
                # Slight irregularity and end curl give real depth to the dry edge.
                py += 0.00065 * math.sin(theta * 9 + q * 3 + slice_index)
                curl = 0.0026 * math.cos(theta * 2) + 0.0012 * math.sin(theta * 7 + q * 3)
                curl += 0.0035 * (q - 0.45) ** 2
                thickness = 0.0020 + 0.0003 * math.sin(theta * 5 + q)
                pz = dz + curl + (0.5 if side == 0 else -0.5) * thickness
                vertices.append((dx + math.cos(angle) * px - math.sin(angle) * py,
                                 dy + math.sin(angle) * px + math.cos(angle) * py, pz))
    def add_face(indices, uv):
        faces.append(indices)
        texcoords.append(uv)
    for side in range(2):
        for i in range(segments):
            for j in range(radial_steps):
                ids = [idx(side, i, j), idx(side, i + 1, j), idx(side, i + 1, j + 1), idx(side, i, j + 1)]
                v0, v1 = (0.80, 0.97) if j == radial_steps - 1 else (0.05 + j * 0.15, 0.05 + (j + 1) * 0.15)
                uv = [(0.02 + 0.96 * i / segments, v0), (0.02 + 0.96 * (i + 1) / segments, v0),
                      (0.02 + 0.96 * (i + 1) / segments, v1), (0.02 + 0.96 * i / segments, v1)]
                if side:
                    ids.reverse()
                    uv.reverse()
                add_face(ids, uv)
    for i in range(segments):
        for j in (0, radial_steps):
            add_face([idx(0, i, j), idx(1, i, j), idx(1, i + 1, j), idx(0, i + 1, j)],
                     [(i / segments, 0.82 if j else 0.1), (i / segments, 0.96 if j else 0.3),
                      ((i + 1) / segments, 0.96 if j else 0.3), ((i + 1) / segments, 0.82 if j else 0.1)])
    for i in (0, segments):
        for j in range(radial_steps):
            add_face([idx(0, i, j), idx(0, i, j + 1), idx(1, i, j + 1), idx(1, i, j)],
                     [(0.05, 0.1), (0.20, 0.1), (0.20, 0.2), (0.05, 0.2)])

# Put the origin at the centered footprint, with the lowest vertex on the floor.
lo = [min(p[i] for p in vertices) for i in range(3)]
hi = [max(p[i] for p in vertices) for i in range(3)]
center = ((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2])
vertices = [tuple(p[i] - center[i] for i in range(3)) for p in vertices]
mesh = bpy.data.meshes.new('DriedAppleSlices_Triangulated')
mesh.from_pydata(vertices, [], faces)
mesh.update()
uv_layer = mesh.uv_layers.new(name='AlbedoUV')
for polygon, uv in zip(mesh.polygons, texcoords):
    for loop, coord in zip(polygon.loop_indices, uv):
        uv_layer.data[loop].uv = coord
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
bmesh.ops.triangulate(bm, faces=list(bm.faces))
bm.to_mesh(mesh)
bm.free()
mesh.update()
obj = bpy.data.objects.new('B47ANCEDProvisions_DriedAppleSlices', mesh)
collection.objects.link(obj)
obj.data.materials.append(material)
for poly in mesh.polygons:
    poly.use_smooth = True
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# Geometry checks before export: each slice is a closed shell with positive volume.
bm = bmesh.new()
bm.from_mesh(mesh)
assert all(e.is_manifold for e in bm.edges), 'Open/nonmanifold edge'
assert all(f.calc_area() > 1e-12 for f in bm.faces), 'Degenerate triangle'
volume = bm.calc_volume(signed=True)
assert volume > 0
bm.free()
assert len(mesh.polygons) <= 1600
assert all(len(p.vertices) == 3 for p in mesh.polygons)
assert all(0 <= uv.uv.x <= 1 and 0 <= uv.uv.y <= 1 for uv in mesh.uv_layers.active.data)
assert tuple(obj.scale) == (1, 1, 1)

# FBX matches the installed native static-mesh container format. Axis/scale still
# require game validation; this is an authoring export, not runtime registration.
fbx_props = bpy.ops.export_scene.fbx.get_rna_type().properties
for name, val in [('axis_forward', '-Z'), ('axis_up', 'Y'), ('path_mode', 'RELATIVE')]:
    assert val in [i.identifier for i in fbx_props[name].enum_items]
bpy.ops.export_scene.fbx(filepath=str(ROOT / 'B47ANCEDProvisions_DriedAppleSlices.fbx'),
    use_selection=True, object_types={'MESH'}, global_scale=1, apply_unit_scale=True,
    bake_space_transform=True, axis_forward='-Z', axis_up='Y', use_mesh_modifiers=True,
    mesh_smooth_type='FACE', add_leaf_bones=False, bake_anim=False, path_mode='RELATIVE')
image.pack()

# A separate studio collection is excluded from the mesh export above.
studio = bpy.data.collections.new('Preview studio - excluded from FBX')
scene.collection.children.link(studio)
camera_data = bpy.data.cameras.new('AssetPreviewCamera')
camera = bpy.data.objects.new('AssetPreviewCamera', camera_data)
studio.objects.link(camera)
camera.location = (0.10, -0.15, 0.17)
target = Vector((0, 0, 0.008))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
enum_set(camera_data, 'type', 'ORTHO')
camera_data.ortho_scale = 0.125
camera_data.clip_start = 0.001
scene.camera = camera
for name, pos, power, extent in [('Key', (-0.08, -0.08, 0.15), 0.65, 0.10), ('Fill', (0.10, 0.06, 0.08), 0.25, 0.12)]:
    data = bpy.data.lights.new(name, type='AREA')
    data.energy, data.size = power, extent
    light = bpy.data.objects.new(name, data)
    studio.objects.link(light)
    light.location = pos
    light.rotation_euler = (target - light.location).to_track_quat('-Z', 'Y').to_euler()
scene.world.color = (0.16, 0.16, 0.16)
try:
    scene.render.engine = 'CYCLES'
except TypeError as exc:
    raise RuntimeError('Cycles required for repeatable CPU preview') from exc
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
enum_set(scene.render.image_settings, 'file_format', 'PNG')
enum_set(scene.render.image_settings, 'color_mode', 'RGBA')
# Keep the scene's valid color-management default (a dynamic enum in this build).
scene.render.filepath = str(ROOT / 'dried-apple-model-preview.png')
image.filepath = '//DriedApple_Albedo.png'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'dried-apple-slices.blend'))
bpy.ops.render.render(write_still=True)
report = {
    'blender': bpy.app.version_string, 'preview_view_transform': scene.view_settings.view_transform,
    'authoring': 'Codex original procedural mesh and albedo; no external generation or borrowed mesh',
    'vertices': len(mesh.vertices), 'triangles': len(mesh.polygons), 'closed_shells': 3,
    'dimensions_metres': [hi[i] - lo[i] for i in range(3)], 'origin': 'footprint center, lowest vertex at Z=0',
    'transforms': 'identity rotation/scale, geometry authored in metres', 'materials': 1,
    'albedo': '256x256 RGBA, opaque, single UV atlas', 'uv_bounds': [0, 1],
    'manifold_edges': True, 'degenerate_faces': 0, 'signed_volume_m3': volume,
    'fbx': {'axis_forward': '-Z', 'axis_up': 'Y', 'global_scale': 1, 'bake_space_transform': True, 'animation': False},
    'runtime': 'Native SP/dedicated NOT TESTED; model not registered or deployed',
    'files': {}
}
for name in ['build_model.py', 'dried-apple-slices.blend', 'B47ANCEDProvisions_DriedAppleSlices.fbx', 'DriedApple_Albedo.png', 'dried-apple-model-preview.png']:
    report['files'][name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
(ROOT / 'model-validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print('DRIED_APPLE_MODEL', json.dumps(report, indent=2))
