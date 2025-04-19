extends TextureProgressBar

@export var player: Player

func _ready():
	player.health_change.connect(update)
	update()

func update():
	value = player.current_health * 100 / player.MAX_HEALTH
