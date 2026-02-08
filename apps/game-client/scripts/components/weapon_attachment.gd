extends Node3D
class_name WeaponAttachment

## Attaches a weapon model to a character's hand bone

@export var weapon_model_path: String = "res://assets/models/quaternius-weapons/Sword.obj"
@export var hand_bone_name: String = "RightHand"
@export var weapon_offset: Vector3 = Vector3(0, 0, 0)
@export var weapon_rotation: Vector3 = Vector3(0, 0, 0)

var skeleton: Skeleton3D
var weapon_instance: Node3D
var bone_attachment: BoneAttachment3D

func _ready() -> void:
	# Find the skeleton in parent
	skeleton = _find_skeleton(get_parent())
	
	if not skeleton:
		push_error("WeaponAttachment: No Skeleton3D found!")
		return
	
	# Find the hand bone
	var bone_idx = skeleton.find_bone(hand_bone_name)
	if bone_idx == -1:
		push_error("WeaponAttachment: Bone '", hand_bone_name, "' not found!")
		print("WeaponAttachment: Available bones: ", _get_bone_names(skeleton))
		return
	
	# Create BoneAttachment3D
	bone_attachment = BoneAttachment3D.new()
	bone_attachment.bone_name = hand_bone_name
	skeleton.add_child(bone_attachment)
	
	# Load and instance weapon
	var weapon_scene = load(weapon_model_path)
	if not weapon_scene:
		push_error("WeaponAttachment: Failed to load weapon from ", weapon_model_path)
		return
	
	weapon_instance = weapon_scene.instantiate()
	bone_attachment.add_child(weapon_instance)
	
	# Apply offset and rotation
	weapon_instance.position = weapon_offset
	weapon_instance.rotation_degrees = weapon_rotation
	
	print("WeaponAttachment: Attached weapon to ", hand_bone_name)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	
	return null

func _get_bone_names(skel: Skeleton3D) -> Array:
	var names = []
	for i in range(skel.get_bone_count()):
		names.append(skel.get_bone_name(i))
	return names
