
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

	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	add_child(mesh_instance)


func build_goal() -> void:
	var white := Color("#F2F5F5")
	var boards := Color("#D1E0E2")
	var net := Color("#8BAEAE")

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
