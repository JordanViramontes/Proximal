extends EnemyBase

class_name IshimRanger

# variables
@export var player_run_radius = 10
@export var comfy_radius = 15
var cherubim_alerted: bool = false
var cherubim_friend: Cherubim
var cherubim_node: Node3D = null
var cherubim_node_index: int = -1
var our_2D_pos: Vector2 = Vector2.ZERO
var player_2D_pos: Vector2 = Vector2.ZERO
var distance_towards_player: float = 0

# bullet variables
@export var bullet: PackedScene
@export var bullet_velocity: float = 10

# components
@onready var shoot_timer = $ShootCooldown
@onready var mesh = $MeshInstance3D

# signals
signal reached_cherubim_friend(ishim: IshimRanger)
signal tell_cherubim_we_died(ishim: IshimRanger, index: int)

# colors
@onready var mat_roam = StandardMaterial3D.new()
@onready var mat_run_away = StandardMaterial3D.new()
@onready var mat_comfy = StandardMaterial3D.new()

func _ready() -> void:
	# when in the comfy radius, the enemy will stand still
	# when the player gets too close itll run away
	ENEMY_STATE["comfy"] = total_states+1
	ENEMY_STATE["run_away"] = total_states+2
	ENEMY_STATE["cherubim_alert"] = total_states+3
	ENEMY_STATE["cherubim_sit"] = total_states+4
	total_states += 4
	
	# colors
	mat_roam.albedo_color = Color("ff79ff")
	mat_run_away.albedo_color = Color("ffcbfd")
	mat_comfy.albedo_color = Color("fe5bff")
	
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# state logic for shooting
	if current_state == ENEMY_STATE.run_away: # running away state
		shoot_timer.stop()
		#if navigation_agent.is_navigation_finished():
			#return
	else:
		if shoot_timer.is_stopped():
			_on_bullet_timer_timeout()
			shoot_timer.start()
	
	# keep sitting on cherubim
	if current_state == ENEMY_STATE.cherubim_sit:
		if cherubim_node:
			global_position = cherubim_node.global_position
	
	# state logic for gravity
	if current_state not in [ENEMY_STATE.spawn_edge, ENEMY_STATE.cherubim_sit]:
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

func _on_pathfind_timer_timeout() -> void:
	# avoid pathfinding
	if current_state == ENEMY_STATE.spawn_edge:
		return
	
	# if we're sitting on a cherubim
	if current_state == ENEMY_STATE.cherubim_sit:
		velocity.x = 0
		velocity.y = 0
		return
	
	# we want to calculate only based on x and z, effectively an infinite cone
	our_2D_pos = Vector2(global_position.x, global_position.z)
	player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	var init_state = current_state
	
	# if we're notin a cherubim alert change states if needed
	if current_state not in [ENEMY_STATE.cherubim_alert, ENEMY_STATE.cherubim_sit]:
		# if we're in radius distance, change state 
		if distance_towards_player <= player_run_radius:
			current_state = ENEMY_STATE.run_away
		elif distance_towards_player <= comfy_radius:
			current_state = ENEMY_STATE.comfy
		else:
			current_state = ENEMY_STATE.roam
	
	# update mesh if we changed states
	if init_state != current_state:
		get_mesh_mat_from_state(current_state)
	
	# avoid pathfinding
	if current_state == ENEMY_STATE.comfy:
		velocity.x = 0
		velocity.z = 0
		return
	
	super._on_pathfind_timer_timeout()
	velocity.x = pathfindVel.x
	velocity.z = pathfindVel.z

func get_mesh_mat_from_state(state):
	if state == ENEMY_STATE.roam:
		mesh.set_surface_override_material(0, mat_roam)
	elif state == ENEMY_STATE.run_away:
		mesh.set_surface_override_material(0, mat_run_away)
	elif state == ENEMY_STATE.comfy:
		mesh.set_surface_override_material(0, mat_comfy)
	else:
		mesh.set_surface_override_material(0, mat_roam)

func get_target_from_state(state):
	if state == ENEMY_STATE.roam:
		return player_position
	elif state == ENEMY_STATE.spawn_edge:
		return spawn_distance_vector
	elif state == ENEMY_STATE.comfy:
		# if we are comfy, dont move :D
		return global_position
	elif state == ENEMY_STATE.run_away:
		# get the distance between player and self (relative position)
		# new target is our pos - the relative position (new_target)
		# basically we will travel the exact opposite direction of the player
		var away_direction = (global_position - player.global_position).normalized()
		var new_target = global_position + away_direction * player_run_radius
		return new_target
	elif state == ENEMY_STATE.cherubim_alert:
		# if the cherubim died while going
		if not cherubim_friend:
			#print("cherubim friend died lol")
			current_state = ENEMY_STATE.roam
			return player_position
		
		# else return the cherubim pos
		return cherubim_friend.global_position
	elif state == ENEMY_STATE.cherubim_sit:
		return global_position
	else:
		return global_position

# whenever the timer ends, shoot! 
func _on_bullet_timer_timeout() -> void:
	if current_state in [ENEMY_STATE.roam, ENEMY_STATE.comfy, ENEMY_STATE.cherubim_sit]:
		var b = bullet.instantiate()
		if b == null: # just in case
			print("ishim_ranger.gd - bullet did not instantiate")
			return
		
		player_position = player.global_position #update the player pos for calculations
		
		# find displacement, distance, and use that to get time
		var direction_transform = Vector3(0, 1.5, 0)
		var direction = (player.global_transform.origin + direction_transform - self.global_transform.origin).normalized()
		var initial_velocity = direction * bullet_velocity
		
		# initialize the bullet
		b.initialize(initial_velocity, self)
		b.position = global_position
		
		World.world.add_child(b)

# called by the cherubim and alerts the ishim
func goto_cherubim(cherubim: Cherubim) -> void:
	cherubim_alerted = true
	current_state = ENEMY_STATE.cherubim_alert
	cherubim_friend = cherubim

# when died
func on_reach_zero_health():
	#if current_state == ENEMY_STATE.cherubim_sit && cherubim_friend:
		#cherubim_friend._on_ishim_died(cherubim_slot)
	if cherubim_friend:
		emit_signal("tell_cherubim_we_died", self, cherubim_node_index)
	super.on_reach_zero_health()

# check if we've reached a cherubim
func _on_hitbox_component_body_entered(body: Cherubim) -> void:
	if current_state != ENEMY_STATE.cherubim_alert:
		return
	#
	if cherubim_friend == body:
		#print("reached! " + str(body))
		emit_signal("reached_cherubim_friend", self)

# cherubim alerts us to follow it
func on_alerted_to_run_to_cherubim(cherubim: Cherubim):
	#print("ishim_ranger.gd: going to: " + str(cherubim))
	current_state = ENEMY_STATE.cherubim_alert
	cherubim_alerted = true
	cherubim_friend = cherubim

# stop running! 
func on_alerted_to_stop_running_to_cherubim():
	#print("ishim_ranger.gd: im stopping!")
	current_state = ENEMY_STATE.roam
	cherubim_alerted = false
	cherubim_friend = null

# we're seated on the cherubim
func on_cherubim_wants_us_seated(node: Node3D, index: int):
	#print("sitting on: " + str(node))
	cherubim_node = node
	cherubim_node_index = index
	current_state = ENEMY_STATE.cherubim_sit
	velocity = Vector3.ZERO
	global_position = cherubim_node.global_position

# cherubim died, reset stuff
func on_alerted_cherubim_died():
	#print("ishim_ranger.gd: cherubim died :(")
	current_state = ENEMY_STATE.roam
	cherubim_node = null
	cherubim_friend = null
	cherubim_alerted = false
	cherubim_node_index = -1
