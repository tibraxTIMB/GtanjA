extends Node3D
const Engineering = preload("res://hitch_engineering.gd")
var model = Engineering.new()
var crank: Node3D
var handle: Node3D
var cable: MeshInstance3D
var plug: Node3D
var lid: Node3D
var wheel: Node3D
var status: Label
var camera: Camera3D
var selected := "sveiv"
var orbit := 0.0
var zoom := 2.4

func part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	mat.roughness = 0.35
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func pivot(pos: Vector3) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	return node

func _ready() -> void:
	var silver := Color(0.65,0.68,0.7)
	var dark := Color(0.12,0.13,0.14)
	part(self,Vector3(0,0.45,0.65),Vector3(0.12,0.12,1.2),silver)
	part(self,Vector3(0,0.45,0),Vector3(0.18,0.16,0.3),silver)
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	ball.mesh = sphere
	add_child(ball)
	ball.position = Vector3(0,0.43,-0.12)
	crank = pivot(Vector3(0.22,0.85,0.3))
	part(crank,Vector3(0.1,0,0),Vector3(0.2,0.025,0.025),silver)
	part(crank,Vector3(0.2,0.04,0),Vector3(0.04,0.08,0.04),dark)
	wheel = pivot(Vector3(0.22,0.2,0.3))
	part(wheel,Vector3(0,0.2,0),Vector3(0.045,0.4,0.045),silver)
	var tire := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.1
	cylinder.height = 0.055
	tire.mesh = cylinder
	wheel.add_child(tire)
	tire.rotation.z = PI/2
	plug = pivot(Vector3(-0.3,0.45,0.1))
	part(plug,Vector3.ZERO,Vector3(0.07,0.07,0.12),dark)
	part(self,Vector3(-0.3,0.45,-0.15),Vector3(0.1,0.1,0.06),dark)
	lid = pivot(Vector3(-0.3,0.51,-0.11))
	part(lid,Vector3(0,-0.045,0),Vector3(0.1,0.09,0.015),dark)
	handle = pivot(Vector3(0,0.54,0.04))
	part(handle,Vector3(0,0.025,0.09),Vector3(0.055,0.045,0.22),silver)
	for i in range(13):
		var angle := TAU*float(i)/13.0
		var pin := MeshInstance3D.new()
		var pin_shape := CylinderMesh.new()
		pin_shape.top_radius = 0.002
		pin_shape.bottom_radius = 0.002
		pin_shape.height = 0.012
		pin.mesh = pin_shape
		plug.add_child(pin)
		pin.rotation.x = PI/2
		pin.position = Vector3(cos(angle)*0.025,sin(angle)*0.025,-0.065)
		var brass := StandardMaterial3D.new()
		brass.albedo_color = Color(0.75,0.58,0.22)
		brass.metallic = 0.8
		pin.material_override = brass
	cable = MeshInstance3D.new()
	add_child(cable)
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-45,-30,0)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := VBoxContainer.new()
	hud.add_child(panel)
	panel.position = Vector2(12,12)
	status = Label.new()
	panel.add_child(status)
	for action in ["sveiv","støpsel","kamera","opne lok","set inn","lås støpsel","fest wire","kulekopling","løys klemme","hev nasehjul","test lys"]:
		var button := Button.new()
		button.text = action
		panel.add_child(button)
		button.pressed.connect(func(): operate(action))
	refresh()

func operate(action: String) -> void:
	match action:
		"sveiv","støpsel","kamera": selected = action
		"opne lok": model.lid_open = true
		"set inn": model.insert_plug()
		"lås støpsel": model.lock_plug()
		"fest wire": model.wire_attached = true
		"kulekopling": model.seat_ball(0.0)
		"løys klemme": model.clamp_locked = false
		"hev nasehjul": model.stow_wheel()
		"test lys":
			for pin in [1,2,4,5,6,7,8]:
				model.test_circuit(pin)
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var amount: float = event.relative.x
		match selected:
			"sveiv":
				model.crank(amount/100.0)
				crank.rotation.y += amount*0.03
			"støpsel": model.rotate_plug(amount*0.5)
			"kamera": orbit += amount*0.01
		refresh()

func refresh() -> void:
	handle.rotation.x = -0.8 if model.handle_open else 0.0
	var wire := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2,0.2,0.2)
	wire.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,mat)
	for i in range(25):
		var t := float(i)/24.0
		var endpoint := Vector3(0.05,0.43,-0.12) if model.wire_attached else Vector3(0.25,0.25,0.25)
		var point := Vector3(0.1,0.45,0.5).lerp(endpoint,t)
		point.y -= sin(t*PI)*0.15
		wire.surface_add_vertex(point)
	wire.surface_end()
	cable.mesh = wire
	wheel.position.y = 0.2+(model.height_mm-430.0)/1000.0
	if model.wheel_stowed:
		wheel.position.y = 0.5
	plug.rotation.z = deg_to_rad(model.plug_angle)
	plug.position.z = -0.07 if model.plug_inserted else 0.1
	lid.rotation.x = -PI/2 if model.lid_open else 0.0
	camera.position = Vector3(sin(orbit)*zoom,1.3,cos(orbit)*zoom)
	camera.look_at(Vector3(0,0.45,0))
	status.text = "%d mm | %s | %s" % [roundi(model.height_mm),"Låst støpsel" if model.plug_locked else "Støpsel ope","KLAR" if model.ready_to_drive() else "IKKJE KLAR"]
