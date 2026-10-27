
extends Node3D

@export var shirt_color: Color = Color("#F59D38")
@export var is_goalkeeper: bool = false

var visual_root: Node3D


func _ready() -> void:
	build_player()


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
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

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


func build_player() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visuals"
	add_child(visual_root)

	# Reduce the oversized original model.
	# Total model height is now roughly 1.75 units.
	visual_root.scale = Vector3.ONE * 1

	# Torso
	add_box(
		visual_root,
		Vector3(0, 1.15, 0),
		Vector3(0.8, 1.0, 0.48),
		shirt_color
	)

	# Head / goalkeeper helmet
	var head_color := Color("#E8D9BA")

	if is_goalkeeper:
		head_color = Color("#183E65")

	add_sphere(
		visual_root,
		Vector3(0, 1.92, 0),
		0.32,
		head_color
	)

	# Legs or goalkeeper pads
	var leg_color := Color("#F6F6F6")

	if is_goalkeeper:
		leg_color = Color("#E5AA3B")

	for x in [-0.23, 0.23]:
		add_box(
			visual_root,
			Vector3(x, 0.42, 0),
			Vector3(0.30, 0.75, 0.36),
			leg_color
		)

	# Arms
	for x in [-0.55, 0.55]:
		add_box(
			visual_root,
			Vector3(x, 1.15, 0),
			Vector3(0.25, 0.7, 0.28),
			shirt_color
		)


	# Field hockey stick on the model's right side.
	# The shaft is angled toward the ball.
	var stick_color := Color("#D8BB82")
	var grip_color := Color("#242424")

	var stick_pivot := Node3D.new()
	stick_pivot.name = "HockeyStick"
	stick_pivot.position = Vector3(0.70, 0.92, 0.25)
	stick_pivot.rotation.z = -0.18
	visual_root.add_child(stick_pivot)

	# Shaft
	add_box(
		stick_pivot,
		Vector3(0, -0.43, 0),
		Vector3(0.08, 0.90, 0.09),
		stick_color
	)

	# Upper grip
	add_box(
		stick_pivot,
		Vector3(0, -0.11, 0),
		Vector3(0.095, 0.24, 0.11),
		grip_color
	)

	# Hooked head
	add_box(
		stick_pivot,
		Vector3(-0.15, -0.85, 0),
		Vector3(0.37, 0.13, 0.16),
		stick_color
	)

	# Rounded toe
	add_sphere(
		stick_pivot,
		Vector3(-0.30, -0.85, 0),
		0.075,
		stick_color
	)


	if is_goalkeeper:
		add_keeper_equipment()


func add_keeper_equipment() -> void:
	var pad_color := Color("#E5AA3B")
	var glove_color := Color("#F3C75B")

	# Chest protector
	add_box(
		visual_root,
		Vector3(0, 1.16, 0.27),
		Vector3(0.84, 0.85, 0.18),
		Color("#226AA4")
	)

	# Kickers
	for x in [-0.23, 0.23]:
		add_box(
			visual_root,
			Vector3(x, 0.13, 0.18),
			Vector3(0.38, 0.25, 0.62),
			pad_color
		)

	# Gloves
	add_box(
		visual_root,
		Vector3(-0.59, 0.90, 0.15),
		Vector3(0.32, 0.33, 0.34),
		glove_color
	)

	add_box(
		visual_root,
		Vector3(0.59, 0.90, 0.15),
		Vector3(0.36, 0.36, 0.40),
		glove_color
	)

	# Helmet visor
	add_box(
		visual_root,
		Vector3(0, 1.95, 0.29),
		Vector3(0.42, 0.18, 0.07),
		Color("#111827")
	)
