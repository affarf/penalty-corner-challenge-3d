
extends Node3D

@export var shirt_color: Color = Color("#DC3545")
@export var is_goalkeeper: bool = false
@export_range(0.8, 1.5, 0.02) var height_scale: float = 1.12

@export_group("Hockey Pose")
@export_range(0.0, 1.0, 0.05) var stance: float = 0.55
@export var stick_color: Color = Color("#E9D448")

var visual_root: Node3D

const PlayerAnimation = preload(
	"res://scripts/players/player_animation_3d.gd"
)

signal hockey_contact(action: String)

var action_rig: Node3D
var player_animator: Node

var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var run_time: float = 0.0

func _ready() -> void:
	build_player()

	player_animator = PlayerAnimation.new()
	player_animator.name = "PlayerAnimator"
	add_child(player_animator)

	player_animator.setup(action_rig)

	player_animator.contact.connect(
		_on_animation_contact
	)


func play_hockey_action(action: String) -> void:
	if player_animator == null:
		return

	player_animator.play_action(action)


func _on_animation_contact(action: String) -> void:
	hockey_contact.emit(action)



func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material


func add_box(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	color: Color
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.position = pos
	instance.material_override = make_material(color)
	parent.add_child(instance)
	return instance


func add_sphere(
	parent: Node3D,
	pos: Vector3,
	radius: float,
	color: Color
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	instance.mesh = mesh
	instance.position = pos
	instance.material_override = make_material(color)
	parent.add_child(instance)
	return instance


# Build a rectangular limb connecting two actual points.
func add_segment(
	parent: Node3D,
	from_point: Vector3,
	to_point: Vector3,
	thickness: float,
	color: Color
) -> void:
	var direction: Vector3 = to_point - from_point
	var length: float = direction.length()

	if length < 0.001:
		return

	var segment := add_box(
		parent,
		(from_point + to_point) * 0.5,
		Vector3(thickness, length, thickness),
		color
	)

	segment.quaternion = Quaternion(
		Vector3.UP,
		direction.normalized()
	)


func build_player() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visuals"
	add_child(visual_root)
	visual_root.scale = Vector3(
		1.0,
		height_scale,
		1.0
	)

	var skin := Color("#E8D9BA")
	var legs_color := Color("#F5F5F5")
	var grip := Color("#22272B")

	# We construct the player facing local +Z.
	# Rotating the entire player keeps both hands on the stick.

	
	# Movable legs for procedural running.
	var left_hip := Vector3(-0.23, 0.91, 0.0)
	var right_hip := Vector3(0.23, 0.91, 0.0)

	var left_knee := Vector3(-0.37, 0.52, 0.22)
	var right_knee := Vector3(0.35, 0.53, 0.13)

	var left_foot := Vector3(-0.39, 0.14, 0.24)
	var right_foot := Vector3(0.39, 0.14, -0.10)

	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLeg"
	left_leg_pivot.position = left_hip
	visual_root.add_child(left_leg_pivot)

	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLeg"
	right_leg_pivot.position = right_hip
	visual_root.add_child(right_leg_pivot)

	# Build each leg relative to its hip pivot.
	add_segment(
		left_leg_pivot,
		Vector3.ZERO,
		left_knee - left_hip,
		0.29,
		legs_color
	)

	add_segment(
		left_leg_pivot,
		left_knee - left_hip,
		left_foot - left_hip,
		0.29,
		legs_color
	)

	add_box(
		left_leg_pivot,
		left_foot - left_hip,
		Vector3(0.34, 0.25, 0.52),
		legs_color
	)

	add_segment(
		right_leg_pivot,
		Vector3.ZERO,
		right_knee - right_hip,
		0.29,
		legs_color
	)

	add_segment(
		right_leg_pivot,
		right_knee - right_hip,
		right_foot - right_hip,
		0.29,
		legs_color
	)

	add_box(
		right_leg_pivot,
		right_foot - right_hip,
		Vector3(0.34, 0.25, 0.52),
		legs_color
	)


	# Lean the torso forward.
	var body_lean: float = stance * 0.34
	var torso_root := Node3D.new()
	torso_root.name = "Torso"
	torso_root.position = Vector3(0, 1.17, 0.10)
	torso_root.rotation.x = body_lean
	visual_root.add_child(torso_root)

	add_box(
		torso_root,
		Vector3.ZERO,
		Vector3(0.82, 0.90, 0.48),
		shirt_color
	)

	add_sphere(
		torso_root,
		Vector3(0, 0.69, 0.03),
		0.30,
		skin
	)
	
	action_rig = Node3D.new()
	action_rig.name = "ActionRig"
	visual_root.add_child(action_rig)

	# Stick occupies the space in front of the player.
	# Left hand high, right hand lower.
	var upper_hand := Vector3(-0.10, 1.17, 0.52)
	var lower_hand := Vector3(0.14, 0.89, 0.66)
	var stick_heel := Vector3(0.32, 0.13, 0.96)

	# Main shaft: diagonally forward, not vertical.
	var stick_top := upper_hand + Vector3(
		-0.10, 0.19, -0.07
	)

	add_segment(
		action_rig,
		stick_top,
		stick_heel,
		0.095,
		stick_color
	)

	# Black wrapped grip at the upper portion.
	var grip_end := stick_top.lerp(
		stick_heel,
		0.30
	)

	add_segment(
		action_rig,
		stick_top,
		grip_end,
		0.105,
		grip
	)

	# Hooked head close to the ground.
	var hook_middle := stick_heel + Vector3(
		-0.12, -0.025, 0.06
	)
	var hook_tip := stick_heel + Vector3(
		-0.27, 0.09, 0.09
	)

	add_segment(
		action_rig,
		stick_heel,
		hook_middle,
		0.14,
		stick_color
	)

	add_segment(
		action_rig,
		hook_middle,
		hook_tip,
		0.13,
		stick_color
	)

	add_sphere(
		action_rig,
		hook_tip,
		0.065,
		stick_color
	)

	# Hands are directly positioned on the shaft.
	add_sphere(
		action_rig,
		upper_hand,
		0.13,
		skin
	)
	add_sphere(
		action_rig,
		lower_hand,
		0.13,
		skin
	)

	# Arms connect the shoulders to the hands.
	var left_shoulder := Vector3(-0.45, 1.43, 0.14)
	var right_shoulder := Vector3(0.45, 1.43, 0.14)

	var left_elbow := Vector3(-0.45, 1.17, 0.36)
	var right_elbow := Vector3(0.40, 1.13, 0.44)

	add_segment(
		action_rig,
		left_shoulder,
		left_elbow,
		0.23,
		shirt_color
	)
	add_segment(
		action_rig,
		left_elbow,
		upper_hand,
		0.19,
		skin
	)

	add_segment(
		action_rig,
		right_shoulder,
		right_elbow,
		0.23,
		shirt_color
	)
	add_segment(
		action_rig,
		right_elbow,
		lower_hand,
		0.19,
		skin
	)

	if is_goalkeeper:
		add_keeper_equipment()


func add_keeper_equipment() -> void:
	# Compatibility for a generic goalkeeper model.
	# Your dedicated goalkeeper scene uses its own rig.
	add_box(
		visual_root,
		Vector3(0, 1.20, 0.34),
		Vector3(0.86, 0.76, 0.13),
		Color("#226AA4")
	)


func set_running(running: bool, delta: float) -> void:
	if left_leg_pivot == null or right_leg_pivot == null:
		return

	var target_left: float = 0.0
	var target_right: float = 0.0
	var target_bounce: float = 0.0

	if running:
		run_time += delta * 12.0

		target_left = sin(run_time) * 0.42
		target_right = -sin(run_time) * 0.42

		target_bounce = absf(sin(run_time)) * 0.07

	else:
		run_time = 0.0

	var blend: float = clampf(delta * 12.0, 0.0, 1.0)

	# Opposite leg movement.
	left_leg_pivot.rotation.x = lerpf(
		left_leg_pivot.rotation.x,
		target_left,
		blend
	)

	right_leg_pivot.rotation.x = lerpf(
		right_leg_pivot.rotation.x,
		target_right,
		blend
	)

	# Small body bounce.
	if visual_root != null:
		visual_root.position.y = lerpf(
			visual_root.position.y,
			target_bounce,
			blend
	)
