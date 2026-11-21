"""Headless: import a GLB, print its bounds/triangle count, render labelled views to PNGs.
Usage: blender -b --factory-startup --python inspect_model.py -- <model.glb> <out_prefix>"""
import sys, math, bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
model, prefix = args[0], args[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=model)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
points = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
hi = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes)
print("MESHES", len(meshes), "TRIS", tris, "MIN", tuple(round(v, 3) for v in lo), "MAX", tuple(round(v, 3) for v in hi))
print("ARMATURES", [o.name for o in bpy.context.scene.objects if o.type == "ARMATURE"], "ACTIONS", [a.name for a in bpy.data.actions])
center, size = (lo + hi) / 2, max(hi - lo)
scene = bpy.context.scene
try:
    scene.render.engine = "BLENDER_WORKBENCH"
except TypeError:
    pass
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE" if any(o.data.materials and o.data.materials[0] and o.data.materials[0].use_nodes for o in meshes) else "MATERIAL"
scene.render.resolution_x = scene.render.resolution_y = 512
world = bpy.data.worlds.new("w"); scene.world = world
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam); scene.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = size * 1.15
for name, direction in {"front": (0, -1, 0.05), "top": (0, -0.01, 1), "side": (1, 0, 0.05), "three_quarter": (0.8, -0.8, 0.6)}.items():
    d = Vector(direction).normalized()
    cam.location = center + d * size * 3
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = f"{prefix}-{name}.png"
    bpy.ops.render.render(write_still=True)
