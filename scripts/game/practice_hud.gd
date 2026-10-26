
extends CanvasLayer

var hud_label: Label


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(390, 0)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 20)
	margin.add_child(hud_label)


func display(
	mode_name: String,
	round_number: int,
	goals: int,
	saves: int,
	misses: int,
	message: String
) -> void:
	if hud_label == null:
		return

	if mode_name == "MENU":
		hud_label.text = message
		return

	hud_label.text = (
		mode_name
		+ "  |  ROUND " + str(round_number)
		+ "\nGoals: " + str(goals)
		+ "   Saves: " + str(saves)
		+ "   Misses: " + str(misses)
		+ "\n" + message
		+ "\nR = Reset | ESC = Menu"
	)
