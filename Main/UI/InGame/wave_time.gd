extends Label

# variables
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")
var time_left: float = 0.0

func _ready() -> void:
	enemy_spawn_path.updateWaveTimer.connect(self._on_get_new_timer)

func _process(delta: float) -> void:
	if time_left > 0:
		time_left -= delta
	
	text = str(int(floor(time_left)))

func _on_get_new_timer(time: float):
	time_left = time
