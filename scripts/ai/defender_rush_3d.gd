
extends Node

@export var rush_speed: float = 6.0
@export var support_speed: float = 4.0

var defenders: Array[Node3D] = []
var starting_positions: Array[Vector3] = []
var target_positions: Array[Vector3] = []
var active: bool = false


func setup(players: Array[Node3D]) -> void:
	defenders = players
	starting_positions.clear()
	target_positions.clear()

	for defender in defenders:
		starting_positions.append(defender.position)
		target_positions.append(defender.position)


func reset_runners() -> void:
	active = false

	for i in range(defenders.size()):
		defenders[i].position = starting_positions[i]


func release() -> void:
	if defenders.size() != 4:
		return

	active = true
	target_positions.clear()

	# Temporary balanced defensive pattern:
	# first runner pressures the stopper,
	# second runner supports,
	# remaining defenders protect the D.

	target_positions.append(
		starting_positions[0]
		+ Vector3(0.0, 0.0, 5.5)
	)

	target_positions.append(
		starting_positions[1]
		+ Vector3(0.0, 0.0, 3.5)
	)

	target_positions.append(
		starting_positions[2]
		+ Vector3(-0.8, 0.0, 1.2)
	)

	target_positions.append(
		starting_positions[3]
		+ Vector3(0.8, 0.0, 1.2)
	)


func stop_runners() -> void:
	active = false


func _physics_process(delta: float) -> void:
	if not active:
		return

	var all_arrived := true

	for i in range(defenders.size()):
		var defender: Node3D = defenders[i]
		var target: Vector3 = target_positions[i]

		var speed: float = support_speed

		if i == 0:
			speed = rush_speed

		defender.position = defender.position.move_toward(
			target,
			speed * delta
		)

		if defender.position.distance_to(target) > 0.05:
			all_arrived = false

	if all_arrived:
		active = false
