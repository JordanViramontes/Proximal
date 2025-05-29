extends Label

# variables
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")
var time_left: float = 0.0
var is_counting = false

func _ready() -> void:
	enemy_spawn_path.updateWaveTimer.connect(self._on_get_new_timer)
	enemy_spawn_path.stopWaveTimer.connect(self._on_stop_timer)

func _process(delta: float) -> void:
	if time_left > 0 && is_counting:
		time_left -= delta
	
	text = str(int(floor(time_left)))

func _on_get_new_timer(time: float):
	time_left = time
	is_counting = true

func _on_stop_timer():
	print("stopping!")
	is_counting = false
