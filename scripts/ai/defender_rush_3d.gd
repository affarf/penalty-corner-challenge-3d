
extends Node

signal ball_intercepted

@export_group("Movement")
@export var first_runner_speed: float = 4.5
@export var second_runner_speed: float = 3.8
@export var coverage_speed: float = 2.8

@export_group("Interception")
@export var intercept_radius: float = 0.75
@export var intercept_height: float = 0.60

var defenders: Array[Node3D] = []
var starting_positions: Array[Vector3] = []
var targets: Array[Vector3] = []

var stopper: Node3D
var shooter: Node3D
var ball: Node3D

var goal_z: float = -18.5

var active: bool = false
var interception_enabled: bool = false
var last_ball_position: Vector3 = Vector3.ZERO


func setup(
	players: Array[Node3D],
	stopper_node: Node3D,
	shooter_node: Node3D,
	ball_node: Node3D
) -> void:
	defenders = players
	stopper = stopper_node
	shooter = shooter_node
	ball = ball_node

	starting_positions.clear()
	targets.clear()

	for defender in defenders:
		starting_positions.append(defender.position)
		targets.append(defender.position)

	last_ball_position = ball.position


func reset_runners() -> void:
	active = false
	interception_enabled = false

	for i in range(defenders.size()):
		defenders[i].position = starting_positions[i]
		defenders[i].set_running(false, 1.0)

	if ball != null:
		last_ball_position = ball.position


func release() -> void:
	if defenders.size() != 4:
		return

	active = true
	interception_enabled = true

	# The first runner goes toward the stopper.
	targets[0] = Vector3(
		stopper.position.x,
		0.0,
		maxf(stopper.position.z - 1.2, goal_z + 0.8)
	)

	# Second runner pressures the shooter.
	targets[1] = Vector3(
		shooter.position.x,
		0.0,
		maxf(shooter.position.z - 1.3, goal_z + 0.8)
	)

	# Third defender protects the passing lane.
	targets[2] = Vector3(
		(stopper.position.x + shooter.position.x) * 0.5,
		0.0,
		maxf(
			(stopper.position.z + shooter.position.z) * 0.5 - 2.0,
			goal_z + 1.0
		)
	)

	# Fourth defender stays near the right post.
	targets[3] = Vector3(
		2.4,
		0.0,
		goal_z + 0.8
	)

	last_ball_position = ball.position


func stop_runners() -> void:
	active = false
	interception_enabled = false

	for defender in defenders:
		defender.set_running(false, 0.0)


func _physics_process(delta: float) -> void:
	if not active:
		return

	var all_arrived: bool = true

	for i in range(defenders.size()):
		var defender: Node3D = defenders[i]
		var target: Vector3 = targets[i]

		var speed: float = coverage_speed

		if i == 0:
			speed = first_runner_speed
		elif i == 1:
			speed = second_runner_speed

		var previous_position: Vector3 = defender.position

		defender.position = defender.position.move_toward(
			target,
			speed * delta
		)

		var is_running: bool = (
			defender.position.distance_to(previous_position) > 0.001
		)

		defender.set_running(is_running, delta)

		if defender.position.distance_to(target) > 0.05:
			all_arrived = false

	if interception_enabled:
		check_interception()

	if all_arrived:
		for defender in defenders:
			defender.set_running(false, delta)


func check_interception() -> void:
	if ball == null:
		return

	if not ball.moving:
		last_ball_position = ball.position
		return

	# Only intercept balls near turf level.
	var ball_bottom: float = (
		ball.get_ball_height() - ball.ball_radius
	)

	if ball_bottom > intercept_height:
		last_ball_position = ball.position
		return

	var previous_2d := Vector2(
		last_ball_position.x,
		last_ball_position.z
	)
	var current_2d := Vector2(
		ball.position.x,
		ball.position.z
	)

	for defender in defenders:
		var defender_2d := Vector2(
			defender.position.x,
			defender.position.z
		)

		# Check the full ball segment to reduce missed
		# interceptions when the ball moves quickly.
		var closest: Vector2 = (
			Geometry2D.get_closest_point_to_segment(
				defender_2d,
				previous_2d,
				current_2d
			)
		)

		if defender_2d.distance_to(closest) <= (
			intercept_radius + ball.ball_radius
		):
			active = false
			interception_enabled = false
			ball_intercepted.emit()
			return

	last_ball_position = ball.position

func enable_interceptions() -> void:
	interception_enabled = true
	active = true
	last_ball_position = ball.position
