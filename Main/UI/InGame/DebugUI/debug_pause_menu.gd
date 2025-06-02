extends Control

# weapon variables [lvl, xp]
var thumb_vars: Array = [1, 0.0]
var index_vars: Array = [1, 0.0]
var middle_vars: Array = [1, 0.0]
var ring_vars: Array = [1, 0.0]
var pinky_vars: Array = [1, 0.0]

# spawn variables
var wave_count: int = 0
var single_values: Array[float] = [1.0, 1.0, 1.0] # health, damage, xp
var wait_for_fade: bool = true

#region components
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")
@onready var enemy_spawner = get_tree().get_first_node_in_group("EnemySpawnParent")
@onready var delay_access_timer = $DelayAccess

# spawn components
@onready var spawn_type_label = $"MainContainer/SpawnUI/Spawn Labels/SpawnTypeLabel"
@onready var spawn_type_button = $"MainContainer/SpawnUI/Spawn Labels/SpawnButton"
@onready var wave_stuff = $MainContainer/SpawnUI/WaveStuff
@onready var single_stuff = $MainContainer/SpawnUI/SingleEnemyStuff

@onready var wave_set_count = $MainContainer/SpawnUI/WaveStuff/SetWave/SetWave
@onready var wave_info = $MainContainer/SpawnUI/WaveStuff/AllWaveInfo/WaveInformation/WaveInfo/Wave/WaveCount
@onready var wave_enemy_info = $MainContainer/SpawnUI/WaveStuff/AllWaveInfo/WaveInformation/EnemyInfo/Enemies/EnemyCount

@onready var single_menu_button = $MainContainer/SpawnUI/SingleEnemyStuff/VBoxContainer/Enemy/EnemySelection
@onready var single_spawn = $MainContainer/SpawnUI/SingleEnemyStuff/VBoxContainer/SpawnSingle
@onready var single_mult_label = $MainContainer/SpawnUI/SingleEnemyStuff/VBoxContainer/EnemyInfo/MultCounts
@onready var single_amount_to_spawn = $MainContainer/SpawnUI/SingleEnemyStuff/VBoxContainer/HBoxContainer/AmountToSpawnCount
#endregion

func _ready() -> void:
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	delay_access_timer.start()
	
	# set defaults
	single_stuff.visible = false
	wave_stuff.visible = true
	spawn_type_button.button_pressed = false
	single_amount_to_spawn.text = "1"
	update_single_UI()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_pause_menu"):
		_on_change_visibility()

func _on_change_visibility() -> void:
	# wiat for the fade to finish
	if wait_for_fade:
		return
	
	# open the screen and parse
	if not self.visible:
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

#region wave spawning
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
	enemy_spawner.debug_spawn_wave(wave_count)

#endregion

#region single spawning
func update_single_UI() -> void:
	single_mult_label.text = str(single_values[0]) + "\n" + str(single_values[1]) + "\n" + str(single_values[2])

func _on_hp_mult_slider_value_changed(value: float) -> void:
	single_values[0] = snapped(remap(value, 0.0, 100.0, 1.0, 10.0), 0.01)
	update_single_UI()

func _on_damage_mult_slider_value_changed(value: float) -> void:
	single_values[1] = snapped(remap(value, 0.0, 100.0, 1.0, 10.0), 0.01)
	update_single_UI()

func _on_xp_mult_slider_value_changed(value: float) -> void:
	single_values[2] = snapped(remap(value, 0.0, 100.0, 1.0, 10.0), 0.01)
	update_single_UI()

func _on_amount_to_spawn_count_text_changed() -> void:
	var real_text = ""
	for i in single_amount_to_spawn.text:
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
	
	single_amount_to_spawn.text = real_text
	single_amount_to_spawn.set_caret_column(single_amount_to_spawn.text.length())

func _on_spawn_single_pressed() -> void:
	enemy_spawner.debug_spawn_single_enemy(single_menu_button.selected, single_amount_to_spawn.text.to_int(), single_values[0], single_values[1], single_values[2])


#endregion

#endregion

# kill all enemies
func _on_button_pressed() -> void:
	enemy_spawner.debug_kill_all_enemies()


func _on_delay_access_timeout() -> void:
	wait_for_fade = false
