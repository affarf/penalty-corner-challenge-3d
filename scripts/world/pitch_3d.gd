
extends Node3D

const FIELD_WIDTH := 24.0
const FIELD_LENGTH := 38.0
const GOAL_Z := -16.0


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


func add_field_line(start: Vector3, end: Vector3) -> void:
	var difference := end - start
	var middle := (start + end) / 2.0

	var line := add_box(
		self,
		middle,
		Vector3(0.09, 0.025, difference.length()),
		Color.WHITE
	)

	line.rotation.y = atan2(difference.x, difference.z)


func build_pitch() -> void:
	# Main pitch
	add_box(
		self,
		Vector3(0, -0.13, 0),
		Vector3(FIELD_WIDTH, 0.2, FIELD_LENGTH),
		Color("#186A4B")
	)

	# Turf stripes
	for i in range(8):
		var z := -16.625 + float(i) * 4.75
		var stripe_color := Color("#23815A")

		if i % 2 == 0:
			stripe_color = Color("#1D7553")

		add_box(
			self,
			Vector3(0, -0.018, z),
			Vector3(FIELD_WIDTH, 0.02, 4.75),
			stripe_color
		)

	# Field boundaries
	add_field_line(
		Vector3(-12, 0.01, -19),
		Vector3(12, 0.01, -19)
	)

	add_field_line(
		Vector3(-12, 0.01, 19),
		Vector3(12, 0.01, 19)
	)

	add_field_line(
		Vector3(-12, 0.01, -19),
		Vector3(-12, 0.01, 19)
	)

	add_field_line(
		Vector3(12, 0.01, -19),
		Vector3(12, 0.01, 19)
	)

	# Goal backline
	add_field_line(
		Vector3(-12, 0.025, GOAL_Z),
		Vector3(12, 0.025, GOAL_Z)
	)

	# Shooting circle
	var radius := 8.0
	var segments := 48

	for i in range(segments):
		var a: float = PI * float(i) / segments
		var b: float = PI * float(i + 1) / segments

		var start := Vector3(
			cos(a) * radius,
			0.04,
			GOAL_Z + sin(a) * radius
		)

		var end := Vector3(
			cos(b) * radius,
			0.04,
			GOAL_Z + sin(b) * radius
		)

		add_field_line(start, end)

	# Penalty spot
	add_sphere(
		self,
		Vector3(0, 0.05, -12),
		0.14,
		Color.WHITE
	)
