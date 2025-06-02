extends Path3D

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
	
	func _init(in_enemy_count: Array, in_enemy_health_multiplier: float, in_enemy_damage_multiplier: float, in_enemy_experience_multiplier: float, in_wave_timer: float):
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

# variables - enemies, health mul, experience mul, damage mul, time
@export var multiply_scaler = 1.5 # as this increases, the game scales faster
@export var default_wave_time = 20
var waveDictionary: Dictionary[int, Wave] = {
	0:Wave.new([5, 0, 0, 0], 1, 1, 1, default_wave_time), # 0
	1:Wave.new([3, 3, 0, 0], 1, 1, 1, default_wave_time),
	2:Wave.new([5, 5, 0, 0], 1, 1, 1, default_wave_time),
	3:Wave.new([0, 8, 0, 0], 1, 1, 1, default_wave_time),
	4:Wave.new([0, 6, 2, 0], 1, 1, 1, default_wave_time), # 4
	5:Wave.new([3, 5, 1, 0], 1, 1, 1, default_wave_time),
	6:Wave.new([6, 6, 2, 0], 1, 1, 1, default_wave_time),
	7:Wave.new([10, 2, 0, 0], 1, 1, 1, default_wave_time),
	8:Wave.new([6, 8, 1, 0], 1, 1, 1, default_wave_time),
	9:Wave.new([3, 0, 0, 1], 1, 1, 1, default_wave_time), # 9
	10:Wave.new([2, 3, 0, 3], 1, 1, 1, default_wave_time),
	11:Wave.new([3, 6, 2, 3], 1, 1, 1, default_wave_time),
	12:Wave.new([0, 10, 5, 1], 1, 1, 1, default_wave_time),
	13:Wave.new([7, 4, 2, 2], 1, 1, 1, default_wave_time),
	14:Wave.new([5, 5, 2, 5], 1, 1, 1, default_wave_time), #14
}
@export var starting_wave: int = 0
var last_static_wave = waveDictionary.size() - 1
var current_wave = starting_wave
var current_wave_enemy_count: int = 0
var can_change_wave: bool = true
var wave = waveDictionary[starting_wave]
var ending_wave_time: float = 3.0
var start_wave_time: float = 5.0
var first_wave: bool = true
var total_enemy_dictionary = waveDictionary[0].enemy_count.size()

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
var debug_turn_off_auto_wave: bool = false
var debug_total_enemy_array: Array = []

# components
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var test_spawn_point = $TestSpawnPoint
@onready var wave_timer = $WaveTimer
#@onready var update_timer = $UpdateTimer
@onready var next_wave_timer = $NextWaveTimer
@onready var wave_info_label = get_tree().get_first_node_in_group("WaveInfoLabel")

# signals
signal updateWaveCount(wave: int)
signal updateWaveTimer(time: float)
signal updateEnemyCount(enemies: int)
signal updateNextWaveVisibility(visible: bool)
signal updateNextWaveTimer(time: float)
signal stopWaveTimer()

func _ready() -> void:
	next_wave_timer.start(start_wave_time)
	
	# wait a couple frames
	await get_tree().process_frame
	await get_tree().process_frame  # Two frames for safety
	
	# emit GUI signals and start clock
	emit_signal("updateNextWaveTimer", next_wave_timer.time_left + 1)
	emit_signal("updateNextWaveVisibility", true)

func spawnWave(wave_index):
	# make sure we're valid
	if wave_index < 0:
		return
		
	# variables
	if current_wave >= waveDictionary.size():
		wave = generateNewWave(wave_index)
	else:
		wave = waveDictionary[current_wave]
	#print("TOTAL IN THIS WAVE: " + str(wave.total_enemies))
	var enemy_count = wave.enemy_count
	#current_wave_enemy_count += wave.total_enemies
	
	# parse enemy_count, mob_path has the file path to the enemy scene
	for mob_path in enemy_count.keys():  
		# spawn the amount of times specified in the dictionary
		for i in range(enemy_count[mob_path]):
			print(mob_path)
			spawnEnemy(mob_path, 0, wave.enemy_health_multiplier, wave.enemy_damage_multiplier, wave.enemy_experience_multiplier)
	
	# set the timer
	wave_timer.start(wave.wave_time_count)
	
	emit_signal("updateWaveTimer", wave_timer.time_left + 1)
	emit_signal("updateEnemyCount", current_wave_enemy_count)
	emit_signal("updateWaveCount", current_wave + 1)

func generateNewWave(wave_count) -> Wave:
	# vars
	var rng = RandomNumberGenerator.new()
	var enemies: Array[int] = []
	var health_mult: float = 1
	var damage_mult: float = 1
	var xp_mult: float = 1
	var wave_time: float = 20
	
	# make a random amount of enemies, total enemy per wave cap calculated by wave number
	enemies.resize(total_enemy_dictionary)
	
	# get random partitions (from 0-100)
	var enemiesRNG: Array[float] = []
	enemiesRNG.resize(total_enemy_dictionary)
	for i in range(total_enemy_dictionary - 1):
		enemiesRNG[i] = rng.randf_range(0, 100)
	enemiesRNG.push_back(100)
	enemiesRNG.sort() # theres an extra 0 from resizing the array which is good!
	
	# now set the amount of enemies based on rng partition; max enemies * partition size 
	for i in range(total_enemy_dictionary):
		enemies[i] = int(ceil(wave_count * ((enemiesRNG[i+1] - enemiesRNG[i]) / 100)))
	
	#print("partitions: " + str(enemiesRNG))
	#print("enemies: " + str(enemies))
	
	# set health and damage multipliers, xp and timer scales as either of these increase
	var max_mult:float = wave_count * (1 / (last_static_wave / multiply_scaler))
	health_mult = rng.randf_range(1, max_mult)
	damage_mult = rng.randf_range(1, max_mult)
	xp_mult = (health_mult + damage_mult * 2) / (max_mult / multiply_scaler) # (h+2d) / (max/scale)
	wave_time = default_wave_time * ( (health_mult + damage_mult + (wave_count / last_static_wave)) / (max_mult) ) # default_time * [(h+d + wave_count/last_static) / max]
	if wave_time < default_wave_time:
		wave_time = default_wave_time
	#print(" max mult: " + str(max_mult) + "\n health_mult: " + str(health_mult) + "\n damage_mult: " + str(damage_mult) + "\n xp_mult: " + str(xp_mult) + "\n wave_time: " + str(wave_time))
	
	
	#print("generating new wave!")
	var new_wave = Wave.new(enemies, health_mult, damage_mult, xp_mult, wave_time)
	
	return new_wave

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
	current_wave_enemy_count += 1
	emit_signal("updateEnemyCount", current_wave_enemy_count)
	debug_total_enemy_array.push_back(mob)
	
	# set the signal for mob death
	mob.die_from_wave.connect(self.enemy_dies)
	
	# set signal for elohim spawning new guys
	if mob is Elohim:
		mob.add_new_enemies.connect(self.increase_enemy_count)

func nextWave():
	current_wave += 1
	print("current wave: " + str(current_wave))
	
	# generate new wave if we're past the dictionary
	if current_wave >= waveDictionary.size():
		waveDictionary[current_wave] = generateNewWave(current_wave)
	#printWave(current_wave)

func prevWave():
	if current_wave == 0:
		return
	current_wave -= 1
	
	if current_wave >= waveDictionary.size():
		waveDictionary[current_wave] = generateNewWave(current_wave)
	#printWave(current_wave)

func printWave(wave_index):
	var wave = waveDictionary[wave_index]
	
	print("Wave: " + str(current_wave))
	for i in wave.enemy_count.keys():
		print(str(wave.enemy_count[i]) + "; " + str(i))
	print("healthMult: " + str(wave.enemy_health_multiplier) + ", damageMult: " + str(wave.enemy_damage_multiplier) + ", xpMult: " + str(wave.enemy_experience_multiplier))
	print("time: " + str(wave.wave_time_count))
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
	#print("DIEDIEDIED: " + str(from_wave))
	# only lower count for enemies in the current wave
	#if from_wave != current_wave:
		#return
	
	current_wave_enemy_count -= 1
	#print("new amount: " + str(current_wave_enemy_count))
	emit_signal("updateEnemyCount", current_wave_enemy_count)
	
	if current_wave_enemy_count <= 0:
		if debug_turn_off_auto_wave:
			return
		
		if can_change_wave == false:
			return
		
		can_change_wave = false
		
		end_wave()

# end the current wave and start the next wave
func end_wave() -> void:
	#print("ending wave: " + str(current_wave))
	
	# stop timers
	wave_timer.stop()
	stopWaveTimer.emit()
	
	next_wave_timer.start(ending_wave_time)
	emit_signal("updateNextWaveTimer", ending_wave_time + 1)
	emit_signal("updateNextWaveVisibility", true)

# starts a new wave
func _on_next_wave_timer_timeout() -> void:
	# just spawn immediately (the game starting timer)
	if first_wave:
		first_wave = false
		current_wave -= 1
	
	# change wave and start a new one
	emit_signal("updateNextWaveVisibility", false)
	current_wave += 1
	spawnWave(current_wave)
	can_change_wave = true

# increases enemy count if something other than me spawns enemies
func increase_enemy_count(amount: int, enemy):
	current_wave_enemy_count += amount
	debug_total_enemy_array.push_back(enemy)
	emit_signal("updateEnemyCount", current_wave_enemy_count)

func get_wave_from_index(index: int):
	#print("getting wave: " + str(index))
	if not waveDictionary.has(index):
		waveDictionary[index] = generateNewWave(index)
	return waveDictionary[index]

#region DEBUG UI
func debug_stop_countdown() -> void:
	next_wave_timer.stop()
	emit_signal("updateNextWaveVisibility", false)

func debug_spawn_single_enemy(index: int, amount:int, hp_mult: float, damage_mult: float, xp_mult: float) -> void:
	debug_stop_countdown()
	debug_turn_off_auto_wave = true
	
	#print("enemy: " + str(index) + DEBUG_enemy_list[index] + ", h: " + str(hp_mult) + ", d: " + str(damage_mult) + ", x: " + str(xp_mult))
	#print("amont: " + str(amount))
	
	# if we spawn a bunch, make it random!
	if amount > 1:
		for i in range(amount):
			spawnEnemy(DEBUG_enemy_list[index], 0, hp_mult, damage_mult, xp_mult)
	
	else:
		spawnEnemy(DEBUG_enemy_list[index], 1, hp_mult, damage_mult, xp_mult)

func debug_spawn_wave(wave_count: int) -> void:
	debug_stop_countdown()
	debug_turn_off_auto_wave = false
	can_change_wave = true
	current_wave = wave_count 
	spawnWave(wave_count)

func debug_kill_all_enemies() -> void:
	print("killing all enemies!")
	for i in debug_total_enemy_array:
		if i:
			i.on_reach_zero_health()

#endregion
