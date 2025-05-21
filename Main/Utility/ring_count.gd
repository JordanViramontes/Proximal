extends Label

@export var ring: WeaponBase

func _process(delta):
	if not ring: return
	text = "Ring: " + str(ring.ammo_count)
