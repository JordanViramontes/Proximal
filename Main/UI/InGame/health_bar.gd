extends TextureProgressBar

@export var ui_manager: Control
var health_component: Node

func _ready():
	ui_manager.manager_ready.connect(on_ui_manager_ready)

func on_ui_manager_ready():
	health_component = ui_manager.player_ui_manager.health_component
	if health_component:
		health_component.health_change.connect(update)
		update()
	else:
		print("HealthBar HealthComponent not assigned!")


func update():
	value = health_component.current_health * 100 / health_component.max_health
