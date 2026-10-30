extends Node

signal ball_intercepted(contact_position: Vector3)

@export_group("Movement")
@export var first_runner_speed: float = 4.5
@export var second_runner_speed: float = 3.8
@export var coverage_speed: float = 2.8

@export_group("Spacing")
@export var minimum_spacing: float = 1.45
@export var separation_strength: float = 8.0
@export var attacker_buffer: float = 1.35

@export_group("Tackling")
@export var tackle_trigger_radius: float = 3.2
@export var tackle_contact_radius: float = 0.9
@export var intercept_height: float = 0.55
@export var tackle_cooldown: float = 0.75
@export var tackle_animation_time: float = 0.40

@export var stationary_tackle_radius: float = 1.25

var shooter_winding_up: bool = false
var allow_tackles: bool = true
var defenders: Array[Node3D] = []
var starting_positions: Array[Vector3] = []
var targets: Array[Vector3] = []
var stopper: Node3D
var shooter: Node3D
var ball: Node3D
var goalkeeper: Node3D
var goal_z: float = -18.5
var active: bool = false
var interception_enabled: bool = false

var tackle_timers: Array[float] = []
var tackling: Array[bool] = []
var tackle_enabled_for: Array[bool] = []
var tackle_action_timers: Array[float] = []
var tackle_ball_starts: Array[Vector3] = []

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
	tackle_timers.clear()
	tackling.clear()
	tackle_enabled_for.clear()
	tackle_action_timers.clear()
	tackle_ball_starts.clear()

	for i in range(defenders.size()):
		var defender := defenders[i]
		starting_positions.append(defender.position)
		targets.append(defender.position)
		tackle_timers.append(0.0)
		tackling.append(false)
		tackle_enabled_for.append(false)
		tackle_action_timers.append(0.0)
		tackle_ball_starts.append(Vector3.ZERO)

		# Connect one contact callback per defender.
		var callback := _on_tackle_contact.bind(i)
		if not defender.hockey_contact.is_connected(callback):
			defender.hockey_contact.connect(callback)

	reset_runners()

func set_goalkeeper(keeper_node: Node3D) -> void:
	goalkeeper = keeper_node

func reset_runners() -> void:
	shooter_winding_up = false
	active = false
	interception_enabled = false

	for i in range(defenders.size()):
		defenders[i].position = starting_positions[i]
		defenders[i].set_running(false, 1.0)
		defenders[i].cancel_hockey_action()
		targets[i] = starting_positions[i]
		tackle_timers[i] = 0.0
		tackling[i] = false
		tackle_enabled_for[i] = false
		tackle_action_timers[i] = 0.0
		tackle_ball_starts[i] = Vector3.ZERO

func release() -> void:
	if defenders.size() != 4:
		return

	active = true
	interception_enabled = false

	# First runner: pressure stopper.
	targets[0] = Vector3(
		stopper.position.x,
		0.0,
		maxf(stopper.position.z - 1.2, goal_z + 0.8)
	)

	# Second runner: pressure shooter.
	targets[1] = Vector3(
		shooter.position.x,
		0.0,
		maxf(shooter.position.z - 1.3, goal_z + 0.8)
	)

	# Third runner: cover the slip-pass lane.
	targets[2] = Vector3(
		(stopper.position.x + shooter.position.x) * 0.5,
		0.0,
		maxf(
			(stopper.position.z + shooter.position.z) * 0.5 - 2.0,
			goal_z + 1.0
		)
	)

	# Fourth defender: stay near goal.
	# Use their actual starting side, not a forced X.
	targets[3] = Vector3(
		starting_positions[3].x,
		0.0,
		goal_z + 0.8
	)

func enable_interceptions() -> void:
	if not allow_tackles:
		interception_enabled = false
		return

	interception_enabled = true
	active = true

func stop_runners() -> void:
	shooter_winding_up = false
	active = false
	interception_enabled = false

	for i in range(defenders.size()):
		defenders[i].set_running(false, 1.0)
		defenders[i].cancel_hockey_action()
		tackling[i] = false
		tackle_enabled_for[i] = false
		tackle_action_timers[i] = 0.0

func _physics_process(delta: float) -> void:
	if not active:
		return

	for i in range(defenders.size()):
		update_defender(i, delta)

func update_defender(i: int, delta: float) -> void:
	var defender: Node3D = defenders[i]

	tackle_timers[i] = maxf(
		0.0,
		tackle_timers[i] - delta
	)

	# Prevent interrupted animations from locking players.
	if tackling[i]:
		tackle_action_timers[i] -= delta
		defender.set_running(false, delta)

		if tackle_action_timers[i] <= 0.0:
			tackling[i] = false
			tackle_enabled_for[i] = false
			defender.cancel_hockey_action()

		return

	var speed: float = coverage_speed

	if i == 0:
		speed = first_runner_speed
	elif i == 1:
		speed = second_runner_speed

	var previous_position: Vector3 = defender.position

	var desired_direction: Vector3 = (
		targets[i] - defender.position
	)
	desired_direction.y = 0.0

	if desired_direction.length() > 0.05:
		desired_direction = desired_direction.normalized()
	else:
		desired_direction = Vector3.ZERO

	var separation: Vector3 = calculate_separation(
		defender,
		i
	)

	var movement: Vector3 = (
		desired_direction * speed
		+ separation * separation_strength
	)

	movement = movement.limit_length(speed)

	defender.position += movement * delta
	defender.position.y = starting_positions[i].y
	
	defender.position = keep_distance_from_attacker(
	defender.position,
	stopper.position,
	attacker_buffer
	)

	defender.position = keep_distance_from_attacker(
		defender.position,
		shooter.position,
		attacker_buffer
	)
	var moved: float = (
		defender.position.distance_to(previous_position)
	)

	defender.set_running(moved > 0.001, delta)

	if interception_enabled:
		try_tackle(i)

func calculate_separation(
	defender: Node3D,
	self_index: int
) -> Vector3:
	var push := Vector3.ZERO
	var other_players: Array[Node3D] = []

	for j in range(defenders.size()):
		if j != self_index:
			other_players.append(defenders[j])

	# Avoid standing inside attackers or goalkeeper.
	other_players.append(stopper)
	other_players.append(shooter)

	if goalkeeper != null:
		other_players.append(goalkeeper)

	for other in other_players:
		var offset: Vector3 = (
			defender.position - other.position
		)
		offset.y = 0.0
		var distance: float = offset.length()

		if distance < minimum_spacing:
			if distance > 0.001:
				push += (
					offset.normalized()
					* (minimum_spacing - distance)
				)
			else:
				# Deterministic direction for exact overlaps.
				var side: float = (
					-1.0 if self_index % 2 == 0 else 1.0
				)
				push += Vector3(side, 0.0, 0.3)

	return push

func try_tackle(i: int) -> void:
	if not ball.moving and not shooter_winding_up:
		return

	if tackle_timers[i] > 0.0 or tackling[i]:
		return

	var ball_bottom: float = (
		ball.get_ball_height() - ball.ball_radius
	)

	if ball_bottom > intercept_height:
		return

	var defender: Node3D = defenders[i]

	var distance: float = Vector2(
		defender.position.x,
		defender.position.z
	).distance_to(
		Vector2(ball.position.x, ball.position.z)
	)

	var trigger_radius: float = tackle_trigger_radius

	if not ball.moving:
		trigger_radius = stationary_tackle_radius

	if distance > trigger_radius:
		return

	tackling[i] = true
	tackle_enabled_for[i] = true

	tackle_timers[i] = tackle_cooldown
	tackle_action_timers[i] = tackle_animation_time

	# Remember where the ball was when tackling began.
	tackle_ball_starts[i] = ball.position

	defender.set_running(false, 1.0)

	print("Defender ", i + 1, " attempts tackle")

	defender.play_hockey_action("tackle")


func _on_tackle_contact(action: String, i: int) -> void:
	if action != "tackle":
		return

	if not active or not interception_enabled:
		return

	if not tackle_enabled_for[i]:
		return

	tackle_enabled_for[i] = false
	tackling[i] = false
	tackle_action_timers[i] = 0.0

	var stationary_challenge: bool = (
		shooter_winding_up and not ball.moving
	)

	if not ball.moving and not stationary_challenge:
		return

	var ball_bottom: float = (
		ball.get_ball_height() - ball.ball_radius
	)

	if ball_bottom > intercept_height:
		return

	var defender: Node3D = defenders[i]

	var defender_point := Vector2(
		defender.position.x,
		defender.position.z
	)

	var contact_position: Vector3 = ball.position
	var distance: float = 0.0

	if stationary_challenge:
		distance = defender_point.distance_to(
			Vector2(ball.position.x, ball.position.z)
		)
	else:
		var ball_start := Vector2(
			tackle_ball_starts[i].x,
			tackle_ball_starts[i].z
		)

		var ball_end := Vector2(
			ball.position.x,
			ball.position.z
		)

		var closest_point := (
			Geometry2D.get_closest_point_to_segment(
				defender_point,
				ball_start,
				ball_end
			)
		)

		distance = defender_point.distance_to(
			closest_point
		)

		contact_position.x = closest_point.x
		contact_position.z = closest_point.y

	var allowed_radius: float = tackle_contact_radius

	if stationary_challenge:
		allowed_radius = stationary_tackle_radius

	if distance <= allowed_radius:
		print("Defender ", i + 1, " BLOCKED!")

		active = false
		interception_enabled = false
		shooter_winding_up = false

		ball_intercepted.emit(contact_position)
	else:
		print("Defender ", i + 1, " missed tackle")


func set_shooter_windup(active_windup: bool) -> void:
	shooter_winding_up = active_windup

func keep_distance_from_attacker(
	defender_pos: Vector3,
	attacker_pos: Vector3,
	buffer: float
) -> Vector3:
	var offset := defender_pos - attacker_pos
	offset.y = 0.0

	var distance := offset.length()

	if distance < buffer and distance > 0.001:
		return attacker_pos + offset.normalized() * buffer

	return defender_pos
