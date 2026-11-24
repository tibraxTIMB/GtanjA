extends Node3D

var car: VehicleBody3D
var trailer: RigidBody3D
var camera: Camera3D
var steering := 0.0
var throttle := false
var braking := false
var reverse := false
var speed_label: Label

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

func block(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision := false) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	if collision:
		var body := StaticBody3D.new()
		parent.add_child(body)
		body.position = pos
		add_shape(body, size, Vector3.ZERO)

func add_shape(parent: CollisionObject3D, size: Vector3, pos: Vector3) -> void:
	var c := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	c.shape = shape
	parent.add_child(c)
	c.position = pos

func _ready() -> void:
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.72, 0.85)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	block(self, Vector3(0,-0.5,0), Vector3(500,1,500), Color(0.28,0.43,0.23), true)
	for x in [-80,0,80]:
		block(self, Vector3(x,0.01,0), Vector3(8,0.03,220), Color(0.22,0.24,0.25))
	for z in [-100,0,100]:
		block(self, Vector3(0,0.02,z), Vector3(180,0.03,8), Color(0.22,0.24,0.25))
	for i in range(12):
		block(self, Vector3(-65 + (i % 6)*25,2.5,-55 if i<6 else 55), Vector3(9,5,8), Color(0.7,0.63,0.52), true)
	car = VehicleBody3D.new()
	car.mass = 1450
	add_child(car)
	car.position = Vector3(0,0.85,-40)
	add_shape(car, Vector3(1.8,0.65,4.2), Vector3.ZERO)
	block(car, Vector3.ZERO, Vector3(1.8,0.65,4.2), Color(0.65,0.12,0.08))
	block(car, Vector3(0,0.6,0), Vector3(1.6,0.65,2.1), Color(0.2,0.35,0.45))
	for x in [-0.92,0.92]:
		for z in [-1.35,1.35]:
			var wheel := VehicleWheel3D.new()
			car.add_child(wheel)
			wheel.position = Vector3(x,-0.3,z)
			wheel.wheel_radius = 0.34
			wheel.use_as_steering = z > 0
			wheel.use_as_traction = z < 0
			var visual := MeshInstance3D.new()
			var tire := CylinderMesh.new()
			tire.top_radius = 0.34
			tire.bottom_radius = 0.34
			tire.height = 0.22
			visual.mesh = tire
			visual.rotation_degrees.z = 90
			visual.material_override = material(Color(0.04,0.04,0.04))
			wheel.add_child(visual)
	trailer = RigidBody3D.new()
	trailer.mass = 230
	add_child(trailer)
	trailer.position = car.position + Vector3(0,0,-4.8)
	add_shape(trailer, Vector3(1.65,0.25,2.8), Vector3.ZERO)
	block(trailer, Vector3.ZERO, Vector3(1.65,0.25,2.8), Color.SILVER)
	for x in [-0.8,0.8]:
		block(trailer, Vector3(x,0.4,0), Vector3(0.08,0.65,2.8), Color.SILVER)
	var joint := PinJoint3D.new()
	add_child(joint)
	joint.position = car.position + Vector3(0,0,-2.2)
	joint.node_a = joint.get_path_to(car)
	joint.node_b = joint.get_path_to(trailer)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.position = car.position + Vector3(0,6,-12)
	var hud := CanvasLayer.new()
	add_child(hud)
	speed_label = Label.new()
	hud.add_child(speed_label)
	speed_label.position = Vector2(20,20)
	speed_label.add_theme_font_size_override("font_size",24)
	var controls := HBoxContainer.new()
	hud.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_top = -100
	for label in ["VENSTRE","HØGRE","D/R","BREMS","GASS"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(120,80)
		controls.add_child(button)
		button.button_down.connect(func(): control(label,true))
		button.button_up.connect(func(): control(label,false))

func control(label: String, pressed: bool) -> void:
	match label:
		"VENSTRE": steering = -1.0 if pressed else 0.0
		"HØGRE": steering = 1.0 if pressed else 0.0
		"GASS": throttle = pressed
		"BREMS": braking = pressed
		"D/R":
			if pressed and car.linear_velocity.length() < 0.5:
				reverse = not reverse

func _physics_process(delta: float) -> void:
	var steer_input := steering + Input.get_axis("ui_left","ui_right")
	car.steering = lerpf(car.steering, clampf(steer_input,-1,1)*0.45, minf(delta*7,1))
	car.engine_force = (-650.0 if reverse else 650.0) if throttle or Input.is_action_pressed("ui_up") else 0.0
	car.brake = 35.0 if braking or Input.is_action_pressed("ui_down") else 0.0
	var target := car.global_position + car.global_basis * Vector3(0,6,-12)
	camera.position = camera.position.lerp(target,minf(delta*5,1))
	camera.look_at(car.global_position + Vector3.UP)
	speed_label.text = "REBORN X | %d km/t | %s" % [roundi(car.linear_velocity.length()*3.6),"R" if reverse else "D"]
