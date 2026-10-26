
extends RefCounted

# Simple attacking decisions for Keeper Mode.
# Later we can add different routines and difficulty levels.

static func choose_shot() -> Dictionary:
	var possible_targets: Array[float] = [
		-2.2,
		0.0,
		2.2
	]

	var target_x: float = possible_targets.pick_random()
	var aerial: bool = randf() < 0.35

	return {
		"target_x": target_x,
		"aerial": aerial
	}
