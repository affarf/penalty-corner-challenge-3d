
extends RefCounted

# Basic AI goalkeeper positioning for Attacker Mode.

static func update_keeper(
	keeper: Node3D,
	shot_start: Vector3,
	shot_destination: Vector3,
	movement_speed: float,
	delta: float
) -> void:
	var dz: float = shot_destination.z - shot_start.z

	if absf(dz) < 0.001:
		return

	var t: float = clampf(
		(keeper.position.z - shot_start.z) / dz,
		0.0,
		1.0
	)

	var target_x: float = lerpf(
		shot_start.x,
		shot_destination.x,
		t
	)

	keeper.position.x = move_toward(
		keeper.position.x,
		target_x,
		movement_speed * delta
	)
