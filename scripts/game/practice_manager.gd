
extends Node3D

const AttackerAI = preload(
	"res://scripts/ai/attacker_ai.gd"
)
const GoalkeeperAI = preload(
	"res://scripts/ai/goalkeeper_ai.gd"
)
const ShotResolver = preload(
	"res://scripts/game/shot_resolver.gd"
)
const PracticeHUD = preload(
	"res://scripts/game/practice_hud.gd"
)

const CornerSequence = preload(
	"res://scripts/game/corner_sequence.gd"
)
enum GameMode {
	MENU,
	KEEPER,
	ATTACKER
}

enum Phase {
	READY,
	INSERTING,
	READY_TO_PASS,
	PASSING,
	READY_TO_SHOOT,
	SHOOTING,
	FINISHED
}

@onready var goal = get_parent().get_node("Goal3D")

@export_group("Goal")
@export var goal_z: float = -18.5
@export var goal_width: float = 6.0
@export var goal_height: float = 3.0
@export var goal_depth: float = 1.8

@export_group("Insertion")
@export var injection_x: float = -8.0
@export var injection_z: float = -18.5
@export var injection_speed: float = 11.0

@export_group("Saves")
@export var keeper_save_depth: float = 0.9

@export_group("Timing")
@export var ai_pass_delay: float = 0.5
@export var ai_shot_delay: float = 1.0
@export var round_end_delay: float = 2.0

@onready var ball = (
	get_parent().get_node("Ball3D")
)
@onready var attacker1: Node3D = (
	get_parent().get_node("Attacker1")
)
@onready var attacker2: Node3D = (
	get_parent().get_node("Attacker2")
)
@onready var goalkeeper = (
	get_parent().get_node("Goalkeeper3D")
)

@onready var injector = (
	get_parent().get_node("Injector")
)

var goalkeeper_ai = GoalkeeperAI.new()
var hud
var corner_sequence
var game_mode: GameMode = GameMode.MENU
var phase: Phase = Phase.READY

var aim_x: float = 0.0
var shot_start: Vector3 = Vector3.ZERO
var shot_destination: Vector3 = Vector3.ZERO
var shot_height: float = 0.0

var round_number: int = 0
var goals: int = 0
var saves: int = 0
var misses: int = 0

var countdown: float = 0.0
var status_message: String = ""

func sync_goal_dimensions() -> void:
	goal_z = goal.global_position.z
	goal_width = goal.goal_width * goal.scale.x
	goal_height = goal.goal_height * goal.scale.y
	goal_depth = goal.goal_depth * goal.scale.z
	

func _ready() -> void:
	sync_goal_dimensions()

	hud = PracticeHUD.new()
	hud.name = "PracticeHUD"
	add_child(hud)

	corner_sequence = CornerSequence.new()
	corner_sequence.name = "CornerSequence"
	add_child(corner_sequence)

	corner_sequence.setup(
		ball,
		injector,
		attacker1,
		attacker2
	)

	corner_sequence.insertion_finished.connect(
		_on_insertion_finished
	)

	corner_sequence.pass_finished.connect(
		_on_pass_finished
	)

	ball.movement_finished.connect(_on_ball_finished)

	show_menu()


func _process(delta: float) -> void:
	if game_mode == GameMode.MENU:
		return

	# AI goalkeeper watches the ball before a shot.
	if game_mode == GameMode.ATTACKER:
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

	if phase == Phase.SHOOTING and ball.moving:
		if game_mode == GameMode.ATTACKER:
			goalkeeper_ai.update(
				goalkeeper,
				ball,
				delta
			)

		check_keeper_save()

	if countdown > 0.0:
		countdown -= delta

		if countdown <= 0.0:
			countdown = 0.0
			advance_timer()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return

	if event.keycode == KEY_ESCAPE:
		show_menu()
		return

	if game_mode == GameMode.MENU:
		match event.keycode:
			KEY_1:
				start_mode(GameMode.KEEPER)
			KEY_2:
				start_mode(GameMode.ATTACKER)
		return

	if event.keycode == KEY_R:
		begin_round()
		return

	if game_mode != GameMode.ATTACKER:
		return

	match event.keycode:
		KEY_E:
			if phase == Phase.READY_TO_PASS:
				pass_ball()

		KEY_1:
			aim_x = -2.2
			set_status("AIM: LEFT")

		KEY_2:
			aim_x = 0.0
			set_status("AIM: CENTER")

		KEY_3:
			aim_x = 2.2
			set_status("AIM: RIGHT")

		KEY_SPACE:
			if phase == Phase.READY_TO_SHOOT:
				shoot_ball(event.shift_pressed)


func start_mode(selected_mode: GameMode) -> void:
	game_mode = selected_mode

	round_number = 0
	goals = 0
	saves = 0
	misses = 0

	goalkeeper.player_controlled = (
		game_mode == GameMode.KEEPER
	)

	begin_round()


func show_menu() -> void:
	corner_sequence.cancel()
	game_mode = GameMode.MENU
	phase = Phase.READY
	countdown = 0.0

	ball.stop_ball()
	goalkeeper.player_controlled = false
	goalkeeper.reset_keeper()
	goalkeeper_ai.reset()

	set_status(
		"PENALTY CORNER CHALLENGE 3D\n\n"
		+ "1 - KEEPER MODE\n"
		+ "2 - ATTACKER MODE\n\n"
		+ "Choose a mode."
	)
	


func begin_round() -> void:
	corner_sequence.cancel()
	if game_mode == GameMode.MENU:
		return

	round_number += 1
	phase = Phase.READY
	countdown = 0.0

	aim_x = 0.0
	shot_height = 0.0

	goalkeeper.reset_keeper()
	goalkeeper_ai.reset()

	goalkeeper.player_controlled = (
		game_mode == GameMode.KEEPER
	)

	# Actual backline injection starting position.
	ball.reset_ball(
		Vector3(injection_x, 0, injection_z)
	)

	start_insertion()


func start_insertion() -> void:
	phase = Phase.INSERTING
	goalkeeper.release_from_line()

	set_status("INJECTION!")

	corner_sequence.start_insertion(injection_speed)


func advance_timer() -> void:
	if game_mode == GameMode.MENU:
		return

	match phase:
		Phase.READY_TO_PASS:
			if game_mode == GameMode.KEEPER:
				pass_ball()

		Phase.READY_TO_SHOOT:
			if game_mode == GameMode.KEEPER:
				var shot: Dictionary = (
					AttackerAI.choose_shot()
				)

				aim_x = float(shot["target_x"])

				shoot_ball(
					bool(shot["aerial"])
				)

		Phase.FINISHED:
			begin_round()


func pass_ball() -> void:
	if phase != Phase.READY_TO_PASS:
		return

	phase = Phase.PASSING
	set_status("SLIP PASS!")

	corner_sequence.start_pass()



func shoot_ball(aerial: bool) -> void:
	if phase != Phase.READY_TO_SHOOT:
		return

	phase = Phase.SHOOTING
	shot_start = ball.position

	# Inside the goal, just before the backboard.
	var back_goal_z: float = (
		goal_z
		- goal_depth
		+ ball.ball_radius
		+ 0.05
	)

	shot_destination = Vector3(
		aim_x,
		0.0,
		back_goal_z
	)

	shot_height = 0.0

	if aerial:
		shot_height = ball.aerial_height

	# Check whether the intended shot enters
	# between the posts and under the crossbar.
	var expected_result: String = (
		ShotResolver.check_goal(
			shot_start,
			shot_destination,
			shot_height,
			ball.ball_radius,
			goal_z,
			goal_width,
			goal_height
		)
	)

	var will_hit_back_net: bool = (
		expected_result == "GOAL!"
	)

	ball.move_to(
		shot_destination,
		ball.shot_speed,
		shot_height,
		will_hit_back_net
	)

	if game_mode == GameMode.ATTACKER:
		goalkeeper_ai.start_shot(
			shot_start,
			shot_destination,
			goalkeeper,
			aerial
		)

	set_status(
		"AERIAL SHOT!" if aerial else "LOW SHOT!"
	)



func check_keeper_save() -> void:
	var saved: bool = ShotResolver.can_keeper_save(
		ball,
		goalkeeper,
		goal_z,
		keeper_save_depth
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

	ball.move_to(
		clearance,
		ball.pass_speed * 0.85,
		0.0
	)

	finish_round("SAVE!")


func _on_ball_finished() -> void:
	if game_mode == GameMode.MENU:
		return

	if phase != Phase.SHOOTING:
		return

	var result: String = ShotResolver.check_goal(
		shot_start,
		shot_destination,
		shot_height,
		ball.ball_radius,
		goal_z,
		goal_width,
		goal_height
	)

	finish_round(result)


func finish_round(result: String) -> void:
	if phase == Phase.FINISHED:
		return

	phase = Phase.FINISHED

	match result:
		"GOAL!":
			goals += 1
		"SAVE!":
			saves += 1
		"MISS!":
			misses += 1

	set_status(result + "\nNext round shortly.")

	countdown = round_end_delay


func set_status(message: String) -> void:
	status_message = message
	print(message)
	refresh_hud()


func refresh_hud() -> void:
	if hud == null:
		return

	var mode_name := "MENU"

	if game_mode == GameMode.KEEPER:
		mode_name = "KEEPER MODE"
	elif game_mode == GameMode.ATTACKER:
		mode_name = "ATTACKER MODE"

	hud.display(
		mode_name,
		round_number,
		goals,
		saves,
		misses,
		status_message
	)

func _on_insertion_finished() -> void:
	if phase != Phase.INSERTING:
		return

	phase = Phase.READY_TO_PASS

	if game_mode == GameMode.KEEPER:
		set_status("STOPPED! Preparing slip pass.")
		countdown = ai_pass_delay
	else:
		set_status("Insertion complete! Press E to pass.")


func _on_pass_finished() -> void:
	if phase != Phase.PASSING:
		return

	phase = Phase.READY_TO_SHOOT

	if game_mode == GameMode.KEEPER:
		set_status("Incoming shot!")
		countdown = ai_shot_delay
	else:
		set_status(
			"1/2/3 = Aim\n"
			+ "SPACE = Low shot\n"
			+ "SHIFT + SPACE = Aerial"
		)
