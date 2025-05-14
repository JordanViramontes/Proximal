extends TextureProgressBar

@export var health_component: Node

func _ready():
	if health_component:
		health_component.health_change.connect(update)
		update()
	else:
		print("HealthComponent not assigned!")

func update():
	value = health_component.current_health * 100 / health_component.max_health
