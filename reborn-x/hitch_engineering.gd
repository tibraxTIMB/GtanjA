extends RefCounted
# Game approximation, not a certified coupling procedure.
enum Connector { SEVEN, THIRTEEN }
var connector := Connector.THIRTEEN
var height_mm := 430.0
var ball_height_mm := 430.0
var clamp_locked := true
var wheel_stowed := false
var handle_open := true
var latched := false
var wire_attached := false
var lid_open := false
var plug_angle := 0.0
var plug_inserted := false
var plug_locked := false
var ground_ok := true
var failed_circuits: Array[int] = []
var checked_circuits: Array[int] = []

func crank(turns: float) -> void:
	if not wheel_stowed and clamp_locked:
		height_mm = clampf(height_mm + turns*4.0,300.0,650.0)

func seat_ball(horizontal_error_mm: float) -> bool:
	if not handle_open or absf(height_mm-ball_height_mm)>8 or absf(horizontal_error_mm)>12:
		return false
	latched = true
	handle_open = false
	return true

func release_ball() -> bool:
	if wheel_stowed or wire_attached or plug_inserted:
		return false
	latched = false
	handle_open = true
	return true

func stow_wheel() -> bool:
	if not latched or clamp_locked:
		return false
	wheel_stowed = true
	clamp_locked = true
	return true

func rotate_plug(degrees: float) -> void:
	if not plug_locked:
		plug_angle = wrapf(plug_angle+degrees,-180.0,180.0)

func insert_plug() -> bool:
	if not lid_open or absf(plug_angle)>8:
		return false
	plug_inserted = true
	plug_locked = connector == Connector.SEVEN
	return true

func lock_plug() -> bool:
	if not plug_inserted:
		return false
	if connector == Connector.THIRTEEN and absf(plug_angle-90.0)>8:
		return false
	plug_locked = true
	return true

func unplug() -> void:
	if connector == Connector.SEVEN or absf(plug_angle)<8:
		plug_locked = false
		plug_inserted = false
		checked_circuits.clear()

func test_circuit(pin: int) -> bool:
	var supported := [1,2,4,5,6,7]
	if connector == Connector.THIRTEEN:
		supported.append(8)
	var ok := plug_inserted and plug_locked and ground_ok and pin in supported and not pin in failed_circuits
	if ok and not pin in checked_circuits:
		checked_circuits.append(pin)
	return ok

func ready_to_drive() -> bool:
	return latched and wire_attached and wheel_stowed and clamp_locked and plug_locked and ground_ok and checked_circuits.size() >= (7 if connector == Connector.THIRTEEN else 6)
