extends Control

# variables
@export var shake_duration = 0.5
@export var shake_intensity: float = 12
@export var shake_frequency: float = 30
var wave_time_shaking = false
var current_wave = 0
var current_time = 0
var current_enemies = 0

# components
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")

@onready var wave = $Wave2/Wave
@onready var wave_count = $Wave2/WaveCount
@onready var wave_timer = $Wave2/WaveTimer

@onready var wave_time = $WaveInfo/Time/WaveTime
@onready var wave_time_count = $WaveInfo/Time/WaveTimeNum

@onready var wave_enemies = $WaveInfo/Enemies/WaveEnemies
@onready var wave_enemies_count = $WaveInfo/Enemies/WaveEnemiesNum
@onready var wave_enemies_timer = $WaveInfo/Enemies/EnemiesTimer

#region audio
@onready var audio_manager = $"../AudioManager"
signal sound_effect_signal_start(name: String)
signal sound_effect_signal_stop(name: String)

var SE_wave_complete: String = "wave_complete"
var SE_wave_complete_silly: String = "wave_complete_silly"
@onready var sound_effects: Dictionary[String, AudioStreamPlayer] = {
	SE_wave_complete:$"../AudioManager/WaveComplete",
	SE_wave_complete_silly:$"../AudioManager/WaveCompleteSilly",
}
#endregion

func _ready() -> void:
	# set components
	wave_count.text = str(0)
	wave_time_count.text = str(0)
	wave_enemies_count.text = str(0)
	
	# set signals
	enemy_spawn_path.updateWaveTimer.connect(update_time)
	enemy_spawn_path.updateEnemyCount.connect(update_enemies)
	enemy_spawn_path.updateWaveCount.connect(update_wave)
	
	# audio
	# sound effects
	for i in sound_effects.keys():
		audio_manager.sound_effects[i] = sound_effects[i]
	self.sound_effect_signal_start.connect(audio_manager.play_sfx)
	self.sound_effect_signal_stop.connect(audio_manager.stop_sfx)

func update_wave(new_wave: int):
	wave_count.text = str(new_wave)
	
	# shake
	_on_shake_wave_ui()
	current_wave = new_wave
	
	# audio
	if new_wave == 16:
		sound_effect_signal_start.emit(SE_wave_complete_silly)
	else:
		sound_effect_signal_start.emit(SE_wave_complete)

func update_time(time: int):
	wave_time_count.text = str(time)

func update_enemies(enemies: int):
	# set text
	wave_enemies_count.text = str(enemies)
	
	# shake
	if enemies < current_enemies:
		_on_shake_enemy_ui()
	current_enemies = enemies

# wave shake
func _on_shake_wave_ui():
	# set up shake
	wave.bbcode_text = "[shake rate=" + str(shake_frequency) + " level=" + str(shake_intensity) + " connected=1]" + wave.text + "[/shake]"
	wave_count.bbcode_text = "[shake rate=" + str(shake_frequency) + " level=" + str(shake_intensity) + " connected=1]" + wave_count.text + "[/shake]"
	
	# set timer
	wave_timer.start(shake_duration)

func _on_wave_timer_timeout() -> void:
	wave.bbcode_text = "Wave:"
	wave_count.bbcode_text = str(current_wave)

# enemies shake
func _on_shake_enemy_ui():
	# set up shake
	wave_enemies.bbcode_text = "[shake rate=" + str(shake_frequency) + " level=" + str(shake_intensity) + " connected=1]" + wave_enemies.text + "[/shake]"
	wave_enemies_count.bbcode_text = "[shake rate=" + str(shake_frequency) + " level=" + str(shake_intensity) + " connected=1]" + wave_enemies_count.text + "[/shake]"
	
	# set timer
	wave_enemies_timer.start(shake_duration)

func _on_enemies_timer_timeout() -> void:
	wave_enemies.bbcode_text = "Enemies:"
	wave_enemies_count.bbcode_text = str(current_enemies)
