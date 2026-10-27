
extends Node3D

@export_group("Goal Dimensions")
@export var goal_width: float = 6.0
@export var goal_height: float = 3.0
@export var goal_depth: float = 1.8

@export_group("Appearance")
@export var post_size: float = 0.10
@export var board_height: float = 0.50
@export var net_spacing: float = 0.38
@export var net_thickness: float = 0.018

@export var frame_color: Color = Color("#FFFFFF")
@export var board_color: Color = Color("#263C45")
@export var net_color: Color = Color("#B8D9DF")

var goal_visuals: Node3D


func _ready() -> void:
	build_goal()


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func add_part(
	start: Vector3,
	finish: Vector3,
	thickness: float,
	color: Color
) -> void:
	var direction: Vector3 = finish - start
	var length: float = direction.length()

	if length < 0.001:
		return

	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		thickness,
		length,
		thickness
	)

	instance.mesh = mesh
	instance.position = (start + finish) * 0.5
	instance.quaternion = Quaternion(
		Vector3.UP,
		direction.normalized()
	)
	instance.material_override = make_material(color)

	goal_visuals.add_child(instance)


func add_board(
	pos: Vector3,
	size: Vector3
) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.position = pos
	instance.material_override = make_material(board_color)

	goal_visuals.add_child(instance)


func add_net_line(
	start: Vector3,
	finish: Vector3
) -> void:
	add_part(
		start,
		finish,
		net_thickness,
		net_color
	)


func build_goal() -> void:
	if goal_visuals != null:
		goal_visuals.queue_free()

	goal_visuals = Node3D.new()
	goal_visuals.name = "GoalVisuals"
	add_child(goal_visuals)

	var half_width: float = goal_width * 0.5
	var back_z: float = -goal_depth

	# ----------------------------------------
	# 1. FRONT GOAL FRAME
	# ----------------------------------------

	for side in [-1.0, 1.0]:
		add_part(
			Vector3(side * half_width, 0, 0),
			Vector3(side * half_width, goal_height, 0),
			post_size,
			frame_color
		)

	add_part(
		Vector3(-half_width, goal_height, 0),
		Vector3(half_width, goal_height, 0),
		post_size,
		frame_color
	)

	# ----------------------------------------
	# 2. REAR SUPPORT FRAME
	# ----------------------------------------

	for side in [-1.0, 1.0]:
		var x: float = side * half_width

		# Rear vertical upright
		add_part(
			Vector3(x, 0, back_z),
			Vector3(x, goal_height, back_z),
			post_size * 0.65,
			frame_color
		)

		# Upper bar connecting front and rear
		add_part(
			Vector3(x, goal_height, 0),
			Vector3(x, goal_height, back_z),
			post_size * 0.65,
			frame_color
		)

	# Upper rear cross support
	add_part(
		Vector3(-half_width, goal_height, back_z),
		Vector3(half_width, goal_height, back_z),
		post_size * 0.65,
		frame_color
	)

	# ----------------------------------------
	# 3. BACKBOARD AND SIDEBOARDS
	# ----------------------------------------

	add_board(
		Vector3(0, board_height * 0.5, back_z),
		Vector3(goal_width, board_height, post_size)
	)

	for side in [-1.0, 1.0]:
		add_board(
			Vector3(
				side * half_width,
				board_height * 0.5,
				back_z * 0.5
			),
			Vector3(post_size, board_height, goal_depth)
		)

	# ----------------------------------------
	# 4. BACK NET — GRID
	# ----------------------------------------

	var horizontal_count: int = maxi(
		1,
		ceili(goal_width / net_spacing)
	)

	var vertical_count: int = maxi(
		1,
		ceili((goal_height - board_height) / net_spacing)
	)

	# Vertical mesh strands
	for i in range(horizontal_count + 1):
		var x: float = lerpf(
			-half_width,
			half_width,
			float(i) / float(horizontal_count)
		)

		add_net_line(
			Vector3(x, board_height, back_z),
			Vector3(x, goal_height, back_z)
		)

	# Horizontal mesh strands
	for i in range(vertical_count + 1):
		var y: float = lerpf(
			board_height,
			goal_height,
			float(i) / float(vertical_count)
		)

		add_net_line(
			Vector3(-half_width, y, back_z),
			Vector3(half_width, y, back_z)
		)

	# ----------------------------------------
	# 5. SIDE NETS
	# ----------------------------------------

	var depth_count: int = maxi(
		1,
		ceili(goal_depth / net_spacing)
	)

	for side in [-1.0, 1.0]:
		var x: float = side * half_width

		# Vertical strands along goal depth
		for i in range(depth_count + 1):
			var z: float = lerpf(
				back_z,
				0.0,
				float(i) / float(depth_count)
			)

			add_net_line(
				Vector3(x, board_height, z),
				Vector3(x, goal_height, z)
			)

		# Horizontal strands along the side
		for i in range(vertical_count + 1):
			var y: float = lerpf(
				board_height,
				goal_height,
				float(i) / float(vertical_count)
			)

			add_net_line(
				Vector3(x, y, back_z),
				Vector3(x, y, 0)
			)

	# ----------------------------------------
	# 6. ROOF NET
	# ----------------------------------------

	# Longitudinal net strands
	for i in range(horizontal_count + 1):
		var x: float = lerpf(
			-half_width,
			half_width,
			float(i) / float(horizontal_count)
		)

		add_net_line(
			Vector3(x, goal_height, 0),
			Vector3(x, goal_height, back_z)
		)

	# Transverse net strands
	for i in range(depth_count + 1):
		var z: float = lerpf(
			back_z,
			0.0,
			float(i) / float(depth_count)
		)

		add_net_line(
			Vector3(-half_width, goal_height, z),
			Vector3(half_width, goal_height, z)
		)
