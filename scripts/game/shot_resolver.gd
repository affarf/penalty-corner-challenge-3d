
extends RefCounted

static func check_goal(
	shot_start: Vector3,
	shot_destination: Vector3,
	shot_height: float,
	ball_radius: float,
	goal_z: float,
	goal_width: float,
	goal_height: float
) -> String:
	var dz: float = (
		shot_destination.z - shot_start.z
	)

	if absf(dz) < 0.001:
		return "MISS!"

	var t: float = (
		(goal_z - shot_start.z) / dz
	)

	if t < 0.0 or t > 1.0:
		return "MISS!"

	var crossing_x: float = lerpf(
		shot_start.x,
		shot_destination.x,
		t
	)

	var crossing_height: float = ball_radius

	if shot_height > 0.0:
		crossing_height += shot_height * (
			1.0 - pow(1.0 - t, 3.0)
		)

	var inside_posts: bool = (
		absf(crossing_x) + ball_radius
		< goal_width / 2.0
	)

	var below_crossbar: bool = (
		crossing_height + ball_radius
		< goal_height
	)

	if inside_posts and below_crossbar:
		return "GOAL!"

	return "MISS!"


static func can_keeper_save(
	ball: Node3D,
	keeper: Node3D,
	goal_z: float,
	save_depth: float
) -> bool:
	var ball_pos: Vector3 = ball.position
	var keeper_pos: Vector3 = keeper.position

	if ball_pos.z + ball.ball_radius < goal_z:
		return false

	var save_width: float = keeper.get_save_width()
	var save_height: float = keeper.get_save_height()

	if save_width <= 0.0 or save_height <= 0.0:
		return false

	var close_x: bool = (
		absf(ball_pos.x - keeper_pos.x)
		<= save_width + ball.ball_radius
	)

	var close_z: bool = (
		absf(ball_pos.z - keeper_pos.z)
		<= save_depth + ball.ball_radius
	)

	var ball_bottom: float = (
		ball.get_ball_height() - ball.ball_radius
	)

	return (
		close_x
		and close_z
		and ball_bottom <= save_height
	)


static func clearance_destination(
	ball_position: Vector3,
	keeper_position: Vector3
) -> Vector3:
	var side: float = 1.0

	if ball_position.x < keeper_position.x:
		side = -1.0

	return Vector3(
		clampf(
			ball_position.x + side * 3.0,
			-10.5,
			10.5
		),
		0.0,
		clampf(
			ball_position.z + 5.0,
			-18.0,
			18.0
		)
	)
