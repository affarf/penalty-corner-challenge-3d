
extends "res://scripts/players/player_3d.gd"

enum SaveState {
	READY,
	QUICK_SAVE,
	DIVING,
	RECOVERING
}

@export var movement_speed: float = 7.0
@export var dive_distance: float = 2.4
@export var dive_duration: float = 0.28
@export var quick_save_duration: float = 0.24
@export var recovery_duration: float = 0.55

@export var min_x: float = -11.0
@export var max_x: float = 11.0
@export var min_z: float = -18.0
@export var max_z: float = 17.0

var player_controlled: bool = true
var save_state: SaveState = SaveState.READY

var last_move_direction: Vector2 = Vector2.RIGHT
var action_timer: float = 0.0

var dive_origin: Vector3
var dive_target: Vector3
var dive_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	is_goalkeeper = true
	shirt_color = Color("#258EF5")
	super._ready()


func _physics_process(delta: float) -> void:
	update_save_state(delta)
	update_save_visuals(delta)

	if not player_controlled:
		return

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if direction.length() > 0.1:
		last_move_direction = direction.normalized()

	if save_state != SaveState.READY:
		return

	position.x += direction.x * movement_speed * delta
	position.z += direction.y * movement_speed * delta

	position.x = clampf(position.x, min_x, max_x)
	position.z = clampf(position.z, min_z, max_z)


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return

	if save_state != SaveState.READY:
		return

	if event is InputEventMouseButton:
		if not event.pressed:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			start_quick_save()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			start_dive()


func start_quick_save() -> void:
	save_state = SaveState.QUICK_SAVE
	action_timer = quick_save_duration


func start_dive() -> void:
	save_state = SaveState.DIVING
	action_timer = 0.0

	dive_origin = position
	dive_direction = last_move_direction

	dive_target = position + Vector3(
		dive_direction.x * dive_distance,
		0.0,
		dive_direction.y * dive_distance
	)

	dive_target.x = clampf(dive_target.x, min_x, max_x)
	dive_target.z = clampf(dive_target.z, min_z, max_z)


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
				action_timer / maxf(dive_duration, 0.01),
				0.0,
				1.0
			)

			position = dive_origin.lerp(
				dive_target,
				t
			)

			if t >= 1.0:
				start_recovery()

		SaveState.RECOVERING:
			action_timer -= delta

			if action_timer <= 0.0:
				save_state = SaveState.READY


func start_recovery() -> void:
	save_state = SaveState.RECOVERING
	action_timer = recovery_duration


func get_save_width() -> float:
	match save_state:
		SaveState.QUICK_SAVE:
			return 1.4
		SaveState.DIVING:
			return 2.0
		SaveState.RECOVERING:
			return 0.0
		_:
			return 0.35


func get_save_height() -> float:
	match save_state:
		SaveState.QUICK_SAVE:
			return 1.5
		SaveState.DIVING:
			return 2.6
		SaveState.RECOVERING:
			return 0.0
		_:
			return 0.8


func reset_keeper() -> void:
	save_state = SaveState.READY
	action_timer = 0.0
	position = Vector3(0, 0, -15.5)
	
	if visual_root != null:
		visual_root.rotation = Vector3.ZERO
	

func update_save_visuals(delta: float) -> void:
	if visual_root == null:
		return

	var target_rotation := Vector3.ZERO

	if save_state == SaveState.DIVING:
		target_rotation.z = -dive_direction.x * 0.65
		target_rotation.x = dive_direction.y * 0.4

	elif save_state == SaveState.QUICK_SAVE:
		target_rotation.x = -0.22

	visual_root.rotation = visual_root.rotation.lerp(
		target_rotation,
		minf(delta * 12.0, 1.0)
	)
