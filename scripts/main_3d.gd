
extends Node3D


func _ready() -> void:
	build_camera_and_light()

func build_camera_and_light() -> void:
	var camera := Camera3D.new()
	camera.name = "GameCamera"
	add_child(camera)

	var focus := Vector3(0, 0, -7.5)

	camera.position = focus + Vector3(27, 32, 34)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29
	camera.look_at(focus, Vector3.UP)
	camera.current = true

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	add_child(sun)

	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true

	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	add_child(world_environment)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8DBED3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.65

	world_environment.environment = env
