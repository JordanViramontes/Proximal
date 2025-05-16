extends Label

var time_left: int = 0
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")
func _ready() -> void:
	enemy_spawn_path.updateWaveTimer.connect(update_time)

func _process(delta: float):
	text = "Time Left: " + str(time_left)

func update_time(time: int):
	time_left = time
