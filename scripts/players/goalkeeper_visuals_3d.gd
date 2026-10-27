
extends Node3D

# Procedural low-poly goalkeeper with movable body parts.
# The controller tells this rig what save to animate.

var torso: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

var pad_color := Color("#E5AA3B")
var shirt_color := Color("#258EF5")
var glove_color := Color("#F3C75B")


func _ready() -> void:
	build_rig()


func make_box(
	parent: Node3D,
	offset: Vector3,
	dimensions: Vector3,
	color: Color
) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8

	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = offset
	parent.add_child(mesh_instance)


func make_sphere(
	parent: Node3D,
	offset: Vector3,
	radius: float,
	color: Color
) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	var material := StandardMaterial3D.new()
	material.albedo_color = color

	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = offset
	parent.add_child(mesh_instance)


func create_pivot(
	parent: Node3D,
	pivot_name: String,
	offset: Vector3
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = offset
	parent.add_child(pivot)
	return pivot


func build_rig() -> void:
	torso = create_pivot(
		self, "Torso", Vector3(0, 1.15, 0)
	)

	make_box(
		torso,
		Vector3.ZERO,
		Vector3(0.85, 0.82, 0.52),
		shirt_color
	)

	make_box(
		torso,
		Vector3(0, 0, 0.29),
		Vector3(0.88, 0.68, 0.12),
		Color("#2066A0")
	)

	# Helmet and cage
	make_sphere(
		torso,
		Vector3(0, 0.64, 0),
		0.29,
		Color("#183E65")
	)

	make_box(
		torso,
		Vector3(0, 0.64, 0.28),
		Vector3(0.39, 0.23, 0.065),
		Color("#D6E5EA")
	)

	# Arm pivots positioned at the shoulders.
	left_arm = create_pivot(
		torso, "LeftArm", Vector3(-0.53, 0.30, 0)
	)
	right_arm = create_pivot(
		torso, "RightArm", Vector3(0.53, 0.30, 0)
	)

	for arm in [left_arm, right_arm]:
		make_box(
			arm,
			Vector3(0, -0.29, 0),
			Vector3(0.24, 0.55, 0.27),
			shirt_color
		)

		make_box(
			arm,
			Vector3(0, -0.61, 0.12),
			Vector3(0.34, 0.30, 0.36),
			glove_color
		)


	# Field hockey stick held by the right glove.
	# Positive X is the model's right-hand side.
	var stick_color := Color("#D5B47D")
	var grip_color := Color("#20252B")

	var stick_pivot := create_pivot(
		left_arm,
		"HockeyStick",
		Vector3(0.10, -0.57, 0.22)
	)

	# Angle the stick slightly toward the turf.
	stick_pivot.rotation.z = -0.16

	# Long shaft with an upper grip.
	make_box(
		stick_pivot,
		Vector3(0, -0.39, 0),
		Vector3(0.075, 0.85, 0.085),
		stick_color
	)

	make_box(
		stick_pivot,
		Vector3(0, -0.10, 0),
		Vector3(0.09, 0.22, 0.10),
		grip_color
	)

	# Hooked head: heel and rounded toe.
	make_box(
		stick_pivot,
		Vector3(-0.14, -0.80, 0),
		Vector3(0.34, 0.13, 0.16),
		stick_color
	)

	make_sphere(
		stick_pivot,
		Vector3(-0.29, -0.80, 0),
		0.075,
		stick_color
	)

	# Hip-mounted leg pivots.
	left_leg = create_pivot(
		self, "LeftLeg", Vector3(-0.24, 0.83, 0)
	)
	right_leg = create_pivot(
		self, "RightLeg", Vector3(0.24, 0.83, 0)
	)

	for leg in [left_leg, right_leg]:
		make_box(
			leg,
			Vector3(0, -0.32, 0.06),
			Vector3(0.34, 0.64, 0.38),
			pad_color
		)

		# Kicker at the bottom of the leg.
		make_box(
			leg,
			Vector3(0, -0.70, 0.22),
			Vector3(0.42, 0.24, 0.66),
			pad_color
		)


func animate_pose(
	action: String,
	save_direction: Vector3,
	delta: float
) -> void:
	var blend := minf(delta * 15.0, 1.0)

	var torso_x := 0.0
	var torso_z := 0.0

	var left_arm_z := 0.0
	var right_arm_z := 0.0
	var left_arm_x := 0.0
	var right_arm_x := 0.0

	var left_leg_x := 0.0
	var right_leg_x := 0.0
	var left_leg_z := 0.0
	var right_leg_z := 0.0

	var side := 1.0
	if save_direction.x < -0.05:
		side = -1.0

	match action:
		"kick":
			# One kicker reaches toward the ball.
			if side > 0.0:
				right_leg_x = -0.95
				right_leg_z = 0.28
			else:
				left_leg_x = -0.95
				left_leg_z = -0.28

			torso_x = -0.08

		"dive":
			# Lean sideways and extend both arms.
			torso_z = -side * 0.60

			left_arm_z = side * 1.25
			right_arm_z = side * 1.25

			left_arm_x = -0.25
			right_arm_x = -0.25

			# Trailing leg follows the dive.
			if side > 0.0:
				left_leg_z = -0.40
				right_leg_z = 0.25
			else:
				right_leg_z = 0.40
				left_leg_z = -0.25

		"recovery":
			torso_x = 0.12

	torso.rotation.x = lerpf(
		torso.rotation.x, torso_x, blend
	)
	torso.rotation.z = lerpf(
		torso.rotation.z, torso_z, blend
	)

	left_arm.rotation.z = lerpf(
		left_arm.rotation.z, left_arm_z, blend
	)
	right_arm.rotation.z = lerpf(
		right_arm.rotation.z, right_arm_z, blend
	)

	left_arm.rotation.x = lerpf(
		left_arm.rotation.x, left_arm_x, blend
	)
	right_arm.rotation.x = lerpf(
		right_arm.rotation.x, right_arm_x, blend
	)

	left_leg.rotation.x = lerpf(
		left_leg.rotation.x, left_leg_x, blend
	)
	right_leg.rotation.x = lerpf(
		right_leg.rotation.x, right_leg_x, blend
	)

	left_leg.rotation.z = lerpf(
		left_leg.rotation.z, left_leg_z, blend
	)
	right_leg.rotation.z = lerpf(
		right_leg.rotation.z, right_leg_z, blend
	)


func reset_pose() -> void:
	if torso == null:
		return

	torso.rotation = Vector3.ZERO
	left_arm.rotation = Vector3.ZERO
	right_arm.rotation = Vector3.ZERO
	left_leg.rotation = Vector3.ZERO
	right_leg.rotation = Vector3.ZERO
