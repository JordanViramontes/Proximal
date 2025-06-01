extends Control

# weapon variables [lvl, xp]
var thumb_vars: Array = [1, 0.0]
var index_vars: Array = [1, 0.0]
var middle_vars: Array = [1, 0.0]
var ring_vars: Array = [1, 0.0]
var pinky_vars: Array = [1, 0.0]

# spawn variables
var wave_count: int = 0

# components
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")
@onready var enemy_spawner = get_tree().get_first_node_in_group("EnemySpawnParent")

# spawn components
@onready var spawn_type_label = $"MainContainer/SpawnUI/Spawn Labels/SpawnTypeLabel"
@onready var spawn_type_button = $"MainContainer/SpawnUI/Spawn Labels/SpawnButton"
@onready var wave_stuff = $MainContainer/SpawnUI/WaveStuff
@onready var single_stuff = $MainContainer/SpawnUI/SingleEnemyStuff

@onready var wave_set_count = $MainContainer/SpawnUI/WaveStuff/SetWave/SetWave
@onready var wave_info = $MainContainer/SpawnUI/WaveStuff/AllWaveInfo/WaveInformation/WaveInfo/Wave/WaveCount
@onready var wave_enemy_info = $MainContainer/SpawnUI/WaveStuff/AllWaveInfo/WaveInformation/EnemyInfo/Enemies/EnemyCount


func _ready() -> void:
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# set defaults
	single_stuff.visible = false
	wave_stuff.visible = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_pause_menu"):
		_on_change_visibility()

func _on_change_visibility() -> void:
	# open the screen and parse
	if not self.visible:
		print("unpaused")
		get_tree().paused = true
		self.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# weapon vars
		#thumb_vars[0] = weapon_manager.weapon_dictionary[0].level
		
		# spawn vars
		wave_count = enemy_spawner.current_wave
		update_wave_UI(enemy_spawner.current_wave)
		

	# update game stuff and close
	else:
		print("paused")
		self.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# weapon vars
		#weapon_manager.weapon_dictionary[0].set_level(thumb_vars[0]+1)

#region WEAPONS

#region Weapon Levels
func _on_thumb_lvl_item_selected(index: int) -> void:
	thumb_vars[0] = index

func _on_index_lvl_item_selected(index: int) -> void:
	index_vars[0] = index

func _on_middle_lvl_item_selected(index: int) -> void:
	middle_vars[0] = index

func _on_ring_lvl_item_selected(index: int) -> void:
	ring_vars[0] = index

func _on_pinky_lvl_item_selected(index: int) -> void:
	pinky_vars[0] = index

#endregion

#region Weapon XPs
#endregion

#endregion

#region SPAWNING

# update wave UI
func update_wave_UI(wave_count: int):
	var wave
	if wave_count <= 0:
		wave = enemy_spawner.get_wave_from_index(0)
	else:
		wave = enemy_spawner.get_wave_from_index(wave_count)
	var wave_enemies = wave.enemy_count
	wave_set_count.text = str(wave_count + 1)
	wave_info.text = str(wave_count + 1) + "\n" + str(wave.wave_time_count) + "\n" + str(wave.enemy_health_multiplier) + "\n" + str(wave.enemy_damage_multiplier) + "\n" + str(wave.enemy_experience_multiplier)
	
	var wave_enemy_info_texts: Array[String] = []
	var wave_enemy_total = 0
	for i in wave.enemy_count.keys():
		wave_enemy_info_texts.push_back(str(wave.enemy_count[i]))
		wave_enemy_total += wave.enemy_count[i]
	
	wave_enemy_info.text = str(wave_enemy_total) + "\n"
	for i in range(wave_enemy_info_texts.size() -1):
		wave_enemy_info.text += wave_enemy_info_texts[i] + "\n"
	
	wave_enemy_info.text += wave_enemy_info_texts[wave_enemy_info_texts.size() -1]

# toggle between single and wave
func _on_spawn_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		spawn_type_label.text = "Spawn Single Enemy"
		wave_stuff.visible = false
		single_stuff.visible = true
		
	else:
		spawn_type_label.text = "Spawn Waves"
		single_stuff.visible = false
		wave_stuff.visible = true

#func printWave(wave_index):
	#var wave = waveDictionary[wave_index]
	#
	#print("Wave: " + str(current_wave))
	#for i in wave.enemy_count.keys():
		#print(str(wave.enemy_count[i]) + "; " + str(i))
	#print("healthMult: " + str(wave.enemy_health_multiplier) + ", damageMult: " + str(wave.enemy_damage_multiplier) + ", xpMult: " + str(wave.enemy_experience_multiplier))
	#print("time: " + str(wave.wave_time_count))
	#print()

func _on_wave_increase_pressed() -> void:
	wave_count += 1
	update_wave_UI(wave_count)

func _on_wave_decrease_pressed() -> void:
	if wave_count == 0:
		return
	wave_count -= 1
	update_wave_UI(wave_count)

# updating the set_wave
func _on_set_wave_text_changed() -> void:
	var real_text = ""
	for i in wave_set_count.text:
		if i.is_valid_int():
			real_text += i
	
	# check we're not empty
	if real_text.length() == 0:
		return
	
	# if zero
	if real_text == "0":
		real_text = "1"
	
	# if float limit
	if real_text.to_int() > 4000000000:
		real_text = "4000000000"
	
	wave_count = real_text.to_int() - 1
	wave_set_count.text = real_text
	update_wave_UI(real_text.to_int() - 1)
	print("check: " + str(wave_set_count.text))
	
	wave_set_count.set_caret_column(wave_set_count.text.length())

# spawn wave!
func _on_spawn_wave_pressed() -> void:
	enemy_spawner.current_wave = wave_count 
	enemy_spawner.spawnWave(wave_count)
	enemy_spawner.debug_stop_countdown()
