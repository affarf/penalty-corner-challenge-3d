

extends Node3D
class_name PracticeBall3D
signal movement_finished

@export var ball_radius: float = 0.22
@export var pass_speed: float = 12.0
@export var shot_speed: float = 20.0
@export var aerial_height: float = 2.0

var ball_mesh: MeshInstance3D
var shadow_mesh: MeshInstance3D

var moving: bool = false
var travel_time: float = 1.0
var elapsed: float = 0.0

var start_position: Vector3
var target_position: Vector3
var arc_height: float = 0.0


func _ready() -> void:
	build_visuals()


func _process(delta: float) -> void:
	if not moving:
		return

	elapsed += delta
	var t: float = clampf(elapsed / travel_time, 0.0, 1.0)

	# Move across the pitch.
	var ground_position := start_position.lerp(target_position, t)
	position = ground_position

	# Aerial shots use a visible arc.
	var height := sin(t * PI) * arc_height
	ball_mesh.position.y = ball_radius + height

	# Shadow stays on the pitch.
	shadow_mesh.scale = Vector3.ONE * (
		1.0 - 0.25 * sin(t * PI)
	)

	if t >= 1.0:
		moving = false
		ball_mesh.position.y = ball_radius
		movement_finished.emit()


func move_to(
	destination: Vector3,
	speed: float,
	height: float = 0.0
) -> void:
	start_position = position
	target_position = Vector3(
		destination.x,
		0.0,
		destination.z
	)

	var distance: float = start_position.distance_to(target_position)
	travel_time = maxf(distance / maxf(speed, 0.1), 0.01)

	arc_height = height
	elapsed = 0.0
	moving = true


func reset_ball(destination: Vector3) -> void:
	moving = false
	elapsed = 0.0
	arc_height = 0.0
	position = Vector3(destination.x, 0.0, destination.z)

	if ball_mesh != null:
		ball_mesh.position.y = ball_radius

	if shadow_mesh != null:
		shadow_mesh.scale = Vector3.ONE


func build_visuals() -> void:
	ball_mesh = MeshInstance3D.new()
	ball_mesh.name = "BallVisual"

	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0

	var white := StandardMaterial3D.new()
	white.albedo_color = Color.WHITE
	white.roughness = 0.7

	ball_mesh.mesh = sphere
	ball_mesh.material_override = white
	ball_mesh.position.y = ball_radius
	add_child(ball_mesh)

	shadow_mesh = MeshInstance3D.new()
	shadow_mesh.name = "BallShadow"

	var disk := CylinderMesh.new()
	disk.top_radius = ball_radius * 1.3
	disk.bottom_radius = ball_radius * 1.3
	disk.height = 0.015

	var shadow_material := StandardMaterial3D.new()
	shadow_material.albedo_color = Color(0, 0, 0, 0.3)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	shadow_mesh.mesh = disk
	shadow_mesh.material_override = shadow_material
	shadow_mesh.position.y = 0.025
	add_child(shadow_mesh)
