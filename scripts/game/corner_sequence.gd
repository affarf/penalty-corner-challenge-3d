
extends Node

signal status_changed(message: String)
signal corner_finished(result: String)

const AttackerAI = preload(
	"res://scripts/ai/attacker_ai.gd"
)
const GoalkeeperAI = preload(
	"res://scripts/ai/goalkeeper_ai.gd"
)
const ShotResolver = preload(
	"res://scripts/game/shot_resolver.gd"
)
signal injection_released
signal pass_released
signal shooter_windup_changed(is_winding_up: bool)

enum Phase {
	IDLE,
	INSERTING,
	READY_TO_PASS,
	PASSING,
	READY_TO_SHOOT,
	SHOOTING,
	FINISHED
}

var phase: Phase = Phase.IDLE
var automatic_attack: bool = false
var ai_keeper_enabled: bool = false

var ball: Node3D
var injector: Node3D
var stopper: Node3D
var shooter: Node3D
var goalkeeper: Node3D
var defenders: Array[Node3D] = []

var goalkeeper_ai = GoalkeeperAI.new()

var goal_z: float = -18.5
var goal_width: float = 6.0
var goal_height: float = 3.0
var goal_depth: float = 1.8

var injection_position := Vector3(-8.0, 0, -18.5)
var injection_speed: float = 11.0
var save_depth: float = 0.9

var ai_pass_delay: float = 0.6
var ai_shot_delay: float = 1.0

var aim_x: float = 0.0
var shot_start := Vector3.ZERO
var shot_destination := Vector3.ZERO
var shot_height: float = 0.0

var action_timer: float = 0.0


func setup(
	ball_node,
	injector_node,
	stopper_node,
	shooter_node,
	keeper_node
) -> void:
	ball = ball_node
	injector = injector_node
	stopper = stopper_node
	shooter = shooter_node
	goalkeeper = keeper_node
	
	shooter.hockey_contact.connect(_on_shooter_contact)
	injector.hockey_contact.connect(_on_injector_contact)
	stopper.hockey_contact.connect(_on_stopper_contact)
	ball.movement_finished.connect(_on_ball_finished)



func _process(delta: float) -> void:
	if phase == Phase.IDLE or phase == Phase.FINISHED:
		return

	# AI goalkeeper tracks the attack.
	if ai_keeper_enabled:
		if phase in [
			Phase.INSERTING,
			Phase.READY_TO_PASS,
			Phase.PASSING,
			Phase.READY_TO_SHOOT
		]:
			goalkeeper_ai.update_tracking(
				goalkeeper,
				ball,
				delta
			)

	# AI goalkeeper reacts when the actual shot starts.
	if phase == Phase.SHOOTING and ball.moving:
		if ai_keeper_enabled:
			goalkeeper_ai.update(
				goalkeeper,
				ball,
				delta
			)

		check_save()

	# Automatic attackers handle passing and shooting.
	if action_timer > 0.0:
		action_timer -= delta

		if action_timer <= 0.0:
			action_timer = 0.0
			run_automatic_action()




func start_corner(
	auto_attack: bool,
	use_ai_keeper: bool = false
) -> void:
	cancel()

	automatic_attack = auto_attack
	ai_keeper_enabled = use_ai_keeper

	aim_x = 0.0
	shot_height = 0.0

	goalkeeper_ai.reset()
	goalkeeper.reset_keeper()

	# In AI Mode, nobody controls the goalkeeper.
	# In Keeper Mode, the human controls it.
	goalkeeper.player_controlled = not ai_keeper_enabled

	ball.reset_ball(injection_position)

	phase = Phase.INSERTING
	goalkeeper.release_from_line()

	status_changed.emit("INJECTION!")
	injector.play_hockey_action("inject")



func cancel() -> void:
	phase = Phase.IDLE
	action_timer = 0.0
	goalkeeper_ai.reset()

	if ball != null:
		ball.stop_ball()
		
	shooter_windup_changed.emit(false)


func request_pass() -> void:
	if phase != Phase.READY_TO_PASS:
		return

	phase = Phase.PASSING
	status_changed.emit("SLIP PASS!")

	stopper.play_hockey_action("pass")


func set_aim(value: float) -> void:
	aim_x = value

	if phase == Phase.READY_TO_SHOOT:
		status_changed.emit(
			"AIM: " + str(snappedf(aim_x, 0.1))
		)



func request_shot(aerial: bool) -> void:
	if phase != Phase.READY_TO_SHOOT:
		return

	phase = Phase.SHOOTING
	shooter_windup_changed.emit(true)

	shot_height = (
		ball.aerial_height if aerial else 0.0
	)

	status_changed.emit(
		"DRAG FLICK WINDUP!"
		if aerial else "SHOT WINDUP!"
	)

	# Animate first. The ball moves on contact.
	shooter.play_hockey_action("shoot")



func run_automatic_action() -> void:
	if not automatic_attack:
		return

	match phase:
		Phase.READY_TO_PASS:
			request_pass()

		Phase.READY_TO_SHOOT:
			var choice: Dictionary = AttackerAI.choose_shot()

			aim_x = float(choice["target_x"])
			request_shot(bool(choice["aerial"]))


func _on_injector_contact(action: String) -> void:
	if phase != Phase.INSERTING:
		return

	if action != "inject":
		return

	var destination: Vector3 = (
		stopper.position + Vector3(0, 0, -0.8)
	)

	ball.move_to(
		destination,
		19,
		0.0
	)
	
	injection_released.emit()


func _on_stopper_contact(action: String) -> void:
	if phase != Phase.PASSING:
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
	pass_released.emit()


func _on_ball_finished() -> void:
	match phase:
		Phase.INSERTING:
			phase = Phase.READY_TO_PASS

			stopper.play_hockey_action("trap")

			if automatic_attack:
				status_changed.emit("TRAPPED! Preparing pass.")
				action_timer = ai_pass_delay
			else:
				status_changed.emit(
					"Trap complete! Press E to pass."
				)

		Phase.PASSING:
			phase = Phase.READY_TO_SHOOT

			if automatic_attack:
				status_changed.emit("Incoming shot!")
				action_timer = ai_shot_delay
			else:
				status_changed.emit(
					"1/2/3 = Aim\n"
					+ "SPACE = Low shot\n"
					+ "SHIFT + SPACE = Aerial"
				)

		Phase.SHOOTING:
			var result: String = ShotResolver.check_goal(
				shot_start,
				shot_destination,
				shot_height,
				ball.ball_radius,
				goal_z,
				goal_width,
				goal_height
			)

			complete_corner(result)


func check_save() -> void:
	var saved: bool = ShotResolver.can_keeper_save(
		ball,
		goalkeeper,
		goal_z,
		save_depth
	)

	if not saved:
		return

	var clearance: Vector3 = (
		ShotResolver.clearance_destination(
			ball.position,
			goalkeeper.position
		)
	)

	ball.stop_ball()
	phase = Phase.FINISHED

	ball.move_to(
		clearance,
		ball.pass_speed * 0.85,
		0.0
	)

	corner_finished.emit("SAVE!")


func complete_corner(result: String) -> void:
	if phase == Phase.FINISHED:
		return

	phase = Phase.FINISHED
	action_timer = 0.0
	corner_finished.emit(result)


func _on_shooter_contact(action: String) -> void:
	if action != "shoot":
		return

	if phase != Phase.SHOOTING:
		return

	shooter_windup_changed.emit(false)

	# Prevent another contact from launching a second shot.
	if ball.moving:
		return
	
	if shooter_is_under_pressure():
		block_shot_before_release()
		return

	shot_start = ball.position

	var back_z: float = (
		goal_z
		- goal_depth
		+ ball.ball_radius
		+ 0.05
	)

	shot_destination = Vector3(
		aim_x,
		0.0,
		back_z
	)

	var expected_result: String = ShotResolver.check_goal(
		shot_start,
		shot_destination,
		shot_height,
		ball.ball_radius,
		goal_z,
		goal_width,
		goal_height
	)

	ball.move_to(
		shot_destination,
		ball.shot_speed,
		shot_height,
		expected_result == "GOAL!"
	)

	if ai_keeper_enabled:
		goalkeeper_ai.start_shot(
			shot_start,
			shot_destination,
			goalkeeper,
			shot_height > 0.0
		)

	status_changed.emit(
		"AERIAL SHOT!"
		if shot_height > 0.0 else "LOW SHOT!"
	)




func handle_defender_interception(
	contact_position: Vector3
) -> void:
	if phase != Phase.PASSING and phase != Phase.SHOOTING:
		return

	# During a shot windup, the ball isn't moving yet.
	var blocked_pass: bool = (phase == Phase.PASSING)

	# End the corner before starting the rebound.
	phase = Phase.FINISHED
	action_timer = 0.0
	shooter_windup_changed.emit(false)

	ball.stop_ball()

	# Move the ball to the approximate tackle contact point.
	contact_position.y = 0.0
	ball.position = contact_position

	# Send the ball away from the goal.
	# Positive Z points toward the pitch.
	var side: float = (
		-1.0 if contact_position.x > 0.0 else 1.0
	)

	var rebound_direction := Vector3(
		side * 0.7,
		0.0,
		1.0
	).normalized()

	var rebound_target: Vector3 = (
		contact_position + rebound_direction * 3.2
	)

	# The rebound is a new movement, not the original pass.
	ball.move_to(
		rebound_target,
		9.0,
		0.0
	)

	if blocked_pass:
		corner_finished.emit("INTERCEPTED!")
	else:
		corner_finished.emit("BLOCK!")

func set_defenders(players: Array[Node3D]) -> void:
	defenders = players

func shooter_is_under_pressure() -> bool:
	for defender in defenders:
		var distance := Vector2(
			defender.position.x,
			defender.position.z
		).distance_to(
			Vector2(
				shooter.position.x,
				shooter.position.z
			)
		)

		if distance <= 1.35:
			return true

	return false
	

func block_shot_before_release() -> void:
	var contact_position: Vector3 = ball.position

	var side: float = 1.0
	if contact_position.x > shooter.position.x:
		side = -1.0

	var rebound_direction: Vector3 = Vector3(
		side * 0.7,
		0.0,
		1.0
	).normalized()

	var rebound_target: Vector3 = (
		contact_position + rebound_direction * 3.2
	)

	rebound_target.x = clampf(
		rebound_target.x, -11.0, 11.0
	)
	rebound_target.z = clampf(
		rebound_target.z, -18.0, 5.0
	)

	phase = Phase.FINISHED
	action_timer = 0.0
	shooter_windup_changed.emit(false)

	ball.stop_ball()

	ball.move_to(
		rebound_target,
		10.0,
		0.0
	)

	corner_finished.emit("BLOCK!")
