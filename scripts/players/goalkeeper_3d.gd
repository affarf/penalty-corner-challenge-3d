
extends "res://scripts/players/player_3d.gd"

enum SaveState {
	READY,
	QUICK_SAVE,
	DIVING,
	RECOVERING
}

@export_group("Movement")
@export var movement_speed: float = 5.5
@export var movement_acceleration: float = 20.0
@export var movement_deceleration: float = 25.0

@export_group("Goalkeeper Area")
@export var min_x: float = -4.5
@export var max_x: float = 4.5
@export var min_z: float = -16.8
@export var max_z: float = -9.5

@export_group("Save Actions")
@export var dive_distance: float = 2.0
@export var dive_duration: float = 0.30
@export var quick_save_duration: float = 0.30
@export var recovery_duration: float = 0.55

var player_controlled: bool = true
var save_state: SaveState = SaveState.READY

var move_velocity: Vector3 = Vector3.ZERO
var last_move_direction: Vector3 = Vector3.RIGHT
var dive_direction: Vector3 = Vector3.RIGHT

var action_timer: float = 0.0
var dive_origin: Vector3 = Vector3.ZERO
var dive_target: Vector3 = Vector3.ZERO

var camera: Camera3D


func _ready() -> void:
	is_goalkeeper = true
	shirt_color = Color("#258EF5")

	super._ready()

	camera = get_viewport().get_camera_3d()


func _physics_process(delta: float) -> void:
	update_save_state(delta)
	update_save_visuals(delta)

	if not player_controlled:
		move_velocity = Vector3.ZERO
		return

	if save_state != SaveState.READY:
		move_velocity = Vector3.ZERO
		return

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	var world_direction := get_camera_movement(
		input_direction
	)

	if world_direction.length() > 0.1:
		last_move_direction = world_direction

	var desired_velocity := (
		world_direction * movement_speed
	)

	var acceleration := movement_acceleration

	if world_direction.length() < 0.1:
		acceleration = movement_deceleration

	move_velocity = move_velocity.move_toward(
		desired_velocity,
		acceleration * delta
	)

	position += move_velocity * delta
	clamp_position()


func get_camera_movement(
	input_direction: Vector2
) -> Vector3:
	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		return Vector3(
			input_direction.x,
			0.0,
			input_direction.y
		).normalized()

	# Project the camera's right and up directions
	# onto the horizontal XZ playing surface.
	var camera_right := camera.global_transform.basis.x
	var camera_up := camera.global_transform.basis.y

	var right := Vector3(
		camera_right.x,
		0.0,
		camera_right.z
	).normalized()

	var up := Vector3(
		camera_up.x,
		0.0,
		camera_up.z
	).normalized()

	var direction := (
		right * input_direction.x
		- up * input_direction.y
	)

	return direction.normalized()


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return

	if save_state != SaveState.READY:
		return

	if game_mode_is_menu():
		return

	if event is InputEventMouseButton:
		if not event.pressed:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			start_quick_save()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			start_dive()


func game_mode_is_menu() -> bool:
	# Manager disables player control in the menu.
	# Kept as a separate helper for future UI changes.
	return false


func start_quick_save() -> void:
	save_state = SaveState.QUICK_SAVE
	action_timer = quick_save_duration
	move_velocity = Vector3.ZERO


func start_dive() -> void:
	save_state = SaveState.DIVING
	action_timer = 0.0

	dive_origin = position
	dive_direction = last_move_direction.normalized()

	dive_target = (
		position + dive_direction * dive_distance
	)

	dive_target.x = clampf(
		dive_target.x,
		min_x,
		max_x
	)

	dive_target.z = clampf(
		dive_target.z,
		min_z,
		max_z
	)

	move_velocity = Vector3.ZERO


func update_save_state(delta: float) -> void:
	match save_state:
		SaveState.READY:
			pass

		SaveState.QUICK_SAVE:
			action_timer -= delta

			if action_timer <= 0.0:
				start_recovery()

		SaveState.DIVING:
			action_timer += delta

			var t: float = clampf(
				action_timer / maxf(
					dive_duration, 0.01
				),
				0.0,
				1.0
			)

			# Ease out the dive movement.
			var eased_t: float = (
				1.0 - pow(1.0 - t, 2.0)
			)

			position = dive_origin.lerp(
				dive_target,
				eased_t
			)

			clamp_position()

			if t >= 1.0:
				start_recovery()

		SaveState.RECOVERING:
			action_timer -= delta

			if action_timer <= 0.0:
				save_state = SaveState.READY


func update_save_visuals(delta: float) -> void:
	if visual_root == null:
		return

	var target_rotation := Vector3.ZERO
	var target_height: float = 0.0

	match save_state:
		SaveState.DIVING:
			target_rotation.z = (
				-dive_direction.x * 0.85
			)

			target_rotation.x = (
				dive_direction.z * 0.55
			)

			target_height = -0.20

		SaveState.QUICK_SAVE:
			target_rotation.x = -0.30

		SaveState.RECOVERING:
			target_height = -0.12

	var blend: float = minf(
		delta * 12.0,
		1.0
	)

	visual_root.rotation = (
		visual_root.rotation.lerp(
			target_rotation,
			blend
		)
	)

	visual_root.position.y = lerpf(
		visual_root.position.y,
		target_height,
		blend
	)


func clamp_position() -> void:
	position.x = clampf(
		position.x,
		min_x,
		max_x
	)

	position.z = clampf(
		position.z,
		min_z,
		max_z
	)


func start_recovery() -> void:
	save_state = SaveState.RECOVERING
	action_timer = recovery_duration


func get_save_width() -> float:
	match save_state:
		SaveState.QUICK_SAVE:
			return 1.25

		SaveState.DIVING:
			return 1.50

		SaveState.RECOVERING:
			return 0.0

		_:
			return 0.35


func get_save_height() -> float:
	match save_state:
		SaveState.QUICK_SAVE:
			return 1.45

		SaveState.DIVING:
			return 2.35

		SaveState.RECOVERING:
			return 0.0

		_:
			return 0.65


func reset_keeper() -> void:
	save_state = SaveState.READY
	action_timer = 0.0
	move_velocity = Vector3.ZERO

	position = Vector3(0, 0, -15.5)
	last_move_direction = Vector3.RIGHT

	if visual_root != null:
		visual_root.rotation = Vector3.ZERO
		visual_root.position = Vector3.ZERO
