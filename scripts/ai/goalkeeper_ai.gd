
extends RefCounted

var reaction_delay: float = 0.25
var movement_speed: float = 4.5
var decision_made: bool = false
var reaction_timer: float = 0.0

var target_x: float = 0.0
var aerial_shot: bool = false


func reset() -> void:
	decision_made = false
	reaction_timer = reaction_delay
	target_x = 0.0
	aerial_shot = false


func start_shot(
	shot_start: Vector3,
	shot_end: Vector3,
	goalkeeper: Node3D,
	is_aerial: bool
) -> void:
	reset()

	aerial_shot = is_aerial

	var dz: float = shot_end.z - shot_start.z

	if absf(dz) < 0.001:
		target_x = 0.0
		return

	var t: float = clampf(
		(goalkeeper.position.z - shot_start.z) / dz,
		0.0,
		1.0
	)

	target_x = lerpf(shot_start.x, shot_end.x, t)

	# Small prediction error prevents perfect AI.
	target_x += randf_range(-0.35, 0.35)


func update(
	keeper: Node3D,
	ball: Node3D,
	delta: float
) -> void:
	if keeper.save_state != keeper.SaveState.READY:
		return

	if reaction_timer > 0.0:
		reaction_timer -= delta
		return

	if decision_made:
		return

	# Move sideways toward the expected shot.
	var old_x: float = keeper.position.x

	keeper.position.x = move_toward(
		keeper.position.x,
		target_x,
		movement_speed * delta
	)

	var difference: float = target_x - keeper.position.x

	# Calculate how soon the ball reaches the keeper.
	var remaining_z: float = (
		ball.position.z - keeper.position.z
	)

	var ball_speed: float = maxf(ball.shot_speed, 0.1)
	var time_to_contact: float = remaining_z / ball_speed

	if time_to_contact > 0.37:
		return

	if time_to_contact < -0.05:
		decision_made = true
		return

	# Choose a direction for the save.
	var direction: float = signf(target_x - old_x)

	if absf(difference) > 0.1:
		direction = signf(difference)

	if is_zero_approx(direction):
		direction = 1.0

	keeper.last_move_direction = Vector3(
		direction, 0.0, 0.0
	)

	# Close, low shots use the kicker.
	# Wider or aerial shots trigger a dive.
	var lateral_distance: float = absf(
		target_x - keeper.position.x
	)

	if not aerial_shot and lateral_distance < 0.9:
		keeper.start_quick_save()
	else:
		keeper.start_dive()

	decision_made = true
