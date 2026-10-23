"""Run with Blender --background --factory-startup --disable-autoexec --python.

No network/add-ons. Input is the hash-pinned original; all outputs are derivatives.
"""

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys
import tempfile

import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from warden_rig_geometry import BONES, SOURCE_SHA256, assess, components, guard_generated_outputs, identify_regions, mesh_weights


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/models/enemy-warden/model.glb"
FPS = 30
CLIPS = {"Idle": 2.0, "Walk": 1.0, "Attack": 1.4}


def sha256(path):
    with Path(path).open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def import_source():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE), merge_vertices=False)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != 1:
        raise ValueError("Expected the single original Warden mesh")
    mesh = meshes[0]
    # glTF import produces Blender (source x, -source z, source y).
    transform = Matrix.Translation((0, 0, 0.90315)) @ Matrix.Diagonal((-1.9, -1.9, 1.9, 1.0)) @ mesh.matrix_world
    normal_transform = transform.inverted().transposed().to_3x3()
    normals = [(normal_transform @ normal.vector).normalized() for normal in mesh.data.corner_normals]
    mesh.data.transform(transform)
    mesh.data.normals_split_custom_set(normals)
    mesh.data.update()
    points = [tuple(vertex.co) for vertex in mesh.data.vertices]
    mesh.parent = None
    mesh.matrix_world.identity()
    mesh.name = "WardenBody"
    mesh.data.name = "WardenOriginalTopology"
    faces = [tuple(p.vertices) for p in mesh.data.polygons]
    return mesh, points, faces


def make_armature(mesh, points, groups):
    armature = bpy.data.armatures.new("WardenHumanoid")
    rig = bpy.data.objects.new("WardenRig", armature)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, parent) in BONES.items():
        bone = armature.edit_bones.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = armature.edit_bones[parent]
        bone.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    armature.display_type = "STICK"
    assignments, weapon, hand = mesh_weights(points, [tuple(p.vertices) for p in mesh.data.polygons])
    for name in BONES:
        mesh.vertex_groups.new(name=name)
    distribution = Counter()
    for index, weights in enumerate(assignments):
        for name, value in weights.items():
            mesh.vertex_groups[name].add([index], value, "REPLACE")
        distribution[max(weights, key=weights.get)] += 1
    modifier = mesh.modifiers.new("WardenSkin", "ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = False
    mesh.parent = rig
    return rig, weapon, hand, dict(distribution)


def rotate(rig, name, axis, radians):
    bone = rig.pose.bones[name]
    rest = rig.data.bones[name].matrix_local.to_quaternion()
    bone.rotation_quaternion = rest.inverted() @ Quaternion(axis, radians) @ rest


def smooth(start, end, time):
    t = max(0.0, min(1.0, (time - start) / (end - start)))
    return t * t * (3.0 - 2.0 * t)


def pose_clip(rig, clip, time):
    for bone in rig.pose.bones:
        bone.rotation_mode = "QUATERNION"
        bone.rotation_quaternion = Quaternion()
        bone.location = Vector((0, 0, 0))
        bone.scale = Vector((1, 1, 1))
    if clip == "Idle":
        breath = math.sin(time * math.tau / CLIPS[clip])
        rotate(rig, "Spine", (1, 0, 0), 0.012 * breath)
        rotate(rig, "Chest", (1, 0, 0), -0.008 * breath)
        rotate(rig, "Head", (0, 0, 1), 0.012 * breath)
        rotate(rig, "Forearm.L", (1, 0, 0), 0.018 * breath)
    elif clip == "Walk":
        phase = time * math.tau
        for side, sign in (("R", 1), ("L", -1)):
            stride = math.sin(phase) * sign
            thigh = 0.28 * stride
            shin = -0.5 * max(stride, 0.0)
            rotate(rig, f"Thigh.{side}", (1, 0, 0), thigh)
            rotate(rig, f"Shin.{side}", (1, 0, 0), shin)
            rotate(rig, f"Foot.{side}", (1, 0, 0), -thigh - shin)
            rotate(rig, f"UpperArm.{side}", (1, 0, 0), -0.15 * stride)
            rotate(rig, f"Forearm.{side}", (1, 0, 0), 0.08 * max(-stride, 0.0))
        rotate(rig, "Pelvis", (0, 0, 1), 0.025 * math.sin(phase))
        rotate(rig, "Chest", (0, 0, 1), -0.04 * math.sin(phase))
    elif clip == "Attack":
        if time < 0.55:
            blend = smooth(0, 0.55, time)
            shoulder, elbow, twist = 1.5 * blend, 0.7 * blend, -0.12 * blend
        elif time < 0.69:
            blend = smooth(0.55, 0.69, time)
            shoulder, elbow, twist = 1.5 - 0.8 * blend, 0.7 - 0.55 * blend, -0.12 + 0.24 * blend
        else:
            blend = 1.0 - smooth(0.69, 1.12, time)
            shoulder, elbow, twist = 0.7 * blend, 0.15 * blend, 0.12 * blend
        rotate(rig, "UpperArm.R", (1, 0, 0), shoulder)
        rotate(rig, "Forearm.R", (1, 0, 0), elbow)
        rotate(rig, "Chest", (0, 0, 1), twist)
        rotate(rig, "UpperArm.L", (1, 0, 0), 0.12 * math.sin(time * math.pi / 1.4))


def animate(rig):
    bpy.context.scene.render.fps = FPS
    rig.animation_data_create()
    actions = []
    for clip, length in CLIPS.items():
        action = bpy.data.actions.new(clip)
        action.use_fake_user = True
        rig.animation_data.action = action
        frames = round(length * FPS)
        for frame in range(frames + 1):
            pose_clip(rig, clip, frame / FPS)
            for bone in rig.pose.bones:
                bone.keyframe_insert(data_path="rotation_quaternion", frame=frame + 1, group=bone.name)
                bone.keyframe_insert(data_path="location", frame=frame + 1, group=bone.name)
        track = rig.animation_data.nla_tracks.new()
        track.name = clip
        strip = track.strips.new(clip, 1, action)
        strip.name = clip
        track.mute = True
        actions.append(action)
    rig.animation_data.action = None
    pose_clip(rig, "Idle", 0)
    bpy.context.scene.frame_set(1)
    return actions


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assess-only", action="store_true")
    parser.add_argument("--replace-generated", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    report = assess(SOURCE)
    authoring = ROOT / "builds/authoring/warden-rig"
    authoring.mkdir(parents=True, exist_ok=True)
    mesh, points, faces = import_source()
    groups = components(points, faces)
    weapon, hand = identify_regions(points, groups)
    report["blender_mesh_vertices"] = len(points)
    report["blender_mesh_faces"] = len(faces)
    report["blade_vertices"] = len(weapon)
    report["rigid_hand_region_vertices"] = len(hand)
    report["blender_version"] = bpy.app.version_string
    report["blender_build_hash"] = bpy.app.build_hash.decode()
    (authoring / "mesh-assessment.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("ASSESSMENT:", json.dumps(report), flush=True)
    if args.assess_only:
        return
    output = ROOT / "assets/prototypes/warden-rig"
    glb = output / "warden_rig.glb"
    blend = authoring / "warden_rig.blend"
    provenance = output / "provenance.json"
    guard_generated_outputs(glb, blend, provenance, args.replace_generated)
    rig, weapon, hand, distribution = make_armature(mesh, points, groups)
    animate(rig)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 61
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    mesh.select_set(True)
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="build-", dir=authoring) as stage:
        staged_blend = Path(stage) / "warden_rig.blend"
        staged_glb = Path(stage) / "warden_rig.glb"
        bpy.ops.wm.save_as_mainfile(filepath=str(staged_blend))
        bpy.ops.export_scene.gltf(
            filepath=str(staged_glb), export_format="GLB", use_selection=True,
            export_materials="NONE", export_texcoords=True, export_normals=True,
            export_skins=True, export_all_influences=False, export_influence_nb=4, export_def_bones=True,
            export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True,
            export_anim_single_armature=True, export_frame_range=False, export_anim_slide_to_zero=True,
            export_yup=True, export_extras=False,
        )
        record = {
            "source": "assets/models/enemy-warden/model.glb", "source_sha256": SOURCE_SHA256,
            "authoring_script": "tools/author_warden_rig.py", "blender_version": bpy.app.version_string,
            "authoring_script_sha256": sha256(Path(__file__)),
            "weight_helper_sha256": sha256(ROOT / "tools/warden_rig_geometry.py"),
            "blender_build_hash": bpy.app.build_hash.decode(), "bones": len(BONES), "clips": CLIPS,
            "coordinates": "Godot meters / Y-up / -Z-forward, baked existing normalization",
            "geometry": {"vertices": len(points), "triangles": len(faces), "topology_changed": False, "uvs_preserved": True},
            "material": "Original Warden material/1K textures reused by Godot preview; derivative embeds no textures",
            "weighting": "Deterministic fitted anatomical regions, six inverse-edge-length topology-smoothing passes, max four normalized influences; disconnected hand and blade rigid",
            "dominant_weight_vertex_counts": distribution, "blade_vertices": len(weapon), "rigid_hand_vertices": len(hand),
            "attack_visual_windup_seconds": 0.55, "gameplay_integration": False,
            "glb_sha256": sha256(staged_glb), "blend_sha256": sha256(staged_blend),
            "limitations": ["Technical prototype, not production animation", "No fingers/facial rig or cloth simulation", "Spatial weights and in-place foot planting require human review"],
        }
        shutil.copyfile(staged_glb, glb)
        shutil.copyfile(staged_blend, blend)
        provenance.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print("SUCCESS:", glb, "editable source:", blend, flush=True)
    print("PROVENANCE:", json.dumps(record), flush=True)


if __name__ == "__main__":
    main()
