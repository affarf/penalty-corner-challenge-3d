
extends Node3D

const CornerSequence = preload(
	"res://scripts/game/corner_sequence.gd"
)
const PracticeHUD = preload(
	"res://scripts/game/practice_hud.gd"
)

const DefenderRush = preload(
	"res://scripts/ai/defender_rush_3d.gd"
)

enum GameMode {
	MENU,
	KEEPER,
	ATTACKER
}

@export_group("Insertion")
@export var injection_x: float = -8.0
@export var injection_z: float = -18.5
@export var injection_speed: float = 11.0

@export_group("Timing")
@export var ai_pass_delay: float = 0.6
@export var ai_shot_delay: float = 1.0
@export var round_end_delay: float = 2.0

@export_group("Goalkeeping")
@export var keeper_save_depth: float = 0.9

@onready var goal = get_parent().get_node("Goal3D")
@onready var ball = get_parent().get_node("Ball3D")
@onready var injector = get_parent().get_node("Injector")
@onready var attacker1 = get_parent().get_node("Attacker1")
@onready var attacker2 = get_parent().get_node("Attacker2")
@onready var goalkeeper = get_parent().get_node("Goalkeeper3D")

var sequence
var hud
var defender_rush
var game_mode: GameMode = GameMode.MENU
var round_number: int = 0

var goals: int = 0
var saves: int = 0
var misses: int = 0

var round_timer: float = 0.0
var status_message: String = ""



func _ready() -> void:
	# 1. Create HUD
	hud = PracticeHUD.new()
	hud.name = "PracticeHUD"
	add_child(hud)

	# 2. Create CornerSequence
	sequence = CornerSequence.new()
	sequence.name = "CornerSequence"
	add_child(sequence)

	sequence.setup(
		ball,
		injector,
		attacker1,
		attacker2,
		goalkeeper
	)

	# 3. Create DefenderRush BEFORE connecting signals
	defender_rush = DefenderRush.new()
	defender_rush.name = "DefenderRush"
	add_child(defender_rush)

	var defenders: Array[Node3D] = [
		get_parent().get_node("Defender1"),
		get_parent().get_node("Defender2"),
		get_parent().get_node("Defender3"),
		get_parent().get_node("Defender4")
	]

	defender_rush.setup(
		defenders,
		attacker1,
		attacker2,
		ball
	)
	
	defender_rush.set_goalkeeper(goalkeeper)
	defender_rush.goal_z = goal.global_position.z

	# 4. Connect signals
	sequence.status_changed.connect(set_status)
	sequence.corner_finished.connect(_on_corner_finished)

	sequence.injection_released.connect(
		defender_rush.release
	)

	sequence.pass_released.connect(
		defender_rush.enable_interceptions
	)
	
	sequence.shooter_windup_changed.connect(
		defender_rush.set_shooter_windup
	)

	defender_rush.ball_intercepted.connect(
		sequence.handle_defender_interception
	)

	# 5. Display main menu
	show_menu()



func _process(delta: float) -> void:
	if game_mode == GameMode.MENU:
		return

	if round_timer <= 0.0:
		return

	round_timer -= delta

	if round_timer <= 0.0:
		round_timer = 0.0
		begin_round()


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
			sequence.request_pass()

		KEY_1:
			sequence.set_aim(-2.2)

		KEY_2:
			sequence.set_aim(0.0)

		KEY_3:
			sequence.set_aim(2.2)

		KEY_SPACE:
			sequence.request_shot(event.shift_pressed)


func start_mode(selected_mode: GameMode) -> void:
	game_mode = selected_mode

	round_number = 0
	goals = 0
	saves = 0
	misses = 0

	begin_round()


func show_menu() -> void:
	game_mode = GameMode.MENU
	round_timer = 0.0

	sequence.cancel()
	defender_rush.reset_runners()
	goalkeeper.player_controlled = false
	goalkeeper.reset_keeper()

	set_status(
		"PENALTY CORNER CHALLENGE 3D\n\n"
		+ "1 - KEEPER MODE\n"
		+ "2 - ATTACKER MODE\n\n"
		+ "Choose a mode."
	)


func begin_round() -> void:
	if game_mode == GameMode.MENU:
		return

	round_number += 1
	round_timer = 0.0

	# Use the goal scene's actual current dimensions.
	sequence.goal_z = goal.global_position.z
	sequence.goal_width = goal.goal_width * goal.scale.x
	sequence.goal_height = goal.goal_height * goal.scale.y
	sequence.goal_depth = goal.goal_depth * goal.scale.z

	# Preserve your customized corner coordinates.
	sequence.injection_position = Vector3(
		injection_x, 0.0, injection_z
	)

	sequence.injection_speed = injection_speed
	sequence.ai_pass_delay = ai_pass_delay
	sequence.ai_shot_delay = ai_shot_delay
	sequence.save_depth = keeper_save_depth
	
	defender_rush.reset_runners()

	sequence.start_corner(
		game_mode == GameMode.KEEPER
	)

	refresh_hud()


func _on_corner_finished(result: String) -> void:
	defender_rush.stop_runners()
	match result:
		"GOAL!":
			goals += 1

		"SAVE!":
			saves += 1

		"MISS!":
			misses += 1
		
		"BLOCK!":
			saves += 1

	set_status(result + "\nNext round shortly.")
	round_timer = round_end_delay


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
