
extends Node3D

@export var goal_width: float = 6.0
@export var goal_height: float = 3.0
@export var goal_depth: float = 1.8



const POST_SIZE := 0.10
const BOARD_HEIGHT := 0.50


func _ready() -> void:
	build_goal()


func add_part(
	pos: Vector3,
	dimensions: Vector3,
	color: Color
) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	var net := Color(0.63, 0.72, 0.75, 0.22)

	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	add_child(mesh_instance)


func build_goal() -> void:
	var white := Color("#FFFFFF")
	var boards := Color("#263C45")
	var net := Color("#A1B8C0")

	var half_width := goal_width / 2.0

	# Front posts
	for side in [-1.0, 1.0]:
		add_part(
			Vector3(
				side * half_width,
				goal_height / 2.0,
				0
			),
			Vector3(
				POST_SIZE,
				goal_height,
				POST_SIZE
			),
			white
		)

	# Crossbar
	add_part(
		Vector3(0, goal_height, 0),
		Vector3(
			goal_width + POST_SIZE,
			POST_SIZE,
			POST_SIZE
		),
		white
	)

	# Backboard
	add_part(
		Vector3(
			0,
			BOARD_HEIGHT / 2.0,
			-goal_depth
		),
		Vector3(
			goal_width,
			BOARD_HEIGHT,
			POST_SIZE
		),
		boards
	)

	# Sideboards
	for side in [-1.0, 1.0]:
		add_part(
			Vector3(
				side * half_width,
				BOARD_HEIGHT / 2.0,
				-goal_depth / 2.0
			),
			Vector3(
				POST_SIZE,
				BOARD_HEIGHT,
				goal_depth
			),
			boards
		)

	# Placeholder upper net
	add_part(
		Vector3(
			0,
			(goal_height + BOARD_HEIGHT) / 2.0,
			-goal_depth
		),
		Vector3(
			goal_width,
			goal_height - BOARD_HEIGHT,
			0.025
		),
		net
	)
