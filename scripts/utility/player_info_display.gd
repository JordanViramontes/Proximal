extends Label

@export var player: Player

func _process(delta):
	if not player: return
	text = "speed: " + str(player.velocity.length()) + \
			"\nis_on_floor: " + str(player.is_on_floor())
