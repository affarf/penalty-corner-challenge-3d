
extends Node3D

@export var ball_radius: float = 0.22
@export var travel_speed: float = 13.0
@export var launch_height: float = 2.5
@export var travel_distance: float = 12.0

var ball_mesh: MeshInstance3D
var shadow_mesh: MeshInstance3D

var moving: bool = false
var progress: float = 0.0
var start_position: Vector3
var end_position: Vector3


func _ready() -> void:
	build_visuals()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and not moving:
		launch_ball()

	if moving:
		progress += delta * travel_speed / travel_distance
		progress = clampf(progress, 0.0, 1.0)

		var ground_position := start_position.lerp(
			end_position,
			progress
		)

		var height := sin(progress * PI) * launch_height

		position = ground_position
		ball_mesh.position.y = ball_radius + height

		# Shadow remains at ground level.
		shadow_mesh.scale = Vector3.ONE * (
			1.0 - progress * 0.25
		)

		if progress >= 1.0:
			moving = false
			ball_mesh.position.y = ball_radius


func launch_ball() -> void:
	moving = true
	progress = 0.0

	start_position = position
	end_position = start_position + Vector3(0, 0, -travel_distance)


func build_visuals() -> void:
	ball_mesh = MeshInstance3D.new()
	ball_mesh.name = "BallVisual"

	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0

	var white := StandardMaterial3D.new()
	white.albedo_color = Color.WHITE

	ball_mesh.mesh = sphere
	ball_mesh.material_override = white
	ball_mesh.position.y = ball_radius
	add_child(ball_mesh)

	# Shadow
	shadow_mesh = MeshInstance3D.new()
	shadow_mesh.name = "BallShadow"

	var shadow := CylinderMesh.new()
	shadow.top_radius = ball_radius * 1.3
	shadow.bottom_radius = ball_radius * 1.3
	shadow.height = 0.015

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0, 0, 0, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	shadow_mesh.mesh = shadow
	shadow_mesh.material_override = material
	shadow_mesh.position.y = 0.025
	add_child(shadow_mesh)
