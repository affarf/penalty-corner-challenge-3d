
extends Node3D

const FIELD_WIDTH := 24.0
const FIELD_LENGTH := 38.0
const GOAL_Z := -16.0

const GOAL_WIDTH := 3.66
const GOAL_HEIGHT := 2.14
const GOAL_DEPTH := 1.20
const POST_THICKNESS := 0.08
const BOARD_HEIGHT := 0.46
const BOARD_THICKNESS := 0.06

var goalkeeper: Node3D


func _ready() -> void:
	build_pitch()

	goalkeeper = create_player(
		Vector3(0, 0, -16.5),
		Color("#258EF5"),
		true
	)

	create_player(
		Vector3(0, 0, 8),
		Color("#F59D38"),
		false
	)

	create_player(
		Vector3(6, 0, 7),
		Color("#F59D38"),
		false
	)

	add_sphere(
		self,
		Vector3(0, 0.22, 6),
		0.22,
		Color.WHITE
	)

	build_camera_and_light()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	if goalkeeper == null:
		return

	# X and Z are the horizontal pitch coordinates.
	goalkeeper.position.x += direction.x * 9.0 * delta
	goalkeeper.position.z += direction.y * 9.0 * delta

	goalkeeper.position.x = clampf(
		goalkeeper.position.x, -11.0, 11.0
	)

	goalkeeper.position.z = clampf(
		goalkeeper.position.z, -18.0, 17.0
	)


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
	# Pitch base
	add_box(
		self,
		Vector3(0, -0.13, 0),
		Vector3(FIELD_WIDTH, 0.2, FIELD_LENGTH),
		Color("#186A4B")
	)

	# Alternating turf stripes
	for i in range(8):
		var z := -16.625 + float(i) * 4.75
		var stripe_color := Color("#23815A")

		if i % 2 == 0:
			stripe_color = Color("#1D7553")

		add_box(
			self,
			Vector3(0, -0.018, z),
			Vector3(24.0, 0.02, 4.75),
			stripe_color
		)

	# Field markings
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

	# Backline
	add_field_line(
		Vector3(-12, 0.025, GOAL_Z),
		Vector3(12, 0.025, GOAL_Z)
	)

	# Simplified shooting-circle arc
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
		Vector3(0, 0.050, -12),
		0.14,
		Color.WHITE
	)




func create_player(
	start: Vector3,
	shirt_color: Color,
	is_keeper: bool
) -> Node3D:
	var player := Node3D.new()
	add_child(player)
	player.position = start

	# Body
	add_box(
		player,
		Vector3(0, 1.15, 0),
		Vector3(0.8, 1.0, 0.48),
		shirt_color
	)

	# Head / helmet
	var head_color := Color("#E8D9BA")

	if is_keeper:
		head_color = Color("#183E65")

	add_sphere(
		player,
		Vector3(0, 1.92, 0),
		0.32,
		head_color
	)

	# Legs / pads
	var leg_color := Color("#F6F6F6")

	if is_keeper:
		leg_color = Color("#E5AA3B")

	for x in [-0.23, 0.23]:
		add_box(
			player,
			Vector3(x, 0.4, 0),
			Vector3(0.3, 0.75, 0.35),
			leg_color
		)

	# Arms
	for x in [-0.55, 0.55]:
		add_box(
			player,
			Vector3(x, 1.15, 0),
			Vector3(0.25, 0.7, 0.28),
			shirt_color
		)

	# Hockey stick shaft
	add_box(
		player,
		Vector3(-0.85, 0.65, 0.20),
		Vector3(0.09, 1.3, 0.09),
		Color("#D8BB82")
	)

	# Hockey stick head / toe
	add_box(
		player,
		Vector3(-0.70, 0.12, 0.20),
		Vector3(0.40, 0.13, 0.11),
		Color("#D8BB82")
	)

	return player


func build_camera_and_light() -> void:
	var camera := Camera3D.new()
	add_child(camera)

	camera.position = Vector3(27, 32, 34)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 35.0
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	camera.current = true

	var sun := DirectionalLight3D.new()
	add_child(sun)

	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true

	var environment := WorldEnvironment.new()
	add_child(environment)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8DBED3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.65

	environment.environment = env
