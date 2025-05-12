extends Path3D

# variables
@export var mob_scene: PackedScene
@export var starting_wave = 0
var current_wave = starting_wave
var waveDictionary = [
	Wave.new([5, 5], 1, 1),
	Wave.new([10, 10], 1, 1),
	Wave.new([20, 20], 1, 1),
]

# DEBUG components
var DEBUG_enemy_list = [
	"res://scenes/Enemies/enemy_base.tscn", # BASE 0
	"res://scenes/Enemies/ishim_crawler.tscn", # CRAWLER 1
	"res://scenes/Enemies/ishim_ranger.tscn", # RANGER 2
	"res://scenes/Enemies/cherubim.tscn", # CHERUBIM WORM 3
	"res://scenes/Enemies/elohim.tscn", # ELOHIM 4
	"res://scenes/Enemies/be_elohim_crawler.tscn", # BENE ELOHIM CRAWLER 5
	"res://scenes/Enemies/be_elohim_ranger.tscn", # BENE ELOHIM RANGER 6
]
var DEBUG_enemy_ptr = 5
var DEBUG_wave: bool = true

# components
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var test_spawn_point = $TestSpawnPoint

# wave struct holds all information about each wave
class Wave:
	var enemy_count = { 
		"res://scenes/Enemies/ishim_crawler.tscn":-1, #ISHIM_CRAWLER
		"res://scenes/Enemies/ishim_ranger.tscn":-1, #ISHIM_RANGER
		"res://scenes/Enemies/cherubim.tscn":-1, # CHERUBIM WORM
		"res://scenes/Enemies/elohim.tscn":-1, # ELOHIM 
	}
	var enemy_health_multiplier: float = -1 
	var enemy_damage_multiplier: float = -1
	
	func _init(in_enemy_count: Array, in_enemy_health_multiplier: float, in_enemy_damage_multiplier: float):
		# get enemy counts
		var keys = enemy_count.keys()
		for i in range(in_enemy_count.size()):
			if i >= enemy_count.size():
				break
			enemy_count[keys[i]] = in_enemy_count[i]
		
		# the rest
		enemy_health_multiplier = in_enemy_health_multiplier
		enemy_damage_multiplier = in_enemy_damage_multiplier
		

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

func spawnWave(wave_index):
		# make sure we're valid
	if wave_index > waveDictionary.size() || wave_index < 0:
		return
		
	# variables
	var wave = waveDictionary[wave_index]
	var enemy_count = wave.enemy_count
	
	# parse enemy_count, mob_path has the file path to the enemy scene
	for mob_path in enemy_count.keys():  
		# spawn the amount of times specified in the dictionary
		for i in range(enemy_count[mob_path]):
			spawnEnemy(mob_path, 0)

func TESTspawnWave():
	# for debugging enemies
	var test_amount = 1
	for i in range(test_amount):
		spawnEnemy(DEBUG_enemy_list[DEBUG_enemy_ptr], 1)

func spawnEnemy(mob_path, debug_flag):
	var mob = load(mob_path).instantiate()
	
	# Choose a random location on the SpawnPath, We store the reference to the SpawnLocation node.
	var mob_spawn_location = get_node("EnemySpawner")
	
	# give random location an offset, and get player position
	mob_spawn_location.progress_ratio = randf()
	var player_position = player.global_position
	if not debug_flag:
		mob.initialize(mob_spawn_location.position, player_position)
	else:
		var spawn_point = test_spawn_point.global_position
		mob.initialize(spawn_point, player_position)
	
	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

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
