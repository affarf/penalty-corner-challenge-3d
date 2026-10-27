
extends Node3D

@export_group("Arena")
@export var field_width: float = 28.0
@export var field_length: float = 27.0
@export var field_center_z: float = -7.0

@export_group("Markings")
@export var goal_z: float = -16.0
@export var circle_radius: float = 10
@export var penalty_spot_z: float = -11

var turf_color := Color("#23815A")
var stripe_color := Color("#1D7553")
var line_color := Color.WHITE


func _ready() -> void:
	build_pitch()


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func add_box(
	parent: Node3D,
	pos: Vector3,
	dimensions: Vector3,
	color: Color
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = make_material(color)

	parent.add_child(instance)
	return instance


func add_line(start: Vector3, end: Vector3) -> void:
	var difference := end - start
	var length := difference.length()

	if length < 0.001:
		return

	var line := add_box(
		self,
		(start + end) * 0.5,
		Vector3(0.085, 0.025, length),
		line_color
	)

	line.rotation.y = atan2(
		difference.x,
		difference.z
	)


func build_pitch() -> void:
	var min_z := field_center_z - field_length * 0.5
	var max_z := field_center_z + field_length * 0.5
	var half_width := field_width * 0.5

	# Turf foundation
	add_box(
		self,
		Vector3(0, -0.13, field_center_z),
		Vector3(field_width, 0.2, field_length),
		Color("#186A4B")
	)

	# Alternating turf stripes
	var stripe_count := 6
	var stripe_length := field_length / float(stripe_count)

	for i in range(stripe_count):
		var z := (
			min_z
			+ stripe_length * (float(i) + 0.5)
		)

		var color := turf_color
		if i % 2 == 0:
			color = stripe_color

		add_box(
			self,
			Vector3(0, -0.018, z),
			Vector3(field_width, 0.02, stripe_length),
			color
		)

	# Outer boundary
	add_line(
		Vector3(-half_width, 0.035, min_z),
		Vector3(half_width, 0.035, min_z)
	)

	add_line(
		Vector3(-half_width, 0.035, max_z),
		Vector3(half_width, 0.035, max_z)
	)

	add_line(
		Vector3(-half_width, 0.035, min_z),
		Vector3(-half_width, 0.035, max_z)
	)

	add_line(
		Vector3(half_width, 0.035, min_z),
		Vector3(half_width, 0.035, max_z)
	)

	# Goal/backline
	add_line(
		Vector3(-half_width, 0.05, goal_z),
		Vector3(half_width, 0.05, goal_z)
	)

	# Simplified D for the prototype
	var segments := 64

	for i in range(segments):
		var a := PI * float(i) / float(segments)
		var b := PI * float(i + 1) / float(segments)

		var start := Vector3(
			cos(a) * circle_radius,
			0.055,
			goal_z + sin(a) * circle_radius
		)

		var end := Vector3(
			cos(b) * circle_radius,
			0.055,
			goal_z + sin(b) * circle_radius
		)

		add_line(start, end)

	# Penalty spot marker
	add_box(
		self,
		Vector3(0, 0.055, penalty_spot_z),
		Vector3(0.18, 0.025, 0.18),
		line_color
	)
