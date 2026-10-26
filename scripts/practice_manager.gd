
extends Node3D

enum Phase {
	READY,
	PASSING,
	READY_TO_SHOOT,
	SHOOTING,
	FINISHED
}

enum ShotAim {
	LEFT,
	CENTER,
	RIGHT
}

@export var goal_z: float = -16.0
@export var goal_width: float = 6.0
@export var goal_height: float = 3.0
@export var goal_depth: float = 1.8

@onready var ball = get_parent().get_node("Ball3D")
@onready var attacker1: Node3D = get_parent().get_node("Attacker1")
@onready var attacker2: Node3D = get_parent().get_node("Attacker2")

var phase: Phase = Phase.READY
var shot_aim: ShotAim = ShotAim.CENTER

var shot_start: Vector3
var shot_destination: Vector3
var shot_arc_height: float = 0.0


func _ready() -> void:
	ball.movement_finished.connect(_on_ball_movement_finished)
	reset_practice()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_E:
			if phase == Phase.READY:
				pass_ball()

		KEY_1:
			shot_aim = ShotAim.LEFT
			print("AIM: LEFT")

		KEY_2:
			shot_aim = ShotAim.CENTER
			print("AIM: CENTER")

		KEY_3:
			shot_aim = ShotAim.RIGHT
			print("AIM: RIGHT")

		KEY_SPACE:
			if phase == Phase.READY_TO_SHOOT:
				shoot_ball(event.shift_pressed)

		KEY_R:
			reset_practice()


func pass_ball() -> void:
	if ball.moving:
		return

	phase = Phase.PASSING

	var destination: Vector3 = (
		attacker2.position + Vector3(0, 0, -0.8)
	)

	ball.move_to(
		destination,
		ball.pass_speed,
		0.0
	)

	print("PASS!")


func get_shot_x() -> float:
	match shot_aim:
		ShotAim.LEFT:
			return -2.2

		ShotAim.RIGHT:
			return 2.2

		_:
			return 0.0


func shoot_ball(aerial: bool) -> void:
	if ball.moving:
		return

	phase = Phase.SHOOTING

	shot_start = ball.position

	shot_destination = Vector3(
		get_shot_x(),
		0.0,
		goal_z - goal_depth + 0.1
	)

	shot_arc_height = 0.0

	if aerial:
		shot_arc_height = ball.aerial_height

	ball.move_to(
		shot_destination,
		ball.shot_speed,
		shot_arc_height
	)

	if aerial:
		print("AERIAL SHOT!")
	else:
		print("LOW SHOT!")


func check_goal() -> void:
	# Calculate where the ball crosses the goal line,
	# rather than checking only where it stops.

	var dz: float = shot_destination.z - shot_start.z

	if absf(dz) < 0.001:
		print("MISS! Invalid shot direction.")
		return

	var t: float = (
		(goal_z - shot_start.z) / dz
	)

	if t < 0.0 or t > 1.0:
		print("MISS! Ball did not cross the goal line.")
		return

	var crossing_x: float = lerpf(
		shot_start.x,
		shot_destination.x,
		t
	)
	var crossing_height: float = ball.ball_radius

	if shot_arc_height > 0.0:
		crossing_height += shot_arc_height * (
			1.0 - pow(1.0 - t, 3.0)
		)

	var inside_posts: bool = (
		absf(crossing_x) + ball.ball_radius
		< goal_width / 2.0
	)

	var below_crossbar: bool = (
		crossing_height + ball.ball_radius
		< goal_height
	)

	if inside_posts and below_crossbar:
		print("GOAL!")
		print("Crossing X: ", snappedf(crossing_x, 0.01))
		print("Ball height: ", snappedf(crossing_height, 0.01))
	else:
		print("MISS!")

		if not inside_posts:
			print("Shot went wide.")

		if not below_crossbar:
			print("Shot went over the crossbar.")


func _on_ball_movement_finished() -> void:
	match phase:
		Phase.PASSING:
			phase = Phase.READY_TO_SHOOT
			print("PASS COMPLETE!")
			print("Choose 1, 2, or 3, then shoot.")

		Phase.SHOOTING:
			check_goal()
			phase = Phase.FINISHED
			print("Press R to try again.")


func reset_practice() -> void:
	phase = Phase.READY
	shot_aim = ShotAim.CENTER
	shot_arc_height = 0.0

	var start: Vector3 = (
		attacker1.position + Vector3(0, 0, -1.0)
	)

	ball.reset_ball(start)

	print("-------------------------")
	print("PRACTICE READY")
	print("E = Pass")
	print("1 / 2 / 3 = Aim")
	print("SPACE = Shoot")
	print("SHIFT + SPACE = Aerial")
	print("R = Reset")
