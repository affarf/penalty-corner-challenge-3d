
extends RefCounted

var reaction_delay: float = 0.12
var movement_speed: float = 5.0
var tracking_speed: float = 2.2
var prediction_error: float = 0.25

var reaction_timer: float = 0.0
var target_x: float = 0.0
var aerial_shot: bool = false
var decision_made: bool = false
var shot_active: bool = false


func reset() -> void:
	reaction_timer = 0.0
	target_x = 0.0
	aerial_shot = false
	decision_made = false
	shot_active = false


func update_tracking(
	keeper: Node3D,
	ball: Node3D,
	delta: float
) -> void:
	if keeper.stepping_out:
		return

	if keeper.save_state != 0:
		return

	# Track the angle between the ball and the goal.
	# Do not follow the ball all the way to the sideline.
	var dz: float = maxf(
		ball.position.z - keeper.position.z,
		0.5
	)

	var tracking_x: float = (
		ball.position.x * 5.0 / dz
	)

	tracking_x = clampf(
		tracking_x,
		-1.6,
		1.6
	)

	keeper.position.x = move_toward(
		keeper.position.x,
		tracking_x,
		tracking_speed * delta
	)


func start_shot(
	shot_start: Vector3,
	shot_end: Vector3,
	keeper: Node3D,
	is_aerial: bool
) -> void:
	decision_made = false
	shot_active = true
	aerial_shot = is_aerial
	reaction_timer = reaction_delay

	var dz: float = shot_end.z - shot_start.z

	if absf(dz) < 0.001:
		target_x = keeper.position.x
		return

	var t: float = clampf(
		(keeper.position.z - shot_start.z) / dz,
		0.0,
		1.0
	)

	target_x = lerpf(
		shot_start.x,
		shot_end.x,
		t
	)

	# Imperfect prediction keeps the AI beatable.
	target_x += randf_range(
		-prediction_error,
		prediction_error
	)

	target_x = clampf(target_x, -3.0, 3.0)


func update(
	keeper: Node3D,
	ball: Node3D,
	delta: float
) -> void:
	if not shot_active or decision_made:
		return

	if keeper.stepping_out:
		return

	if keeper.save_state != 0:
		return

	if reaction_timer > 0.0:
		reaction_timer -= delta
		return

	var remaining_z: float = (
		ball.position.z - keeper.position.z
	)

	var time_to_contact: float = (
		remaining_z / maxf(ball.shot_speed, 0.1)
	)

	var difference: float = (
		target_x - keeper.position.x
	)

	# Move toward the expected interception position.
	if time_to_contact > 0.26:
		keeper.position.x = move_toward(
			keeper.position.x,
			target_x,
			movement_speed * delta
		)
		return

	if time_to_contact < -0.05:
		decision_made = true
		shot_active = false
		return

	# Commit to the save. No last-second teleporting.
	var direction: float = signf(difference)

	if is_zero_approx(direction):
		direction = 1.0

	keeper.last_move_direction = Vector3(
		direction,
		0.0,
		0.0
	)

	if not aerial_shot and absf(difference) < 0.9:
		keeper.start_quick_save()
	else:
		keeper.start_dive()

	decision_made = true
	shot_active = false
