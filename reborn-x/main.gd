extends Node3D

var map_spawn := Vector3(0,0.85,-40)
var map_loaded := false
var map_heading := 0.0
var terrain = null

func ground_height(x:float,z:float) -> float:
	if terrain != null:
		var h: float = terrain.height_at(x,z)
		if is_finite(h):
			return h
	return 0.0
var car: VehicleBody3D
var trailer: RigidBody3D
var camera: Camera3D
var steering := 0.0
var throttle := false
var braking := false
var reverse := false
var speed_label: Label
var traffic: Array[Dictionary] = []
var traffic_route: Array[Vector3] = []
var motor_audio: AudioStreamPlayer3D
var camera_mode := 0
var camera_distance := 12.0
var mission_stage := 0
var hitch: PinJoint3D
var cargo_mass := 0.0
var cargo = preload("res://cargo_engineering.gd").new()
var cargo_meshes: Array[MeshInstance3D] = []
var cargo_selected := -1
var cargo_kind := 0
var sorted_count := 0
var sorting_bays: Array[Vector3] = []
var sorting_errors := 0
var sorting_feedback := ""
const SORT_NAMES = ["Hageavfall","Jord","Stein","Møblar"]
const TEST_PAYLOAD_LIMIT := 520.0
var cargo_straps: Array[MeshInstance3D] = []
const CARGO_TYPES = [
	{"name":"Kvist","mass":25.0,"friction":0.55,"size":Vector3(0.55,0.45,0.65),"color":Color(0.32,0.43,0.18)},
	{"name":"Jord","mass":100.0,"friction":0.5,"size":Vector3(0.55,0.35,0.55),"color":Color(0.32,0.21,0.12)},
	{"name":"Stein","mass":150.0,"friction":0.65,"size":Vector3(0.45,0.35,0.45),"color":Color(0.48,0.49,0.5)},
	{"name":"Møblar","mass":45.0,"friction":0.3,"size":Vector3(0.55,0.65,0.55),"color":Color(0.65,0.43,0.24)}
]
var cargo_touch := -1
var previous_trailer_velocity := Vector3.ZERO
var tailgate: Node3D
var tailgate_open := false
var tailgate_locked := true
var tailgate_latches: Array[bool] = [true,true]
var latch_meshes: Array[Node3D] = []
var gate_drag := false
var gate_touch := -1
var gate_angle := 0.0
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
	car.rotation.y = map_heading
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
	trailer.position = car.position + car.basis * Vector3(0,0,-4.8)
	trailer.rotation.y = map_heading
	add_shape(trailer, Vector3(1.65,0.25,2.8), Vector3.ZERO)
	block(trailer, Vector3.ZERO, Vector3(1.65,0.25,2.8), Color.SILVER)
	for x in [-0.8,0.8]:
		block(trailer, Vector3(x,0.4,0), Vector3(0.08,0.65,2.8), Color.SILVER)
	for x in [-0.92,0.92]:
		var tire_body := RigidBody3D.new()
		tire_body.mass = 12
		add_child(tire_body)
		tire_body.position = trailer.position + trailer.basis * Vector3(x,-0.35,0)
		tire_body.rotation.y = map_heading
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
		axle.rotation.y = map_heading + PI/2
		axle.node_a = axle.get_path_to(trailer)
		axle.node_b = axle.get_path_to(tire_body)
	tailgate = Node3D.new()
	trailer.add_child(tailgate)
	tailgate.position = Vector3(0,0.075,-1.4)
	block(tailgate,Vector3(0,0.325,0),Vector3(1.65,0.65,0.08),Color.SILVER)
	for x in [-0.72,0.72]:
		var latch := Node3D.new()
		tailgate.add_child(latch)
		latch.position = Vector3(x,0.56,-0.06)
		block(latch,Vector3(0,0.04,0),Vector3(0.08,0.15,0.06),Color(0.25,0.27,0.29))
		latch_meshes.append(latch)
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
	joint.position = car.position + car.basis * Vector3(0,0,-2.2)
	joint.node_a = joint.get_path_to(car)
	joint.node_b = joint.get_path_to(trailer)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.position = car.position + car.basis * Vector3(0,6,-12)
	if map_loaded:
		destination = map_spawn + car.basis * Vector3(0,0,25)
		var site = JSON.parse_string(FileAccess.get_file_as_string("res://data/sandvenhagen-local.json")) if FileAccess.file_exists("res://data/sandvenhagen-local.json") else null
		if site is Dictionary and site.get("crs", "") == "EPSG:25832":
			var point = site.get("address_point", [])
			if point is Array and point.size() == 2:
				destination = Vector3(float(point[0]),0,float(point[1]))
		destination.y = ground_height(destination.x,destination.z)
	else:
		block(self,Vector3(80,0.05,100),Vector3(12,0.1,12),Color(0.8,0.65,0.15))
		for i in range(3):
			block(self,Vector3(90+i*5,1.2,110),Vector3(4,2.4,3),Color(0.2,0.45,0.35),true)
	var saved := ConfigFile.new()
	if saved.load("user://reborn_x_career.cfg") == OK:
		career_xp = int(saved.get_value("career","xp",0))
		career_jobs = int(saved.get_value("career","jobs",0))
	setup_sorting_bays()
	setup_traffic()
	setup_audio()
	var hud := CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	hud.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_label = Label.new()
	root.add_child(speed_label)
	speed_label.position = Vector2(24,18)
	speed_label.add_theme_font_size_override("font_size",32)
	mission_label = Label.new()
	root.add_child(mission_label)
	mission_label.position = Vector2(24,100)
	mission_label.hide()
	map_label = Label.new()
	root.add_child(map_label)
	map_label.position = Vector2(24,60)
	var tools := GridContainer.new()
	tools.columns = 3
	root.add_child(tools)
	tools.position = Vector2(350,150)
	tools.hide()
	for action in ["KOPLING","LAST","V LÅS","H LÅS","BAKLUKE","SIKRE","LASTTYPE","LOSS","SORTER"]:
		var b := Button.new()
		b.text = action
		b.custom_minimum_size = Vector2(170,65)
		tools.add_child(b)
		b.button_down.connect(func(): control(action,true))
		b.button_up.connect(func(): control(action,false))
	var menu := Button.new()
	menu.text = "PARKERING / TANJA"
	root.add_child(menu)
	menu.position = Vector2(24,105)
	menu.size = Vector2(245,55)
	menu.pressed.connect(func():
		if car.linear_velocity.length()<0.5:
			tools.visible = not tools.visible
			mission_label.visible = tools.visible
	)
	for spec in [["KAMERA",Vector2(980,20),Vector2(130,65)],["ZOOM",Vector2(1120,20),Vector2(130,65)],["D/R",Vector2(1120,350),Vector2(130,75)]]:
		var b := Button.new()
		b.text = spec[0]
		root.add_child(b)
		b.position = spec[1]
		b.size = spec[2]
		var action: String = spec[0]
		b.pressed.connect(func(): control(action,true))
	wheel_panel = Control.new()
	root.add_child(wheel_panel)
	wheel_panel.position = Vector2(30,420)
	wheel_panel.size = Vector2(260,260)
	wheel_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wheel_panel.draw.connect(func():
		var c := Vector2(130,130)
		wheel_panel.draw_circle(c,120,Color(0.08,0.10,0.12,0.8))
		wheel_panel.draw_arc(c,110,0,TAU,80,Color(0.85,0.87,0.9),15,true)
		for a in [0.0,TAU/3,2*TAU/3]:
			wheel_panel.draw_line(c,c+Vector2.from_angle(a+wheel_angle)*105,Color(0.85,0.87,0.9),12,true)
		wheel_panel.draw_circle(c,30,Color(0.25,0.28,0.3))
	)
	for spec in [["BREMS",Vector2(960,520),Vector2(125,160)],["GASS",Vector2(1100,455),Vector2(150,225)]]:
		var pedal := Label.new()
		root.add_child(pedal)
		pedal.position = spec[1]
		pedal.size = spec[2]
		pedal.text = spec[0]
		pedal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pedal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pedal.add_theme_font_size_override("font_size",28)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12,0.18,0.15,0.85)
		style.set_corner_radius_all(18)
		style.set_border_width_all(3)
		style.border_color = Color.WHITE
		pedal.add_theme_stylebox_override("normal",style)
		pedal.mouse_filter = Control.MOUSE_FILTER_IGNORE

var pedal_touches: Dictionary = {}

func drive_touch(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index == wheel_touch:
				wheel_touch = -1
				return true
			if pedal_touches.has(event.index):
				pedal_touches.erase(event.index)
				throttle = pedal_touches.values().has("GASS")
				braking = pedal_touches.values().has("BREMS")
				return true
		else:
			if Rect2(30,420,260,260).has_point(event.position) and wheel_touch == -1:
				wheel_touch = event.index
				wheel_last = (event.position-Vector2(160,550)).angle()
				return true
			for spec in [["GASS",Rect2(1100,455,150,225)],["BREMS",Rect2(960,520,125,160)]]:
				if spec[1].has_point(event.position):
					pedal_touches[event.index] = spec[0]
					throttle = pedal_touches.values().has("GASS")
					braking = pedal_touches.values().has("BREMS")
					return true
	elif event is InputEventScreenDrag:
		if event.index == wheel_touch:
			var bearing: float = (event.position-Vector2(160,550)).angle()
			wheel_angle = clampf(wheel_angle+wrapf(bearing-wheel_last,-PI,PI),-PI,PI)
			wheel_last = bearing
			return true
		if pedal_touches.has(event.index):
			return true
	return false

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
		"V LÅS","H LÅS":
			if pressed and gate_angle < 0.03 and trailer.linear_velocity.length()<0.2:
				var index := 0 if label == "V LÅS" else 1
				tailgate_latches[index] = not tailgate_latches[index]
				tailgate_locked = tailgate_latches[0] and tailgate_latches[1]
				latch_meshes[index].rotation.z = 0.0 if tailgate_latches[index] else PI/2
		"BAKLUKE":
			if not tailgate_latches[0] and not tailgate_latches[1] and trailer.linear_velocity.length()<0.2:
				gate_drag = pressed
			else:
				gate_drag = false
		"LASTTYPE":
			if pressed:
				cargo_kind = (cargo_kind+1)%CARGO_TYPES.size()
		"LAST":
			if pressed and tailgate_open and trailer.linear_velocity.length()<0.2:
				if cargo.items.size()<3:
					var pos := Vector3(0,0.4,-0.8+0.8*cargo.items.size())
					var kind: Dictionary = CARGO_TYPES[cargo_kind]
					if cargo.add_item(kind["mass"],pos,kind["friction"]):
						cargo.items[-1]["kind"] = cargo_kind
						var mesh := MeshInstance3D.new()
						var crate := BoxMesh.new()
						crate.size = kind["size"]
						mesh.mesh = crate
						mesh.material_override = material(Color(0.45,0.3,0.16))
						trailer.add_child(mesh)
						cargo_meshes.append(mesh)
						cargo_selected = cargo.items.size()-1
				else:
					for mesh in cargo_meshes:
						mesh.queue_free()
					cargo_meshes.clear()
					cargo.items.clear()
					cargo_selected = -1
				refresh_cargo()
		"SORTER":
			if pressed and tailgate_open and trailer.linear_velocity.length()<0.2 and cargo_selected>=0 and cargo_selected<cargo.items.size():
				if nearest_sorting_bay() < 0:
					sorting_feedback = "Køyr til leveringsområdet først"
				elif cargo.items[cargo_selected]["secured"]:
					sorting_feedback = "Frigjer spennbandet først"
				elif nearest_sorting_bay() != int(cargo.items[cargo_selected].get("kind",0)):
					sorting_errors += 1
					sorting_feedback = "BIR-Berit: Feil sortering!"
				else:
					sorted_count += 1
					career_xp += 25
					sorting_feedback = "Godkjend sortering: "+SORT_NAMES[nearest_sorting_bay()]
					control("LOSS",true)
					var saved := ConfigFile.new()
					saved.set_value("career","xp",career_xp)
					saved.set_value("career","jobs",career_jobs)
					saved.save("user://reborn_x_career.cfg")
		"LOSS":
			if pressed and tailgate_open and trailer.linear_velocity.length()<0.2 and cargo_selected>=0 and cargo_selected<cargo.items.size():
				if not cargo.items[cargo_selected]["secured"]:
					cargo_meshes[cargo_selected].queue_free()
					cargo_meshes.remove_at(cargo_selected)
					cargo.items.remove_at(cargo_selected)
					cargo_selected = cargo.items.size()-1
					refresh_cargo()
		"SIKRE":
			if pressed and cargo_selected>=0 and trailer.linear_velocity.length()<0.2:
				cargo.secure(cargo_selected,not cargo.items[cargo_selected]["secured"])
				refresh_cargo()
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
	var acceleration := trailer.global_basis.inverse() * (trailer.linear_velocity-previous_trailer_velocity)/maxf(delta,0.001)
	previous_trailer_velocity = trailer.linear_velocity
	if not cargo.items.is_empty():
		cargo.shift_load(acceleration,delta)
		refresh_cargo()
	if is_instance_valid(tailgate):
		tailgate.rotation.x = -gate_angle
		tailgate_open = gate_angle > 1.45
		if trailer.linear_velocity.length()>0.2:
			gate_drag = false
	update_traffic(delta)
	if is_instance_valid(motor_audio):
		motor_audio.pitch_scale = 0.8 + clampf(car.linear_velocity.length()/18.0,0.0,1.0)*1.4
		motor_audio.volume_db = -24.0 if throttle else -32.0
	if wheel_touch == -1:
		wheel_angle = lerpf(wheel_angle,0.0,minf(delta*8,1))
	if is_instance_valid(wheel_panel):
		wheel_panel.queue_redraw()
	var distance := car.global_position.distance_to(destination)
	var relative := destination-car.global_position
	var bearing := wrapf(atan2(relative.x,relative.z)-car.rotation.y,-PI,PI)
	map_label.text = "GPS: %d m | %s" % [roundi(distance), "høgre" if bearing>0.25 else ("venstre" if bearing < -0.25 else "rett fram")]
	if mission_stage == 0 and distance < 8 and car.linear_velocity.length()<1:
		if hitch.node_b != NodePath("") and cargo_mass>0 and tailgate_locked and gate_angle < 0.03:
			mission_stage = 1
			career_xp += 100
			career_jobs += 1
			var saved := ConfigFile.new()
			saved.set_value("career","xp",career_xp)
			saved.set_value("career","jobs",career_jobs)
			saved.save("user://reborn_x_career.cfg")
	mission_label.text = ("Last Tanja og lever ved GPS-målet" if mission_stage == 0 else "Oppdrag fullført") + " | %d XP | %d kg | %s" % [career_xp,roundi(cargo_mass),"Kopla" if hitch.node_b != NodePath("") else "Fråkopla"]
	mission_label.text += "\nLasttype: %s | Kuletrykkbidrag: %.1f kg" % [CARGO_TYPES[cargo_kind]["name"],cargo.hitch_load_kg()]
	mission_label.text += "\nSortering: %s | Rett: %d | Feil: %d | %s" % [SORT_NAMES[cargo_kind],sorted_count,sorting_errors,sorting_feedback]
	if cargo_mass > TEST_PAYLOAD_LIMIT:
		mission_label.text += " | OVERLAST (testgrense)"
	elif cargo.hitch_load_kg() < 0:
		mission_label.text += " | Negativt kuletrykkbidrag"
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
	var candidate = preload("res://terrain_grid.gd").new()
	# Only combine datasets explicitly projected to the shared origin.
	if data.get("crs","") == "EPSG:25832" and candidate.load_grid():
		terrain = candidate
		add_child(terrain)
		terrain.build()
	else:
		candidate.free()
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
			p.y = ground_height(p.x,p.z)+0.06
			q.y = ground_height(q.x,q.z)+0.06
			var d := q-p
			if d.length() < 0.2:
				continue
			var basis := Basis.looking_at(d,Vector3.UP,true) * Basis.from_scale(Vector3(width,1,d.length()+0.2))
			transforms.append(Transform3D(basis,(p+q)/2))
			if not map_loaded and d.length()>15 and width>=7:
				map_spawn = (p+q)/2 + Vector3(0,0.85,0)
				map_heading = atan2(d.x,d.z)
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
		shape.use_collision = true
		shape.rotation_degrees.x = 90
		shape.position = Vector3(center.x,ground_height(center.x,center.y),center.y)
		shape.material = material(Color(0.7,0.63,0.52))
		add_child(shape)
	map_loaded = true
	return true

func setup_traffic() -> void:
	if map_loaded:
		return
	traffic_route = [Vector3(-80,0,-100),Vector3(80,0,-100),Vector3(80,0,100),Vector3(-80,0,100)]
	for i in range(3):
		var vehicle := AnimatableBody3D.new()
		add_child(vehicle)
		vehicle.position = traffic_route[i]
		add_shape(vehicle,Vector3(1.8,1.1,4.2),Vector3(0,0.8,0))
		block(vehicle,Vector3(0,0.7,0),Vector3(1.8,0.7,4.2),Color(0.2,0.35+i*0.15,0.65))
		block(vehicle,Vector3(0,1.3,0),Vector3(1.6,0.6,2),Color(0.25,0.4,0.5))
		traffic.append({"body":vehicle,"next":(i+1)%4,"speed":0.0})

func update_traffic(delta: float) -> void:
	for entry in traffic:
		var vehicle: AnimatableBody3D = entry["body"]
		var target: Vector3 = traffic_route[entry["next"]]
		var direction := target-vehicle.position
		if direction.length()<0.5:
			entry["next"] = (int(entry["next"])+1)%traffic_route.size()
			continue
		direction = direction.normalized()
		var blocked := false
		for obstacle in [car,trailer]:
			var relative: Vector3 = obstacle.global_position-vehicle.global_position
			relative.y = 0
			if relative.length()<12 and relative.dot(direction)>0 and relative.cross(direction).length()<3:
				blocked = true
		for other in traffic:
			if other == entry:
				continue
			var relative: Vector3 = other["body"].global_position-vehicle.global_position
			if relative.length()<12 and relative.dot(direction)>0 and relative.cross(direction).length()<3:
				blocked = true
		entry["speed"] = move_toward(float(entry["speed"]),0.0 if blocked else 8.0,delta*4)
		vehicle.rotation.y = atan2(direction.x,direction.z)
		vehicle.position += direction*float(entry["speed"])*delta

func setup_audio() -> void:
	var sample_rate := 22050
	var samples := PackedByteArray()
	samples.resize(sample_rate*2)
	for i in range(sample_rate):
		var t := float(i)/sample_rate
		var value := sin(TAU*40*t)*0.45+sin(TAU*80*t)*0.25+sin(TAU*120*t)*0.1
		samples.encode_s16(i*2,roundi(value*12000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = samples
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = sample_rate
	motor_audio = AudioStreamPlayer3D.new()
	car.add_child(motor_audio)
	motor_audio.stream = stream
	motor_audio.volume_db = -32
	motor_audio.play()

func _input(event: InputEvent) -> void:
	if drive_touch(event):
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(camera) and is_instance_valid(trailer) and tailgate_open and trailer.linear_velocity.length()<0.2:
		if event is InputEventScreenTouch and event.pressed:
			for i in range(cargo_meshes.size()):
				var point := cargo_meshes[i].global_position
				if not camera.is_position_behind(point) and camera.unproject_position(point).distance_to(event.position)<30:
					cargo_selected = i
					cargo_touch = event.index
					get_viewport().set_input_as_handled()
					return
		if event is InputEventScreenDrag and event.index == cargo_touch and cargo_selected>=0:
			if not cargo.items[cargo_selected]["secured"]:
				var pos: Vector3 = cargo.items[cargo_selected]["position"]
				pos.z = clampf(pos.z-event.relative.y*0.005,-1.2,1.2)
				pos.x = clampf(pos.x+event.relative.x*0.005,-0.65,0.65)
				cargo.items[cargo_selected]["position"] = pos
				refresh_cargo()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenTouch and not event.pressed and event.index == cargo_touch:
		cargo_touch = -1
		return
	if not is_instance_valid(tailgate) or not is_instance_valid(camera):
		return
	if event is InputEventScreenTouch and event.pressed and trailer.linear_velocity.length()<0.2:
		if event.position.y < get_viewport().get_visible_rect().size.y-110:
			for i in range(latch_meshes.size()):
				var point := latch_meshes[i].global_position
				if not camera.is_position_behind(point) and camera.unproject_position(point).distance_to(event.position)<24:
					control("V LÅS" if i == 0 else "H LÅS",true)
					get_viewport().set_input_as_handled()
					return
			var gate_point := tailgate.to_global(Vector3(0,0.32,0))
			if not camera.is_position_behind(gate_point) and camera.unproject_position(gate_point).distance_to(event.position)<48 and not tailgate_latches[0] and not tailgate_latches[1]:
				gate_touch = event.index
				gate_drag = true
				get_viewport().set_input_as_handled()
				return
	if event is InputEventScreenDrag and gate_touch == event.index and gate_drag:
		gate_angle = clampf(gate_angle + event.relative.y*0.008,0.0,PI/2)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and not event.pressed and gate_touch == event.index:
		gate_touch = -1
		gate_drag = false
		get_viewport().set_input_as_handled()
		return
	if gate_drag and event is InputEventScreenDrag and not tailgate_latches[0] and not tailgate_latches[1]:
		gate_angle = clampf(gate_angle + event.relative.y*0.008,0.0,PI/2)
	if event is InputEventScreenTouch and not event.pressed:
		gate_drag = false

func refresh_cargo() -> void:
	for strap in cargo_straps:
		strap.queue_free()
	cargo_straps.clear()
	cargo_mass = cargo.total_mass()-230.0
	cargo.apply_to(trailer)
	for i in range(cargo_meshes.size()):
		cargo_meshes[i].position = cargo.items[i]["position"]
		if cargo.items[i]["secured"]:
			var strap := MeshInstance3D.new()
			var shape := BoxMesh.new()
			shape.size = Vector3(1.5,0.025,0.045)
			strap.mesh = shape
			strap.material_override = material(Color(0.95,0.55,0.08))
			trailer.add_child(strap)
			strap.position = Vector3(0,cargo_meshes[i].position.y+0.35,cargo_meshes[i].position.z)
			cargo_straps.append(strap)
		var mat: StandardMaterial3D = cargo_meshes[i].material_override
		mat.albedo_color = Color(0.25,0.55,0.3) if cargo.items[i]["secured"] else CARGO_TYPES[int(cargo.items[i].get("kind",0))]["color"]

func setup_sorting_bays() -> void:
	# Fictional test layout; not a surveyed BIR facility.
	for i in range(4):
		var pos := destination + Vector3((i-1.5)*6.0,0,10)
		pos.y = ground_height(pos.x,pos.z)
		pos.y = ground_height(pos.x,pos.z)
		sorting_bays.append(pos-Vector3(0,0,4))
		var color := Color(0.22,0.42,0.32)
		block(self,pos+Vector3(0,0.15,0),Vector3(4,0.3,3),color,true)
		for x in [-1.9,1.9]:
			block(self,pos+Vector3(x,1.1,0),Vector3(0.15,2,3),color,true)
		block(self,pos+Vector3(0,1.1,1.45),Vector3(4,2,0.15),color,true)
		block(self,sorting_bays[i]+Vector3(0,0.04,0),Vector3(4,0.05,5),Color(0.7,0.6,0.2))
		var sign := Label3D.new()
		add_child(sign)
		sign.position = pos+Vector3(0,2.5,0)
		sign.text = SORT_NAMES[i]
		sign.font_size = 64
		sign.pixel_size = 0.015
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func nearest_sorting_bay() -> int:
	var best := -1
	var distance := 2.8
	for i in range(sorting_bays.size()):
		var d := Vector2(trailer.global_position.x-sorting_bays[i].x,trailer.global_position.z-sorting_bays[i].z).length()
		if d < distance:
			best = i
			distance = d
	return best
