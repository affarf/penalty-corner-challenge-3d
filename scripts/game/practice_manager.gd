
extends Node3D

const AttackerAI = preload(
	"res://scripts/ai/attacker_ai.gd"
)
const GoalkeeperAI = preload(
	"res://scripts/ai/goalkeeper_ai.gd"
)
const PracticeHUD = preload(
	"res://scripts/game/practice_hud.gd"
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

@export_group("Goal")
@export var goal_z: float = -16.0
@export var goal_width: float = 6.0
@export var goal_height: float = 3.0
@export var goal_depth: float = 1.8

@export_group("Saves")
@export var keeper_save_depth: float = 0.9

@export_group("Timing")
@export var insertion_time: float = 0.5
@export var ai_pass_delay: float = 0.7
@export var ai_shot_delay: float = 1.0
@export var round_end_delay: float = 2.0

@onready var ball = get_parent().get_node("Ball3D")
@onready var attacker1: Node3D = (
	get_parent().get_node("Attacker1")
)
@onready var attacker2: Node3D = (
	get_parent().get_node("Attacker2")
)
@onready var goalkeeper = (
	get_parent().get_node("Goalkeeper3D")
)

var goalkeeper_ai = GoalkeeperAI.new()
var hud: CanvasLayer

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


func _ready() -> void:
	hud = PracticeHUD.new()
	hud.name = "PracticeHUD"
	add_child(hud)

	ball.movement_finished.connect(_on_ball_finished)

	show_menu()


func _process(delta: float) -> void:
	if game_mode == GameMode.MENU:
		return

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
	game_mode = GameMode.MENU
	phase = Phase.READY
	countdown = 0.0

	ball.stop_ball()
	goalkeeper.player_controlled = false

	# Clear any movement or dive from the previous mode.
	goalkeeper.reset_keeper()
	goalkeeper_ai.reset()

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
	phase = Phase.READY
	countdown = 0.0

	aim_x = 0.0
	shot_height = 0.0

	# Reset BOTH controllers on every round.
	goalkeeper.reset_keeper()
	goalkeeper_ai.reset()

	goalkeeper.player_controlled = (
		game_mode == GameMode.KEEPER
	)

	var start: Vector3 = (
		attacker1.position + Vector3(0, 0, -1.0)
	)

	ball.reset_ball(start)

	# Begin insertion in both modes.
	start_insertion()


func start_insertion() -> void:
	phase = Phase.INSERTING

	# Keeper steps from Z=-17 toward Z=-15.
	goalkeeper.release_from_line()

	set_status("INSERTION! Keeper stepping forward.")

	countdown = insertion_time


func advance_timer() -> void:
	if game_mode == GameMode.MENU:
		return

	match phase:
		Phase.INSERTING:
			phase = Phase.READY_TO_PASS

			if game_mode == GameMode.KEEPER:
				set_status("Attackers preparing to pass...")
				countdown = ai_pass_delay
			else:
				set_status("Press E to pass.")

		Phase.READY_TO_PASS:
			if game_mode == GameMode.KEEPER:
				pass_ball()

		Phase.READY_TO_SHOOT:
			if game_mode == GameMode.KEEPER:
				var shot: Dictionary = (
					AttackerAI.choose_shot()
				)

				aim_x = float(shot["target_x"])
				shoot_ball(bool(shot["aerial"]))

		Phase.FINISHED:
			begin_round()


func pass_ball() -> void:
	if phase != Phase.READY_TO_PASS:
		return

	phase = Phase.PASSING

	var destination: Vector3 = (
		attacker2.position + Vector3(0, 0, -0.8)
	)

	ball.move_to(
		destination,
		ball.pass_speed,
		0.0
	)

	set_status("PASS!")


func shoot_ball(aerial: bool) -> void:
	if phase != Phase.READY_TO_SHOOT:
		return

	phase = Phase.SHOOTING

	shot_start = ball.position

	shot_destination = Vector3(
		aim_x,
		0.0,
		goal_z - goal_depth + 0.1
	)

	shot_height = (
		ball.aerial_height if aerial else 0.0
	)

	ball.move_to(
		shot_destination,
		ball.shot_speed,
		shot_height
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
	var ball_pos: Vector3 = ball.position
	var keeper_pos: Vector3 = goalkeeper.position

	# Ball has passed behind the goal line.
	if ball_pos.z + ball.ball_radius < goal_z:
		return

	var save_width: float = (
		goalkeeper.get_save_width()
	)
	var save_height: float = (
		goalkeeper.get_save_height()
	)

	if save_width <= 0.0 or save_height <= 0.0:
		return

	var close_x: bool = (
		absf(ball_pos.x - keeper_pos.x)
		<= save_width + ball.ball_radius
	)

	var close_z: bool = (
		absf(ball_pos.z - keeper_pos.z)
		<= keeper_save_depth + ball.ball_radius
	)

	var ball_bottom: float = (
		ball.get_ball_height() - ball.ball_radius
	)

	if (
		close_x
		and close_z
		and ball_bottom <= save_height
	):
		deflect_saved_ball()
		finish_round("SAVE!")


func deflect_saved_ball() -> void:
	var ball_pos: Vector3 = ball.position

	var side: float = 1.0
	if ball_pos.x < goalkeeper.position.x:
		side = -1.0

	var destination := Vector3(
		clampf(
			ball_pos.x + side * 3.0,
			-10.5,
			10.5
		),
		0.0,
		clampf(
			ball_pos.z + 5.0,
			-18.0,
			18.0
		)
	)

	ball.stop_ball()
	ball.move_to(
		destination,
		ball.pass_speed * 0.85,
		0.0
	)


func check_goal() -> String:
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

	var crossing_height: float = ball.ball_radius

	if shot_height > 0.0:
		crossing_height += shot_height * (
			1.0 - pow(1.0 - t, 3.0)
		)

	var inside_posts: bool = (
		absf(crossing_x) + ball.ball_radius
		< goal_width / 2.0
	)

	var below_bar: bool = (
		crossing_height + ball.ball_radius
		< goal_height
	)

	if inside_posts and below_bar:
		return "GOAL!"

	return "MISS!"


func _on_ball_finished() -> void:
	if game_mode == GameMode.MENU:
		return

	match phase:
		Phase.PASSING:
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

		Phase.SHOOTING:
			finish_round(check_goal())


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
