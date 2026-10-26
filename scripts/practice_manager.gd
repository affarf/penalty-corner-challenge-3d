
extends Node3D
const AttackerAI = preload("res://scripts/ai/attacker_ai.gd")
const GoalkeeperAI = preload("res://scripts/ai/goalkeeper_ai.gd")
var goalkeeper_ai = GoalkeeperAI.new()
enum GameMode {
	MENU,
	KEEPER,
	ATTACKER
}

enum Phase {
	READY,
	PASSING,
	READY_TO_SHOOT,
	SHOOTING,
	FINISHED
}

@export var goal_z: float = -16.0
@export var goal_width: float = 6.0
@export var goal_height: float = 3.0
@export var goal_depth: float = 1.8

@export var keeper_save_width: float = 1.1
@export var keeper_save_depth: float = 0.9
@export var keeper_save_height: float = 1.25
@export var ai_keeper_speed: float = 4.0

@onready var ball = get_parent().get_node("Ball3D")
@onready var attacker1: Node3D = get_parent().get_node("Attacker1")
@onready var attacker2: Node3D = get_parent().get_node("Attacker2")
@onready var goalkeeper = get_parent().get_node("Goalkeeper3D")

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

var hud_label: Label


func _ready() -> void:
	create_hud()
	ball.movement_finished.connect(_on_ball_finished)
	show_menu()


func _process(delta: float) -> void:
	if game_mode == GameMode.MENU:
		return

	if phase == Phase.SHOOTING and ball.moving:
		if game_mode == GameMode.ATTACKER:
			update_ai_keeper(delta)

		check_keeper_save()

	if countdown > 0.0:
		countdown -= delta

		if countdown <= 0.0:
			countdown = 0.0
			advance_timer()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

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

	if game_mode == GameMode.KEEPER:
		return

	# Attacker Mode controls
	match event.keycode:
		KEY_E:
			if phase == Phase.READY:
				pass_ball()

		KEY_1:
			aim_x = -2.2
			set_status("Aim: LEFT")

		KEY_2:
			aim_x = 0.0
			set_status("Aim: CENTER")

		KEY_3:
			aim_x = 2.2
			set_status("Aim: RIGHT")

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

	set_status(
		"PENALTY CORNER CHALLENGE 3D\n\n"
		+ "1 - KEEPER MODE\n"
		+ "2 - ATTACKER MODE\n\n"
		+ "Choose a mode to begin."
	)


func begin_round() -> void:
	round_number += 1
	phase = Phase.READY
	countdown = 0.0
	aim_x = 0.0
	shot_height = 0.0

	goalkeeper_ai.reset()

	var start: Vector3 = (
		attacker1.position + Vector3(0, 0, -1.0)
	)
	ball.reset_ball(start)

	if game_mode == GameMode.KEEPER:
		set_status("Get ready! The attackers will pass.")
		countdown = 1.5
	else:
		set_status("Press E to pass to Attacker2.")


func advance_timer() -> void:
	if game_mode == GameMode.MENU:
		return

	if phase == Phase.READY:
		if game_mode == GameMode.KEEPER:
			pass_ball()

	elif phase == Phase.READY_TO_SHOOT:
		if game_mode == GameMode.KEEPER:
			var shot: Dictionary = AttackerAI.choose_shot()
			aim_x = float(shot["target_x"])
			shoot_ball(bool(shot["aerial"]))
			
	elif phase == Phase.FINISHED:
		begin_round()


func pass_ball() -> void:
	if phase != Phase.READY:
		return

	phase = Phase.PASSING

	var destination: Vector3 = (
		attacker2.position + Vector3(0, 0, -0.8)
	)

	ball.move_to(destination, ball.pass_speed, 0.0)
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

	shot_height = 0.0
	if aerial:
		shot_height = ball.aerial_height

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

	if aerial:
		set_status("AERIAL SHOT!")
	else:
		set_status("LOW SHOT!")


func update_ai_keeper(delta: float) -> void:
	goalkeeper_ai.update(
		goalkeeper,
		ball,
		delta
	)





func check_keeper_save() -> void:
	var ball_pos: Vector3 = ball.position
	var keeper_pos: Vector3 = goalkeeper.position

	# No saves after the ball is fully behind the line.
	if ball_pos.z + ball.ball_radius < goal_z:
		return

	# Both human and AI use identical save reach.
	var save_width: float = goalkeeper.get_save_width()
	var save_height: float = goalkeeper.get_save_height()

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

	var reachable: bool = ball_bottom <= save_height

	if close_x and close_z and reachable:
		deflect_saved_ball()
		finish_round("SAVE!")




func check_goal() -> String:
	var dz: float = shot_destination.z - shot_start.z

	if absf(dz) < 0.001:
		return "MISS!"

	var t: float = (goal_z - shot_start.z) / dz

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

	var within_posts: bool = (
		absf(crossing_x) + ball.ball_radius
		< goal_width / 2.0
	)

	var below_bar: bool = (
		crossing_height + ball.ball_radius
		< goal_height
	)

	if within_posts and below_bar:
		return "GOAL!"

	return "MISS!"


func _on_ball_finished() -> void:
	if game_mode == GameMode.MENU:
		return

	match phase:
		Phase.PASSING:
			phase = Phase.READY_TO_SHOOT

			if game_mode == GameMode.KEEPER:
				set_status("Incoming shot! Get ready.")
				countdown = 0.7
			else:
				set_status(
					"1/2/3 = Aim | SPACE = Shoot\n"
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

	set_status(result + "\nNext round automatically.")
	countdown = 2.0


func set_status(message: String) -> void:
	status_message = message
	print(message)
	refresh_hud()


func refresh_hud() -> void:
	if hud_label == null:
		return

	if game_mode == GameMode.MENU:
		hud_label.text = status_message
		return

	var mode_name := "KEEPER MODE"
	if game_mode == GameMode.ATTACKER:
		mode_name = "ATTACKER MODE"

	hud_label.text = (
		mode_name
		+ "  |  ROUND " + str(round_number)
		+ "\nGoals: " + str(goals)
		+ "   Saves: " + str(saves)
		+ "   Misses: " + str(misses)
		+ "\n" + status_message
		+ "\nR = Reset | ESC = Menu"
	)


func create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PracticeHUD"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(390, 0)
	layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 20)
	margin.add_child(hud_label)
	
	
func deflect_saved_ball() -> void:
	var ball_position: Vector3 = ball.position
	var keeper_position: Vector3 = goalkeeper.position

	# Push the ball away from our goal (positive Z).
	# Also send it sideways for a visible deflection.
	var side: float = 1.0

	if ball_position.x < keeper_position.x:
		side = -1.0

	var destination := Vector3(
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

	# Stop the original shot, then send the ball away.
	ball.stop_ball()

	ball.move_to(
		destination,
		ball.pass_speed * 0.85,
		0.0
	)
