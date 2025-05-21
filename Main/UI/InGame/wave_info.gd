extends Label

var time_left: int = 0
var enemies_left: int = 0
var wave: int = 0
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")

func _ready() -> void:
	enemy_spawn_path.updateWaveTimer.connect(update_time)
	enemy_spawn_path.updateEnemyCount.connect(update_enemies)
	enemy_spawn_path.updateWaveCount.connect(update_wave)

func _process(delta: float):
	text = "Wave: " + str(wave) + "\nTime Left: " + str(time_left) + "\nEnemies Left: " + str(enemies_left) 

func update_time(time: int):
	time_left = time

func update_enemies(enemies: int):
	enemies_left = enemies

func update_wave(new_wave: int):
	wave = new_wave
