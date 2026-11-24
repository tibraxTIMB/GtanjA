extends RefCounted
# Provisional gameplay geometry, not a certified load calculator.
const EMPTY_MASS := 230.0
const HITCH_DISTANCE := 2.6
const GRAVITY := 9.81
var items: Array[Dictionary] = []

func add_item(mass_kg: float, position: Vector3, friction: float = 0.35) -> bool:
	if mass_kg <= 0 or absf(position.x)>0.65 or absf(position.z)>1.2:
		return false
	items.append({"mass":mass_kg,"position":position,"friction":clampf(friction,0.0,1.0),"secured":false})
	return true

func secure(index: int, secured: bool) -> void:
	if index >= 0 and index < items.size():
		items[index]["secured"] = secured

func total_mass() -> float:
	var result := EMPTY_MASS
	for item in items:
		result += float(item["mass"])
	return result

func center_of_mass() -> Vector3:
	var moment := Vector3.ZERO
	for item in items:
		var position: Vector3 = item["position"]
		moment += position*float(item["mass"])
	return moment/total_mass()

func hitch_load_kg() -> float:
	# Static moment balance around axle at local z=0.
	return total_mass()*center_of_mass().z/HITCH_DISTANCE

func shift_load(acceleration: Vector3, delta: float) -> void:
	for item in items:
		if item["secured"]:
			continue
		var horizontal := Vector3(acceleration.x,0,acceleration.z)
		var excess := maxf(0.0,horizontal.length()-float(item["friction"])*GRAVITY)
		var position: Vector3 = item["position"]
		position -= horizontal.normalized()*excess*delta*delta*0.5
		position.x = clampf(position.x,-0.65,0.65)
		position.z = clampf(position.z,-1.2,1.2)
		item["position"] = position

func apply_to(body: RigidBody3D) -> void:
	body.mass = total_mass()
	body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	body.center_of_mass = center_of_mass()
