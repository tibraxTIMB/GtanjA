extends Node3D

var map_spawn := Vector3(0,0.85,-40)
var map_loaded := false
var car: VehicleBody3D
var trailer: RigidBody3D
var camera: Camera3D
var steering := 0.0
var throttle := false
var braking := false
var reverse := false
var speed_label: Label
var camera_mode := 0
var camera_distance := 12.0
var mission_stage := 0
var hitch: PinJoint3D
var cargo_mass := 0.0
var career_xp := 0
var career_jobs := 0
var cargo_visual: MeshInstance3D
var mission_label: Label
var destination := Vector3(80,0,100)
var map_label: Label
var wheel_touch := -1
var wheel_angle := 0.0
var wheel_last := 0.0
var wheel_panel: Control

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
	if not load_geography():
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
	car.position = map_spawn
	add_shape(car, Vector3(1.8,0.65,4.2), Vector3.ZERO)
	block(car, Vector3.ZERO, Vector3(1.8,0.65,4.2), Color(0.65,0.12,0.08))
	block(car, Vector3(0,0.6,0), Vector3(1.6,0.65,2.1), Color(0.2,0.35,0.45))
	for x in [-0.92,0.92]:
		for z in [-1.35,1.35]:
			var wheel := VehicleWheel3D.new()
			car.add_child(wheel)
			wheel.position = Vector3(x,-0.3,z)
			wheel.wheel_radius = 0.34
			wheel.wheel_rest_length = 0.2
			wheel.suspension_stiffness = 25.0
			wheel.damping_compression = 0.9
			wheel.damping_relaxation = 1.1
			wheel.wheel_friction_slip = 2.5
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
	for x in [-0.92,0.92]:
		var tire_body := RigidBody3D.new()
		tire_body.mass = 12
		add_child(tire_body)
		tire_body.position = trailer.position + Vector3(x,-0.35,0)
		var tire_shape := CylinderShape3D.new()
		tire_shape.radius = 0.34
		tire_shape.height = 0.22
		var tire_collision := CollisionShape3D.new()
		tire_collision.shape = tire_shape
		tire_body.add_child(tire_collision)
		tire_collision.rotation_degrees.z = 90
		var tire_visual := MeshInstance3D.new()
		var tire_mesh := CylinderMesh.new()
		tire_mesh.top_radius = 0.34
		tire_mesh.bottom_radius = 0.34
		tire_mesh.height = 0.22
		tire_visual.mesh = tire_mesh
		tire_visual.rotation_degrees.z = 90
		tire_visual.material_override = material(Color(0.04,0.04,0.04))
		tire_body.add_child(tire_visual)
		var axle := HingeJoint3D.new()
		add_child(axle)
		axle.position = tire_body.position
		axle.rotation_degrees.y = 90
		axle.node_a = axle.get_path_to(trailer)
		axle.node_b = axle.get_path_to(tire_body)
	block(trailer, Vector3(0,0.4,-1.4), Vector3(1.65,0.65,0.08), Color.SILVER)
	block(trailer, Vector3(0,0.4,1.4), Vector3(1.65,0.65,0.08), Color.SILVER)
	for x in [-0.8,0.8]:
		block(trailer, Vector3(x,0.77,0), Vector3(0.12,0.08,2.8), Color(0.78,0.8,0.82))
		block(trailer, Vector3(x*1.35,0.05,0), Vector3(0.32,0.08,0.95), Color(0.35,0.38,0.4))
		block(trailer, Vector3(x*0.8,0.05,-1.46), Vector3(0.28,0.13,0.06), Color(0.85,0.04,0.03))
		var drawbar := MeshInstance3D.new()
		var beam := BoxMesh.new()
		beam.size = Vector3(0.09,0.09,1.5)
		drawbar.mesh = beam
		drawbar.material_override = material(Color.SILVER)
		trailer.add_child(drawbar)
		drawbar.position = Vector3(x*0.5,-0.05,2.0)
		drawbar.rotation.y = -x*0.7
	block(trailer, Vector3(0,-0.05,2.6), Vector3(0.2,0.16,0.3), Color(0.55,0.57,0.6))
	var nameplate := Label3D.new()
	nameplate.text = "TANJA"
	nameplate.font_size = 48
	nameplate.pixel_size = 0.006
	trailer.add_child(nameplate)
	nameplate.position = Vector3(0,0.45,-1.46)
	nameplate.rotation_degrees.y = 180
	var joint := PinJoint3D.new()
	hitch = joint
	add_child(joint)
	joint.position = car.position + Vector3(0,0,-2.2)
	joint.node_a = joint.get_path_to(car)
	joint.node_b = joint.get_path_to(trailer)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.position = car.position + Vector3(0,6,-12)
	if map_loaded:
		destination = map_spawn + Vector3(0,0,25)
	else:
		block(self,Vector3(80,0.05,100),Vector3(12,0.1,12),Color(0.8,0.65,0.15))
		for i in range(3):
			block(self,Vector3(90+i*5,1.2,110),Vector3(4,2.4,3),Color(0.2,0.45,0.35),true)
	var saved := ConfigFile.new()
	if saved.load("user://reborn_x_career.cfg") == OK:
		career_xp = int(saved.get_value("career","xp",0))
		career_jobs = int(saved.get_value("career","jobs",0))
	var hud := CanvasLayer.new()
	add_child(hud)
	speed_label = Label.new()
	hud.add_child(speed_label)
	speed_label.position = Vector2(20,20)
	speed_label.add_theme_font_size_override("font_size",24)
	mission_label = Label.new()
	hud.add_child(mission_label)
	mission_label.position = Vector2(20,55)
	mission_label.add_theme_font_size_override("font_size",20)
	map_label = Label.new()
	hud.add_child(map_label)
	map_label.position = Vector2(20,85)
	var controls := HBoxContainer.new()
	hud.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_top = -100
	for label in ["D/R","BREMS","GASS","KAMERA","ZOOM","KOPLING","LAST"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(120,80)
		controls.add_child(button)
		button.button_down.connect(func(): control(label,true))
		button.button_up.connect(func(): control(label,false))

	wheel_panel = Control.new()
	hud.add_child(wheel_panel)
	wheel_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	wheel_panel.offset_top = -240
	wheel_panel.offset_right = 220
	wheel_panel.offset_bottom = -110
	wheel_panel.gui_input.connect(wheel_input)
	var wheel_text := Label.new()
	wheel_panel.add_child(wheel_text)
	wheel_text.text = "◉ RATT"
	wheel_text.add_theme_font_size_override("font_size", 38)
	wheel_text.mouse_filter = Control.MOUSE_FILTER_IGNORE

func wheel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and wheel_touch == -1:
			wheel_touch = event.index
			wheel_last = (event.position - wheel_panel.size/2).angle()
		elif not event.pressed and event.index == wheel_touch:
			wheel_touch = -1
	elif event is InputEventScreenDrag and event.index == wheel_touch:
		var bearing := (event.position - wheel_panel.size/2).angle()
		wheel_angle = clampf(wheel_angle + wrapf(bearing-wheel_last,-PI,PI),-PI,PI)
		wheel_last = bearing

func control(label: String, pressed: bool) -> void:
	match label:
		"VENSTRE": steering = -1.0 if pressed else 0.0
		"HØGRE": steering = 1.0 if pressed else 0.0
		"GASS": throttle = pressed
		"BREMS": braking = pressed
		"KOPLING":
			if pressed and car.linear_velocity.length()<0.2 and trailer.linear_velocity.length()<0.2:
				if hitch.node_b != NodePath(""):
					hitch.node_b = NodePath("")
				else:
					var ball := car.to_global(Vector3(0,0,-2.2))
					var socket := trailer.to_global(Vector3(0,0,2.6))
					if ball.distance_to(socket)<0.35:
						hitch.global_position = ball
						hitch.node_a = hitch.get_path_to(car)
						hitch.node_b = hitch.get_path_to(trailer)
		"LAST":
			if pressed and trailer.linear_velocity.length()<0.2:
				cargo_mass = 150.0 if cargo_mass == 0 else 0.0
				trailer.mass = 230.0+cargo_mass
				trailer.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
				trailer.center_of_mass = Vector3(0,0.2 if cargo_mass>0 else 0,0.15 if cargo_mass>0 else 0)
				if is_instance_valid(cargo_visual):
					cargo_visual.queue_free()
				if cargo_mass>0:
					cargo_visual = MeshInstance3D.new()
					var crate := BoxMesh.new()
					crate.size = Vector3(1.2,0.5,1.5)
					cargo_visual.mesh = crate
					cargo_visual.material_override = material(Color(0.45,0.3,0.16))
					trailer.add_child(cargo_visual)
					cargo_visual.position = Vector3(0,0.4,0.2)
		"ZOOM":
			if pressed:
				camera_distance = 18.0 if camera_distance < 15.0 else 9.0
		"KAMERA":
			if pressed:
				camera_mode = (camera_mode+1)%3
		"D/R":
			if pressed and car.linear_velocity.length() < 0.5:
				reverse = not reverse

func _physics_process(delta: float) -> void:
	if wheel_touch == -1:
		wheel_angle = lerpf(wheel_angle,0.0,minf(delta*8,1))
	var distance := car.global_position.distance_to(destination)
	var relative := destination-car.global_position
	var bearing := wrapf(atan2(relative.x,relative.z)-car.rotation.y,-PI,PI)
	map_label.text = "GPS: %d m | %s" % [roundi(distance), "høgre" if bearing>0.25 else ("venstre" if bearing < -0.25 else "rett fram")]
	if mission_stage == 0 and distance < 8 and car.linear_velocity.length()<1:
		if hitch.node_b != NodePath("") and cargo_mass>0:
			mission_stage = 1
			career_xp += 100
			career_jobs += 1
			var saved := ConfigFile.new()
			saved.set_value("career","xp",career_xp)
			saved.set_value("career","jobs",career_jobs)
			saved.save("user://reborn_x_career.cfg")
	mission_label.text = ("Last Tanja og lever ved GPS-målet" if mission_stage == 0 else "Oppdrag fullført") + " | %d XP | %d kg | %s" % [career_xp,roundi(cargo_mass),"Kopla" if hitch.node_b != NodePath("") else "Fråkopla"]
	var steer_input := wheel_angle/PI + steering + Input.get_axis("ui_left","ui_right")
	car.steering = lerpf(car.steering, clampf(steer_input,-1,1)*0.45*(1.0-0.5*clampf(car.linear_velocity.length()/20.0,0.0,1.0)), minf(delta*7,1))
	car.engine_force = (-650.0 if reverse else 650.0) if throttle or Input.is_action_pressed("ui_up") else 0.0
	car.brake = 35.0 if braking or Input.is_action_pressed("ui_down") else 0.0
	var target := car.global_position + car.global_basis * Vector3(0,6,-camera_distance)
	if camera_mode == 1:
		target = car.global_position + Vector3(0,25,-0.1)
	elif camera_mode == 2:
		target = trailer.global_position + trailer.global_basis * Vector3(0,4,-8)
	camera.position = camera.position.lerp(target,minf(delta*5,1))
	camera.look_at(car.global_position + Vector3.UP)
	speed_label.text = "REBORN X | %d km/t | %s | %s" % [roundi(car.linear_velocity.length()*3.6),"R" if reverse else "D","OSM" if map_loaded else "TESTKART"]

func load_geography() -> bool:
	var path := "res://data/hardanger.json"
	if not FileAccess.file_exists(path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.has("roads") or data["roads"].is_empty():
		return false
	block(self, Vector3(0,-0.5,0), Vector3(6600,1,6600), Color(0.28,0.43,0.23), true)
	var asphalt := material(Color(0.22,0.24,0.25))
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(1,0.04,1)
	var transforms: Array[Transform3D] = []
	for road in data["roads"]:
		var points: Array = road["points"]
		var width := 7.0 if road["kind"] in ["primary","secondary","trunk"] else 4.0
		for i in range(points.size()-1):
			var p := Vector3(points[i][0],0.025,points[i][1])
			var q := Vector3(points[i+1][0],0.025,points[i+1][1])
			var d := q-p
			if d.length() < 0.2:
				continue
			var basis := Basis(Vector3.UP,atan2(d.x,d.z)).scaled_local(Vector3(width,1,d.length()+0.2))
			transforms.append(Transform3D(basis,(p+q)/2))
			if not map_loaded and d.length()>15 and width>=7:
				map_spawn = (p+q)/2 + Vector3(0,0.85,0)
				map_loaded = true
	if transforms.is_empty():
		return false
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = road_mesh
	batch.instance_count = transforms.size()
	for i in range(transforms.size()):
		batch.set_instance_transform(i,transforms[i])
	var roads := MultiMeshInstance3D.new()
	roads.multimesh = batch
	roads.material_override = asphalt
	add_child(roads)
	for building in data.get("buildings",[]):
		var points: Array = building["points"]
		if points.size()<4:
			continue
		var polygon := PackedVector2Array()
		for i in range(points.size()-1):
			polygon.append(Vector2(points[i][0],points[i][1]))
		if Geometry2D.triangulate_polygon(polygon).is_empty():
			continue
		var center := Vector2.ZERO
		for p in polygon:
			center += p
		center /= polygon.size()
		var local := PackedVector2Array()
		for p in polygon:
			local.append(p-center)
		var shape := CSGPolygon3D.new()
		shape.polygon = local
		shape.depth = 5
		shape.rotation_degrees.x = 90
		shape.position = Vector3(center.x,5,center.y)
		shape.material = material(Color(0.7,0.63,0.52))
		add_child(shape)
	map_loaded = true
	return true
