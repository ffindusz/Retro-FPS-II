"""Rig and animate the Meshy Fire Bat headlessly, then export one GLB with all clips.

Usage:
  blender -b --factory-startup --python tools/blender/rig_bat.py -- <meshy model.glb> <out.glb> [render_prefix]

Meshy rigging only supports humanoids, so the bat gets a small hand-built armature:
body, plus shoulder (wing_1) and tip (wing_2) bones per wing. Skin weights are computed
from each vertex's distance from the body midline, which suits a symmetric spread-wing pose.
Clips: fly (loop), attack, hit, death. Front of the model faces -Y in Blender (glTF +Z).
"""
import math
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

args = sys.argv[sys.argv.index("--") + 1:]
source, output = args[0], args[1]
render_prefix = args[2] if len(args) > 2 else ""
FPS = 24

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = FPS
bpy.ops.import_scene.gltf(filepath=source)
meshes = [o for o in scene.objects if o.type == "MESH"]
assert len(meshes) == 1, f"expected one mesh, got {len(meshes)}"
mesh = meshes[0]
# Bake any import transforms into the vertices so weights use world coordinates.
mesh.parent = None
mesh.data.transform(mesh.matrix_world)
mesh.matrix_world = Matrix.Identity(4)
for obj in list(scene.objects):
    if obj is not mesh and obj.type == "EMPTY":
        bpy.data.objects.remove(obj)

verts = [v.co.copy() for v in mesh.data.vertices]
span = max(abs(v.x) for v in verts)
body_half = 0.15 * span
elbow = 0.55 * span
outer = [v for v in verts if abs(v.x) > 0.4 * span]
wing_z = sum(v.z for v in outer) / len(outer)
wing_y = sum(v.y for v in outer) / len(outer)
core = [v for v in verts if abs(v.x) < body_half]
body_center = sum(core, Vector()) / len(core)
print(f"SPAN {span:.3f} WING_Z {wing_z:.3f} BODY {tuple(round(c, 3) for c in body_center)}")

# --- Armature -------------------------------------------------------------------------
arm_data = bpy.data.armatures.new("BatRig")
rig = bpy.data.objects.new("BatRig", arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
body = arm_data.edit_bones.new("body")
body.head = body_center
body.tail = body_center + Vector((0, 0, 0.25 * span))
for side, sign in (("L", 1.0), ("R", -1.0)):
    shoulder = Vector((sign * body_half, wing_y, wing_z))
    mid = Vector((sign * elbow, wing_y, wing_z))
    tip = Vector((sign * span, wing_y, wing_z))
    w1 = arm_data.edit_bones.new(f"wing_1.{side}")
    w1.head, w1.tail, w1.roll, w1.parent = shoulder, mid, 0.0, body
    w2 = arm_data.edit_bones.new(f"wing_2.{side}")
    w2.head, w2.tail, w2.roll, w2.parent = mid, tip, 0.0, w1
    w2.use_connect = True
bpy.ops.object.mode_set(mode="OBJECT")

# --- Skin weights from distance to the midline -----------------------------------------
groups = {name: mesh.vertex_groups.new(name=name) for name in ("body", "wing_1.L", "wing_2.L", "wing_1.R", "wing_2.R")}

def smooth(t: float) -> float:
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)

for index, v in enumerate(verts):
    ax = abs(v.x)
    side = "L" if v.x >= 0 else "R"
    shoulder_blend = smooth((ax - body_half * 0.7) / (body_half * 0.8))
    tip_blend = smooth((ax - elbow * 0.85) / (elbow * 0.3))
    weights = {"body": 1.0 - shoulder_blend, f"wing_1.{side}": shoulder_blend * (1.0 - tip_blend), f"wing_2.{side}": shoulder_blend * tip_blend}
    for name, weight in weights.items():
        if weight > 0.001:
            groups[name].add([index], weight, "REPLACE")
modifier = mesh.modifiers.new("Armature", "ARMATURE")
modifier.object = rig
mesh.parent = rig

# --- Animation helpers -------------------------------------------------------------------
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
for bone in rig.pose.bones:
    bone.rotation_mode = "QUATERNION"

def world_axis_rotation(bone_name: str, axis: Vector, degrees: float) -> Quaternion:
    """Pose-space quaternion that turns the bone about a world axis (rest frame)."""
    rest = rig.data.bones[bone_name].matrix_local.to_3x3()
    world = Quaternion(axis, math.radians(degrees)).to_matrix()
    return (rest.inverted() @ world @ rest).to_quaternion()

FORWARD = Vector((0, 1, 0))  # flap axis: wings swing up/down around the body's length
PITCH = Vector((1, 0, 0))

def pose(frame: int, body_pitch: float = 0.0, lift: float = 0.0, w1: float = 0.0, w2: float = 0.0, body_roll: float = 0.0, sweep: float = 0.0) -> None:
    """w1/w2: wing angles in degrees, positive raises the wings. sweep folds tips backwards."""
    body = rig.pose.bones["body"]
    body.rotation_quaternion = world_axis_rotation("body", PITCH, body_pitch) @ world_axis_rotation("body", FORWARD, body_roll)
    body.location = Vector((0, 0, 0))
    # Body bone points up (+Z world); its local Y is world Z, so lift moves along local Y.
    body.location.y = lift
    for side, sign in (("L", 1.0), ("R", -1.0)):
        a = rig.pose.bones[f"wing_1.{side}"]
        b = rig.pose.bones[f"wing_2.{side}"]
        a.rotation_quaternion = world_axis_rotation(a.name, FORWARD, -sign * w1)
        b.rotation_quaternion = world_axis_rotation(b.name, FORWARD, -sign * w2) @ world_axis_rotation(b.name, Vector((0, 0, 1)), sign * sweep)
    for bone in rig.pose.bones:
        bone.keyframe_insert("rotation_quaternion", frame=frame)
        bone.keyframe_insert("location", frame=frame)

def clip(name: str, frames: int, poses) -> bpy.types.Action:
    rig.animation_data_create()
    action = bpy.data.actions.new(name)
    rig.animation_data.action = action
    for frame, kwargs in poses:
        pose(frame, **kwargs)
    action.use_fake_user = True
    action.frame_range = (0, frames)
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, action)
    rig.animation_data.action = None
    return action

# fly: 16-frame loop (0.67 s). Tips trail the shoulders for a whip-like beat.
fly = []
for frame in range(0, 17, 2):
    phase = frame / 16 * math.tau
    fly.append((frame, dict(w1=45 * math.sin(phase), w2=25 * math.sin(phase - 0.9), lift=-0.03 * span * math.sin(phase), body_pitch=4 * math.sin(phase))))
clip("fly", 16, fly)
# attack: rear back with wings high (0-8), snap forward to spit at frame 9, recover by 16.
clip("attack", 16, [
    (0, dict()),
    (6, dict(body_pitch=-22, w1=55, w2=35, lift=0.04 * span)),
    (8, dict(body_pitch=-26, w1=60, w2=40, lift=0.05 * span)),
    (10, dict(body_pitch=18, w1=-20, w2=-10, lift=-0.02 * span)),
    (16, dict()),
])
# hit: a short jolt.
clip("hit", 8, [
    (0, dict()),
    (2, dict(body_pitch=-18, body_roll=10, w1=30, w2=50)),
    (8, dict()),
])
# death: wings crumple and fold back while the body rolls over.
clip("death", 20, [
    (0, dict()),
    (4, dict(body_pitch=-20, w1=40, w2=60)),
    (12, dict(body_pitch=30, body_roll=60, w1=-50, w2=-70, sweep=40)),
    (20, dict(body_pitch=40, body_roll=90, w1=-70, w2=-90, sweep=55)),
])
for action in bpy.data.actions:
    for fcurve in action.fcurves if hasattr(action, "fcurves") else []:
        for point in fcurve.keyframe_points:
            point.interpolation = "BEZIER"
bpy.ops.object.mode_set(mode="OBJECT")
print("ACTIONS", [(a.name, tuple(a.frame_range)) for a in bpy.data.actions])

bpy.ops.export_scene.gltf(
    filepath=output, export_format="GLB", export_animations=True,
    export_animation_mode="NLA_TRACKS", export_skins=True, export_apply=False, export_yup=True,
)
print("EXPORTED", output)

if render_prefix:
    try:
        scene.render.engine = "BLENDER_WORKBENCH"
    except TypeError:
        pass
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = scene.render.resolution_y = 384
    scene.world = bpy.data.worlds.new("w")
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = span * 2.6
    direction = Vector((0.35, -1, 0.45)).normalized()
    cam.location = body_center + direction * span * 4
    cam.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    for track in rig.animation_data.nla_tracks:
        track.mute = False
        start, end = track.strips[0].frame_start, track.strips[0].frame_end
        for label, frame in (("a", start), ("b", (start + end) / 2), ("c", end)):
            scene.frame_set(int(frame))
            scene.render.filepath = f"{render_prefix}-{track.name}-{label}.png"
            bpy.ops.render.render(write_still=True)
        track.mute = True
