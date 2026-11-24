extends RefCounted
# Sources: https://bir.no/åpningstider-i-miljoeparkene/kvam/
# https://bir.no/media/12077/aarsrapport_2022_.pdf
# https://bir.no/bli-kvitt-boss/sortering-i-miljoeparken/
# Functional topology only; no surveyed coordinates.
const ADDRESS = "Gamle Dalavegen 110"
const PAID = ["Hageavfall","Masser med organisk innhald","Masser med uorganisk innhald","Store øydelagde gjenstandar"]
const FREE = ["Ombruk","EE-avfall","Farleg avfall","Papp og papir","Glas- og metallemballasje","Plastemballasje"]
enum Zone { OUTSIDE, FREE_ZONE, SCALE, PAID_ZONE, EXIT }
var zone := Zone.OUTSIDE
var entry_weight := 0.0
var delivered_kg := 0.0
func is_open(day: int, hour: float) -> bool:
	# Monday=1, Sunday=7. Ordinary hours; holidays not modelled.
	if day in [1,3,5]:
		return hour>=12 and hour<19
	return day==6 and hour>=9 and hour<16
func enter(day: int,hour: float) -> bool:
	if zone != Zone.OUTSIDE or not is_open(day,hour):
		return false
	zone = Zone.FREE_ZONE
	delivered_kg = 0.0
	return true
func weigh(mass: float) -> bool:
	if zone != Zone.FREE_ZONE or mass<=0:
		return false
	entry_weight = mass
	zone = Zone.SCALE
	return true
func enter_paid() -> bool:
	if zone != Zone.SCALE:
		return false
	zone = Zone.PAID_ZONE
	return true
func deliver(category: String,mass: float) -> bool:
	if mass<=0:
		return false
	if zone==Zone.FREE_ZONE and category in FREE:
		return true
	if zone==Zone.PAID_ZONE and category in PAID:
		delivered_kg += mass
		return true
	return false
func leave() -> void:
	zone = Zone.OUTSIDE
