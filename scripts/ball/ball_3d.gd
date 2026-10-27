
extends Node3D
class_name PracticeBall3D

signal movement_finished

@export var ball_radius: float = 0.22
@export var pass_speed: float = 12.0
@export var shot_speed: float = 20.0
@export var aerial_height: float = 2.0
@export var drop_duration: float = 0.35

var ball_mesh: MeshInstance3D
var shadow_mesh: MeshInstance3D

var moving: bool = false
var dropping: bool = false

var travel_time: float = 1.0
var elapsed: float = 0.0

var start_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO

var arc_height: float = 0.0
var impact_height: float = 0.0
var hit_back_net: bool = false


func _ready() -> void:
	build_visuals()


func _process(delta: float) -> void:
	if moving:
		process_flight(delta)
	elif dropping:
		process_drop(delta)


func process_flight(delta: float) -> void:
	elapsed += delta

	var t: float = clampf(
		elapsed / travel_time,
		0.0,
		1.0
	)

	position = start_position.lerp(
		target_position,
		t
	)

	var height: float = 0.0

	if arc_height > 0.0:
		if hit_back_net:
			# Rise and remain airborne into the goal.
			height = arc_height * (
				1.0 - pow(1.0 - t, 3.0)
			)
		else:
			# Shots that miss follow a normal arc.
			height = sin(t * PI) * arc_height

	ball_mesh.position.y = ball_radius + height
	update_shadow(height)

	if t >= 1.0:
		moving = false

		if hit_back_net and arc_height > 0.0:
			# Ball reached the back net.
			impact_height = height
			elapsed = 0.0
			dropping = true
		else:
			finish_movement()


func process_drop(delta: float) -> void:
	elapsed += delta

	var t: float = clampf(
		elapsed / maxf(drop_duration, 0.01),
		0.0,
		1.0
	)

	# Stay at the back of the goal while falling.
	var height: float = impact_height * (
		1.0 - t * t
	)

	ball_mesh.position.y = ball_radius + height
	update_shadow(height)

	if t >= 1.0:
		dropping = false
		finish_movement()


func update_shadow(height: float) -> void:
	if shadow_mesh == null:
		return

	var shadow_factor: float = clampf(
		1.0 - height * 0.18,
		0.4,
		1.0
	)

	shadow_mesh.scale = Vector3.ONE * shadow_factor


func finish_movement() -> void:
	ball_mesh.position.y = ball_radius
	shadow_mesh.scale = Vector3.ONE

	moving = false
	dropping = false

	movement_finished.emit()


func move_to(
	destination: Vector3,
	speed: float,
	height: float = 0.0,
	back_net_impact: bool = false
) -> void:
	start_position = position

	target_position = Vector3(
		destination.x,
		0.0,
		destination.z
	)

	var distance: float = (
		start_position.distance_to(target_position)
	)

	travel_time = maxf(
		distance / maxf(speed, 0.1),
		0.01
	)

	arc_height = height
	hit_back_net = back_net_impact

	elapsed = 0.0
	impact_height = 0.0

	moving = true
	dropping = false


func stop_ball() -> void:
	moving = false
	dropping = false
	elapsed = 0.0
	hit_back_net = false

	# Keep current height until another move or reset.
	if shadow_mesh != null:
		shadow_mesh.scale = Vector3.ONE


func get_ball_height() -> float:
	if ball_mesh == null:
		return ball_radius

	return ball_mesh.position.y


func reset_ball(destination: Vector3) -> void:
	moving = false
	dropping = false
	elapsed = 0.0

	arc_height = 0.0
	impact_height = 0.0
	hit_back_net = false

	position = Vector3(
		destination.x,
		0.0,
		destination.z
	)

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
	shadow_material.albedo_color = Color(
		0.0, 0.0, 0.0, 0.3
	)
	shadow_material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	shadow_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	shadow_mesh.mesh = disk
	shadow_mesh.material_override = shadow_material
	shadow_mesh.position.y = 0.025
	add_child(shadow_mesh)
