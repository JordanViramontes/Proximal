extends Label

var time_left: int = 0
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")

func _ready() -> void:
	self.visible = false
	enemy_spawn_path.updateNextWaveTimer.connect(update_time)
	enemy_spawn_path.updateNextWaveVisibility.connect(update_visibility)

func _process(delta: float):
	text = "NEXT WAVE SPAWNING IN:\n" + str(time_left)

func update_time(time: int):
	if time == 0: # avoid it looking weird
		return
	time_left = time

func update_visibility(visiblity: bool):
	self.visible = visiblity
