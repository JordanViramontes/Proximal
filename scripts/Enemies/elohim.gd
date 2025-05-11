extends EnemyBase

# variables
@export var player_run_radius = 10
@export var comfy_radius = 5
@export var touch_damage = 3
@export var bene_spawn_angle = 45
var DEBUG_spawn_bool = true;

# components
@onready var summon_cooldown = $SummonCooldown
@onready var summoning_timer = $SummoningTimer
@onready var be_elohim_ranger_path = "res://scenes/Enemies/be_elohim_ranger.tscn"
@onready var enemy_spawn_parent = get_tree().get_first_node_in_group("EnemySpawnParent")

# colors
@onready var mat_roam = StandardMaterial3D.new()
@onready var mat_summoning = StandardMaterial3D.new()

func _ready() -> void:
	# when in the comfy radius, the enemy will stand still
	# when the player gets too close itll run away
	ENEMY_STATE["summoning"] = total_states+1
	ENEMY_STATE["comfy"] = total_states+2
	ENEMY_STATE["run_away"] = total_states+3
	total_states += 3
	
	# colors
	mat_roam.albedo_color = Color("2c5b00")
	mat_summoning.albedo_color = Color("438500")
	
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# states
	if current_state == ENEMY_STATE.run_away: # running away state
		if navigation_agent.is_navigation_finished():
			print("navigation finisihed?")
			return
	
	## state logic for summoning
	#if current_state == ENEMY_STATE.summoning:
		#position.x = position.x
		#position.z = position.z
	
	# state logic for gravity
	if current_state != ENEMY_STATE.spawn_edge:
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

func _on_pathfind_timer_timeout() -> void:
	# we want to calculate only based on x and z, effectively an infinite cone
	var our_2D_pos = Vector2(global_position.x, global_position.z)
	var player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	var distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	
	# if we're summoning
	if current_state == ENEMY_STATE.summoning:
		velocity.x = 0
		velocity.y = 0
		return

	# update state
	if current_state != ENEMY_STATE.spawn_edge:
		# if we're in radius distance, change state 
		if distance_towards_player <= player_run_radius:
			current_state = ENEMY_STATE.run_away
		elif distance_towards_player <= comfy_radius:
			current_state = ENEMY_STATE.comfy
		else:
			current_state = ENEMY_STATE.roam
	
	# set summoning timer if not set already
	if current_state != ENEMY_STATE.summoning and summon_cooldown.is_stopped():
		summon_cooldown.start() 
	
	super._on_pathfind_timer_timeout()
	#velocity.x = pathfindVel.x
	#velocity.z = pathfindVel.z
	velocity.x = 0
	velocity.y = 0
	
	#print("vel: " + str(pathfindVel) + ", state: " + str(current_state))

func get_target_from_state(state):
	if state == ENEMY_STATE.roam:
		return player_position
	elif state == ENEMY_STATE.spawn_edge:
		return spawn_distance_vector
	elif state == ENEMY_STATE.comfy:
		# if we are comfy, dont move :D
		return position
	elif state == ENEMY_STATE.run_away:
		# get the distance between player and self (relative position)
		# new target is our pos - the relative position (new_target)
		# basically we will travel the exact opposite direction of the player
		var away_direction = (global_position - player.global_position).normalized()
		var new_target = global_position + away_direction * player_run_radius
		return new_target

# we are in ummoning process!
func _on_summon_cooldown_timeout() -> void:
	#print("beginning summoning sequence!")
	velocity.x = 0
	velocity.z = 0
	current_state = ENEMY_STATE.summoning
	summoning_timer.start()

# finished summoning, go back to normal
func _on_summoning_timer_timeout() -> void:
	# actually summon
	if DEBUG_spawn_bool:
		summon_guys()
		DEBUG_spawn_bool = false
	
	current_state = ENEMY_STATE.roam
	_on_pathfind_timer_timeout()

# summon small guys
func summon_guys() -> void:
	#var mob1 = load(be_elohim_ranger_path).instantiate()
	var mob2 = load(be_elohim_ranger_path).instantiate()
	
	# calculate the horizontal velocity offsets for both bene
	var direction_to_player = (player.global_position - self.global_position).normalized()
	var dir1 = direction_to_player.rotated(Vector3.UP, bene_spawn_angle)
	var dir2 = direction_to_player.rotated(Vector3.UP, bene_spawn_angle * -1)
	#print("dir: " + str(direction_to_player))
	#print("dir1: " + str(dir1))
	#print("dir2: " + str(dir2))
	
	# spawn in the mob
	var offset = 1
	#mob1.bene_initialize(global_position + Vector3(0, offset, 0), player_position, dir1)
	mob2.bene_initialize(global_position + Vector3(0, offset, 0), player_position, dir2)
	
	# Spawn the mob by adding it to the Main scene.
	print("SPAWN PARENT: " + str(enemy_spawn_parent))
	#enemy_spawn_parent.add_child(mob1)
	enemy_spawn_parent.add_child(mob2)
