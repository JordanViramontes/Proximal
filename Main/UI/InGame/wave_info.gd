extends Control

# components
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")
@onready var wave_count = $Wave2/WaveCount
@onready var wave_time_count = $WaveInfo/Time/WaveTimeNum
@onready var wave_enemies_count = $WaveInfo/Enemies/WaveEnemiesNum

func _ready() -> void:
	# set components
	wave_count.text = str(0)
	wave_time_count.text = str(0)
	wave_enemies_count.text = str(0)
	
	# set signals
	enemy_spawn_path.updateWaveTimer.connect(update_time)
	enemy_spawn_path.updateEnemyCount.connect(update_enemies)
	enemy_spawn_path.updateWaveCount.connect(update_wave)

func update_wave(new_wave: int):
	wave_count.text = str(new_wave)

func update_time(time: int):
	wave_time_count.text = str(time)

func update_enemies(enemies: int):
	wave_enemies_count.text = str(enemies)
