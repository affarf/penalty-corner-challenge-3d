
extends Node

signal contact(action: String)

var action_rig: Node3D
var current_tween: Tween


func setup(rig: Node3D) -> void:
	action_rig = rig


func play_action(action: String) -> void:
	if action_rig == null:
		return

	if current_tween != null:
		current_tween.kill()

	action_rig.position = Vector3.ZERO
	action_rig.rotation = Vector3.ZERO

	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_SINE)

	match action:
		"inject":
			animate_injection()

		"trap":
			animate_trap()

		"pass":
			animate_pass()
		
		"shoot":
			animate_shot()
		"tackle":
			animate_tackle()


func animate_injection() -> void:
	# Prepare the stick behind the ball.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0, 0.08, -0.25),
		0.18
	)

	# Push through the ball.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0, -0.05, 0.30),
		0.15
	)

	current_tween.tween_callback(
		func() -> void:
			contact.emit("inject")
	)

	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0, 0.05, 0.42),
		0.15
	)

	current_tween.tween_property(
		action_rig,
		"position",
		Vector3.ZERO,
		0.20
	)


func animate_trap() -> void:
	# Lower the stick to receive the ball.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0, -0.16, 0.16),
		0.13
	)

	current_tween.tween_callback(
		func() -> void:
			contact.emit("trap")
	)

	# Absorb contact, then return to ready.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0, -0.10, 0.04),
		0.13
	)

	current_tween.tween_property(
		action_rig,
		"position",
		Vector3.ZERO,
		0.20
	)


func animate_pass() -> void:
	# Short backswing.
	current_tween.tween_property(
		action_rig,
		"rotation:y",
		-0.42,
		0.16
	)

	# Sweep the stick across the ball.
	current_tween.tween_property(
		action_rig,
		"rotation:y",
		0.36,
		0.19
	)

	current_tween.tween_callback(
		func() -> void:
			contact.emit("pass")
	)

	# Follow-through.
	current_tween.tween_property(
		action_rig,
		"rotation:y",
		0.52,
		0.12
	)

	current_tween.tween_property(
		action_rig,
		"rotation:y",
		0.0,
		0.23
	)


func animate_shot() -> void:
	# Preparation: lower the stick and draw it back.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0.0, -0.12, -0.22),
		0.22
	)

	current_tween.parallel().tween_property(
		action_rig,
		"rotation:y",
		-0.35,
		0.22
	)

	# Forward acceleration through the ball.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0.0, -0.06, 0.34),
		0.14
	)

	current_tween.parallel().tween_property(
		action_rig,
		"rotation:y",
		0.25,
		0.14
	)

	# The ball leaves the stick here.
	current_tween.tween_callback(
		func() -> void:
			contact.emit("shoot")
	)

	# Follow-through.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0.0, 0.16, 0.46),
		0.16
	)

	current_tween.parallel().tween_property(
		action_rig,
		"rotation:y",
		0.48,
		0.16
	)

	# Return to the ready stance.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3.ZERO,
		0.24
	)

	current_tween.parallel().tween_property(
		action_rig,
		"rotation:y",
		0.0,
		0.24
	)


func animate_tackle() -> void:
	# Extend the stick toward the ball.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3(0.0, -0.13, 0.32),
		0.13
	)

	current_tween.parallel().tween_property(
		action_rig,
		"rotation:y",
		-0.20,
		0.13
	)

	# Stick-contact moment.
	current_tween.tween_callback(
		func() -> void:
			contact.emit("tackle")
	)

	# Pull the stick back.
	current_tween.tween_property(
		action_rig,
		"position",
		Vector3.ZERO,
		0.22
	)

	current_tween.parallel().tween_property(
		action_rig,
		"rotation:y",
		0.0,
		0.22
	)

func cancel_action() -> void:
	if current_tween != null:
		current_tween.kill()
		current_tween = null

	if action_rig != null:
		action_rig.position = Vector3.ZERO
		action_rig.rotation = Vector3.ZERO
