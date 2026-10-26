
extends Node3D

enum Phase {
	READY,
	PASSING,
	READY_TO_SHOOT,
	SHOOTING,
	FINISHED
}

@export var goal_z: float = -16.0

@onready var ball = get_parent().get_node_or_null("Ball3D")
@onready var attacker1: Node3D = get_parent().get_node("Attacker1")
@onready var attacker2: Node3D = get_parent().get_node("Attacker2")

var phase: Phase = Phase.READY


func _ready() -> void:
	if ball == null:
		push_error("Ball3D is missing or has the wrong script.")
		return

	ball.movement_finished.connect(_on_ball_movement_finished)
	reset_practice()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_E:
			if phase == Phase.READY:
				pass_ball()

		KEY_SPACE:
			if phase == Phase.READY_TO_SHOOT:
				shoot_ball(event.shift_pressed)

		KEY_R:
			reset_practice()


func pass_ball() -> void:
	if ball == null:
		push_error("Ball3D not found! Check scene tree and script.")
		return

	phase = Phase.PASSING

	var destination := attacker2.position + Vector3(0, 0, -0.8)

	ball.move_to(
		destination,
		ball.pass_speed,
		0.0
	)

	print("PASS!")


func shoot_ball(aerial: bool) -> void:
	phase = Phase.SHOOTING

	# Aim toward the center of the goal.
	var destination := Vector3(0, 0, goal_z - 1.0)
	var shot_height := 0.0

	if aerial:
		shot_height = ball.aerial_height

	ball.move_to(
		destination,
		ball.shot_speed,
		shot_height
	)

	if aerial:
		print("AERIAL SHOT!")
	else:
		print("LOW SHOT!")


func _on_ball_movement_finished() -> void:
	match phase:
		Phase.PASSING:
			phase = Phase.READY_TO_SHOOT
			print("PASS COMPLETE! Press SPACE to shoot.")

		Phase.SHOOTING:
			phase = Phase.FINISHED
			print("SHOT COMPLETE! Press R to reset.")


func reset_practice() -> void:
	if ball == null:
		return

	phase = Phase.READY

	# Start the ball slightly in front of Attacker1.
	var start := attacker1.position + Vector3(0, 0, -1.0)
	ball.reset_ball(start)

	print("READY! Press E to pass.")
