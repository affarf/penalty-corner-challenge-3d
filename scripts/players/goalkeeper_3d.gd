
extends "res://scripts/players/player_3d.gd"

@export var movement_speed: float = 9.0
@export var min_x: float = -11.0
@export var max_x: float = 11.0
@export var min_z: float = -18.0
@export var max_z: float = 17.0

var player_controlled: bool = true


func _ready() -> void:
	is_goalkeeper = true
	shirt_color = Color("#258EF5")
	super._ready()


func _physics_process(delta: float) -> void:
	if not player_controlled:
		return

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	position.x += direction.x * movement_speed * delta
	position.z += direction.y * movement_speed * delta

	position.x = clampf(position.x, min_x, max_x)
	position.z = clampf(position.z, min_z, max_z)
