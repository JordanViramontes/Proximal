extends EnemyBase

# variables
@export var player_run_radius = 10
@export var comfy_radius = 15
@export var bullet: PackedScene
@export var bullet_radius: float = 1.5

# components
@onready var shoot_timer = $ShootCooldown

func _ready() -> void:
	super._ready()
	
	# when in the comfy radius, the enemy will stand still
	# when the player gets too close itll run away
	ENEMY_STATE["comfy"] = total_states+1
	ENEMY_STATE["run_away"] = total_states+2
	total_states += 2

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# states
	if current_state == ENEMY_STATE.run_away:
		shoot_timer.stop()
		if navigation_agent.is_navigation_finished():
			return
	else:
		if shoot_timer.is_stopped():
			shoot_timer.start()
	
	if current_state != ENEMY_STATE.spawn_edge:
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta
	# running away state

func _on_pathfind_timer_timeout() -> void:
	# we want to calculate only based on x and z, effectively an infinite cone
	var our_2D_pos = Vector2(global_position.x, global_position.z)
	var player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	var distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	
	# if we're not spawning
	if current_state != ENEMY_STATE.spawn_edge:
		# if we're in radius distance, change state 
		if distance_towards_player <= player_run_radius:
			current_state = ENEMY_STATE.run_away
		elif distance_towards_player <= comfy_radius:
			current_state = ENEMY_STATE.comfy
		else:
			current_state = ENEMY_STATE.roam
	
	super._on_pathfind_timer_timeout()

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
		var relative_position = to_local(player.global_position)
		var new_target = global_position - (player_run_radius * relative_position)
		return new_target

# whenever the timer ends, shoot! (taken from index)
func _on_bullet_timer_timeout() -> void:
	if current_state == ENEMY_STATE.roam || current_state == ENEMY_STATE.comfy:
		var b = bullet.instantiate()
		if b == null: # just in case
			print("isham_ranger.gd - bullet did not instantiate")
			return
		
		var direction = (player.global_position - global_position).normalized()
		b.position = global_position + direction * bullet_radius
		
		World.world.add_child(b)
		
		# add small permutation to firing direction
		b.direction = Util.permute_vector(direction, 0)
		b.direction.y += 0.1
