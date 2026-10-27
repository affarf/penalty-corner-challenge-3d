
extends Node

signal insertion_finished
signal pass_finished

enum Action {
	NONE,
	INSERTING,
	PASSING
}


var ball: Node3D
var injector: Node3D
var stopper: Node3D
var shooter: Node3D

var current_action: Action = Action.NONE
var injection_speed: float = 11.0


func setup(
	ball_node: Node3D,
	injector_node: Node3D,
	stopper_node: Node3D,
	shooter_node: Node3D
) -> void:
	ball = ball_node
	injector = injector_node
	stopper = stopper_node
	shooter = shooter_node

	injector.hockey_contact.connect(_on_injector_contact)
	stopper.hockey_contact.connect(_on_stopper_contact)
	ball.movement_finished.connect(_on_ball_finished)


func cancel() -> void:
	current_action = Action.NONE


func start_insertion(speed: float) -> void:
	current_action = Action.INSERTING
	injection_speed = speed

	injector.play_hockey_action("inject")


func start_pass() -> void:
	current_action = Action.PASSING
	stopper.play_hockey_action("pass")


func _on_injector_contact(action: String) -> void:
	if current_action != Action.INSERTING:
		return

	if action != "inject":
		return

	var destination: Vector3 = (
		stopper.position + Vector3(0, 0, -0.8)
	)

	ball.move_to(
		destination,
		injection_speed,
		0.0
	)


func _on_stopper_contact(action: String) -> void:
	if current_action != Action.PASSING:
		return

	if action != "pass":
		return

	var destination: Vector3 = (
		shooter.position + Vector3(0, 0, -0.8)
	)

	ball.move_to(
		destination,
		ball.pass_speed,
		0.0
	)


func _on_ball_finished() -> void:
	match current_action:
		Action.INSERTING:
			current_action = Action.NONE

			stopper.play_hockey_action("trap")
			insertion_finished.emit()

		Action.PASSING:
			current_action = Action.NONE
			pass_finished.emit()
