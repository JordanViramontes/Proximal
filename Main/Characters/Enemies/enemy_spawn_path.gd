extends Path3D

# variables - enemies, health mul, experience mul, damage mul, time
var waveDictionary = [
	Wave.new([5, 0, 0, 0], 1, 1, 1, 20), # 0
	Wave.new([3, 3, 0, 0], 1, 1, 1, 20),
	Wave.new([5, 5, 0, 0], 1, 1, 1, 20),
	Wave.new([0, 10, 0, 0], 1, 1, 1, 20),
	Wave.new([0, 6, 2, 0], 1, 1, 1, 20), # 4
	Wave.new([3, 5, 1, 0], 1, 1, 1, 20),
	Wave.new([6, 6, 2, 0], 1, 1, 1, 20),
	Wave.new([10, 2, 0, 0], 1, 1, 1, 20),
	Wave.new([6, 8, 1, 0], 1, 1, 1, 20),
	Wave.new([3, 0, 0, 1], 1, 1, 1, 20), # 9
	Wave.new([2, 3, 0, 3], 1, 1, 1, 20),
	Wave.new([3, 6, 2, 3], 1, 1, 1, 20),
	Wave.new([3, 10, 5, 1], 1, 1, 1, 20),
	Wave.new([7, 4, 2, 2], 1, 1, 1, 20),
	Wave.new([10, 10, 5, 5], 1, 1, 1, 20), #14
]
@export var starting_wave: int = 0
var current_wave = starting_wave
var current_wave_enemy_count: int = 0
var can_change_wave: bool = true
var wave = waveDictionary[starting_wave]

# DEBUG components
var DEBUG_enemy_list = [
	"res://Main/Characters/Enemies/EnemyBase/enemy_base.tscn", # BASE 0
	"res://Main/Characters/Enemies/IshimCrawler/ishim_crawler.tscn", # CRAWLER 1
	"res://Main/Characters/Enemies/IshimRanger/ishim_ranger.tscn", # RANGER 2
	"res://Main/Characters/Enemies/Cherubim/cherubim.tscn", # CHERUBIM WORM 3
	"res://Main/Characters/Enemies/Elohim/elohim.tscn", # ELOHIM 4
	"res://Main/Characters/Enemies/ElohimBeneCrawler/be_elohim_crawler.tscn", # BENE ELOHIM CRAWLER 5
	"res://Main/Characters/Enemies/ElohimBeneRanger/be_elohim_ranger.tscn", # BENE ELOHIM RANGER 6
]
var DEBUG_enemy_ptr = 3
var DEBUG_wave: bool = true

# components
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var test_spawn_point = $TestSpawnPoint
@onready var wave_timer = $WaveTimer
@onready var update_timer = $UpdateTimer
@onready var next_wave_timer = $NextWaveTimer
@onready var wave_info_label = get_tree().get_first_node_in_group("WaveInfoLabel")

# signals
signal updateWaveCount(wave: int)
signal updateWaveTimer(time: int)
signal updateEnemyCount(enemies: int)
signal updateNextWaveVisibility(visible: bool)
signal updateNextWaveTimer(time: int)

# wave struct holds all information about each wave
class Wave:
	var enemy_count = { 
		"res://Main/Characters/Enemies/IshimCrawler/ishim_crawler.tscn":-1, #ISHIM_CRAWLER
		"res://Main/Characters/Enemies/IshimRanger/ishim_ranger.tscn":-1, #ISHIM_RANGER
		"res://Main/Characters/Enemies/Cherubim/cherubim.tscn":-1, # CHERUBIM WORM
		"res://Main/Characters/Enemies/Elohim/elohim.tscn":-1, # ELOHIM 
	}
	var total_enemies: int = 0
	var enemy_health_multiplier: float = 1
	var enemy_damage_multiplier: float = 1
	var enemy_experience_multiplier: float = 1
	var wave_time_count: float = 20
	
	func _init(in_enemy_count: Array, in_enemy_health_multiplier: float, in_enemy_experience_multiplier: float, in_enemy_damage_multiplier: float, in_wave_timer: float):
		# get enemy counts
		var keys = enemy_count.keys()
		for i in range(in_enemy_count.size()):
			if i >= enemy_count.size():
				break
			enemy_count[keys[i]] = in_enemy_count[i]
			total_enemies += in_enemy_count[i]
		
		# the rest
		enemy_health_multiplier = in_enemy_health_multiplier
		enemy_damage_multiplier = in_enemy_damage_multiplier
		enemy_experience_multiplier = in_enemy_experience_multiplier
		wave_time_count = in_wave_timer
		

 # modified from squash the creeps lol

func _ready() -> void:
	print("WARNING: USING DEBUG ENEMY SPAWNING")

func _process(delta):
	if Input.is_action_just_pressed("debug_toggle_wave"):
		DEBUG_wave = not DEBUG_wave
		if DEBUG_wave:
			print("CHANGED SPAWN TO: WAVES")
		else:
			print("CHANGED SPAWN TO: SINGLE ENEMY")
	
	# changes what we spawn based on debug
	if DEBUG_wave:
		if Input.is_action_just_pressed("debug_spawn_enemy"):
			spawnWave(current_wave)
		if Input.is_action_just_pressed("debug_next_enemy"):
			nextWave()
		if Input.is_action_just_pressed("debug_prev_enemy"):
			prevWave()
	else:
		if Input.is_action_just_pressed("debug_spawn_enemy"):
			TESTspawnWave()
		if Input.is_action_just_pressed("debug_next_enemy"):
			if not DEBUG_enemy_ptr + 1 >= DEBUG_enemy_list.size():
				DEBUG_enemy_ptr = DEBUG_enemy_ptr + 1
				print("DEBUG enemy now at: " + DEBUG_enemy_list[DEBUG_enemy_ptr])
			else:
				print("CANT! At the end of enemy list")
		if Input.is_action_just_pressed("debug_prev_enemy"):
			if not DEBUG_enemy_ptr - 1 < 0:
				DEBUG_enemy_ptr = DEBUG_enemy_ptr - 1
				print("DEBUG enemy now at: " + DEBUG_enemy_list[DEBUG_enemy_ptr])
			else:
				print("CANT! At the end of enemy list")
	
	# timer
	#print(wave_timer.time_left)

func spawnWave(wave_index):
	# make sure we're valid
	if wave_index < 0:
		return
		
	# variables
	if current_wave >= waveDictionary.size():
		wave = generateNewWave(wave_index)
	else:
		wave = waveDictionary[current_wave]
	print("TOTAL IN THIS WAVE: " + str(wave.total_enemies))
	var enemy_count = wave.enemy_count
	current_wave_enemy_count += wave.total_enemies
	
	# parse enemy_count, mob_path has the file path to the enemy scene
	for mob_path in enemy_count.keys():  
		# spawn the amount of times specified in the dictionary
		for i in range(enemy_count[mob_path]):
			spawnEnemy(mob_path, 0, wave.enemy_health_multiplier, wave.enemy_damage_multiplier, wave.enemy_experience_multiplier)
	
	# set the timer
	wave_timer.stop()
	wave_timer.wait_time = wave.wave_time_count
	wave_timer.start()
	
	update_timer.stop()
	update_timer.wait_time = 1
	update_timer.start()
	emit_signal("updateWaveTimer", wave_timer.time_left)
	emit_signal("updateEnemyCount", current_wave_enemy_count)
	emit_signal("updateWaveCount", current_wave + 1)

func generateNewWave(wave_count) -> Wave:
	print("generating new wave!")
	var new_wave = Wave.new([10, 10, 10, 10], 1, 1, 1, 20)
	
	return new_wave

func TESTspawnWave():
	# for debugging enemies
	var test_amount = 1
	for i in range(test_amount):
		spawnEnemy(DEBUG_enemy_list[DEBUG_enemy_ptr], 1, 1, 1, 1)

func spawnEnemy(mob_path, debug_flag, health_multiplier, damage_multiplier, experience_multiplier):
	var mob = load(mob_path).instantiate()
	
	# Choose a random location on the SpawnPath, We store the reference to the SpawnLocation node.
	var mob_spawn_location = get_node("EnemySpawner")
	
	# give random location an offset, and get player position
	mob_spawn_location.progress_ratio = randf()
	var player_position = player.global_position
	if not debug_flag:
		mob.initialize(mob_spawn_location.position, player_position, current_wave, health_multiplier, damage_multiplier, experience_multiplier)
	else:
		var spawn_point = test_spawn_point.global_position
		mob.initialize(spawn_point, player_position, current_wave, health_multiplier, damage_multiplier, experience_multiplier)
	
	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	
	# set the signal for mob death
	mob.die_from_wave.connect(self.enemy_dies)
	
	# set signal for elohim spawning new guys
	if mob is Elohim:
		mob.add_new_enemies.connect(self.increase_enemy_count)

func nextWave():
	if current_wave >= waveDictionary.size() - 1:
		return
	current_wave += 1
	print("Wave: " + str(current_wave))
	printWave(current_wave)

func prevWave():
	if current_wave == 0:
		return
	current_wave -= 1
	print("wave: " + str(current_wave))
	printWave(current_wave)

func printWave(wave_index):
	var wave = waveDictionary[wave_index]
	for i in wave.enemy_count.keys():
		print("Enemy: " + str(i) + ", cnt: " + str(wave.enemy_count[i]))
	print("healthMult: " + str(wave.enemy_health_multiplier) + ", damageMult: " + str(wave.enemy_damage_multiplier))
	print()

# one of the ways waves end
func _on_wave_timer_timeout() -> void:
	emit_signal("updateWaveTimer", 0)
	
	# avoid ending multiple waves at once
	if can_change_wave == false:
		return
	
	can_change_wave = false
	end_wave()

# every time an enemy dies, update the enemy counter, if we have 0 enemies left start next wave
func enemy_dies(from_wave: int) -> void:
	if not DEBUG_wave:
		return
	#print("DIEDIEDIED: " + str(from_wave))
	# only lower count for enemies in the current wave
	#if from_wave != current_wave:
		#return
	
	current_wave_enemy_count -= 1
	print("new amount: " + str(current_wave_enemy_count))
	emit_signal("updateEnemyCount", current_wave_enemy_count)
	
	if current_wave_enemy_count <= 0:
		if can_change_wave == false:
			return
		
		can_change_wave = false
		end_wave()

# end the current wave and start the next wave
func end_wave() -> void:
	print("ending wave: " + str(current_wave))
	# stop timers
	wave_timer.stop()
	
	next_wave_timer.start()
	update_timer.stop()
	update_timer.wait_time = 1
	update_timer.start()
	emit_signal("updateNextWaveTimer", next_wave_timer.time_left)
	emit_signal("updateNextWaveVisibility", true)

# timer for UI
func _on_update_timer_timeout() -> void:
	if not can_change_wave:
		emit_signal("updateNextWaveTimer", next_wave_timer.time_left)
		return
	
	if wave_timer.time_left >= 1:
		emit_signal("updateWaveTimer", wave_timer.time_left)

# starts a new wave
func _on_next_wave_timer_timeout() -> void:
	# change wave and start a new one
	emit_signal("updateNextWaveVisibility", false)
	current_wave += 1
	spawnWave(current_wave)
	can_change_wave = true

# increases enemy count if something other than me spawns enemies
func increase_enemy_count(amount: int):
	if not DEBUG_wave:
		return
	
	current_wave_enemy_count += amount
	emit_signal("updateEnemyCount", current_wave_enemy_count)
