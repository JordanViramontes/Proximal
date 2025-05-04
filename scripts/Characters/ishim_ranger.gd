extends EnemyBase

class_name IshimRanger

# variables
@export var player_run_radius = 10
@export var comfy_radius = 15
@export var bullet: PackedScene
@export var bullet_radius: float = 1.5
@export var bullet_velocity: float = 8
@export var bullet_max_range:float = 13
@export var bullet_gravity: float = -2
var cherubim_alerted: bool = false
var cherubim_friend: Cherubim
var cherubim_slot: int = -1

# components
@onready var shoot_timer = $ShootCooldown
@onready var mesh = $MeshInstance3D
@onready var cherubim_node: Node3D = null

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
		if navigation_agent.is_navigation_finished():
			return
	elif current_state == ENEMY_STATE.cherubim_sit:
		if cherubim_node:
			global_position = cherubim_node.global_position
	else:
		if shoot_timer.is_stopped():
			_on_bullet_timer_timeout()
			shoot_timer.start()
	
	# state logic for gravity
	if current_state != ENEMY_STATE.spawn_edge && current_state != ENEMY_STATE.cherubim_sit:
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

func _on_pathfind_timer_timeout() -> void:
	# we want to calculate only based on x and z, effectively an infinite cone
	var our_2D_pos = Vector2(global_position.x, global_position.z)
	var player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	var distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	
	# if we're not spawning or in a cherubim alert
	if current_state != ENEMY_STATE.spawn_edge && current_state != ENEMY_STATE.cherubim_alert && current_state != ENEMY_STATE.cherubim_sit:
		# if we're in radius distance, change state 
		if distance_towards_player <= player_run_radius:
			current_state = ENEMY_STATE.run_away
			if mesh.material_override != mat_run_away:
				mesh.set_surface_override_material(0, mat_run_away)
		elif distance_towards_player <= comfy_radius:
			current_state = ENEMY_STATE.comfy
			if mesh.material_override != mat_comfy:
				mesh.set_surface_override_material(0, mat_comfy)
		else:
			current_state = ENEMY_STATE.roam
			if mesh.material_override != mat_roam:
				mesh.set_surface_override_material(0, mat_roam)
	
	# if we're sitting
	if current_state == ENEMY_STATE.cherubim_sit:
		velocity.x = 0
		velocity.y = 0
		return
	
	super._on_pathfind_timer_timeout()
	velocity.x = pathfindVel.x
	velocity.z = pathfindVel.z

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
	elif state == ENEMY_STATE.cherubim_alert:
		# if the cherubim died while going
		if not cherubim_friend:
			print("cherubim friend died lol")
			current_state = ENEMY_STATE.roam
			return player_position
		
		# else return the cherubim pos
		return cherubim_friend.global_position
	elif state == ENEMY_STATE.cherubim_sit:
		return position

# whenever the timer ends, shoot! 
func _on_bullet_timer_timeout() -> void:
	if current_state == ENEMY_STATE.roam || current_state == ENEMY_STATE.comfy || current_state == ENEMY_STATE.cherubim_sit:
		var b = bullet.instantiate()
		if b == null: # just in case
			print("isham_ranger.gd - bullet did not instantiate")
			return
		
		player_position = player.global_position #update the player pos for calculations
		
		# find displacement, distance, and use that to get time
		var displacement = Vector3(player_position.x, player_position.y+1.5, player_position.z) - global_position
		var direction = displacement.normalized()
		var h_displacement: Vector3 = Vector3(displacement.x, 0, displacement.z)
		var h_distance = h_displacement.length()
		if h_distance > bullet_max_range:
			h_distance = bullet_max_range
		var t = (h_distance / bullet_velocity)
		
		# use time and kinematics to get velocity
		var h_v = h_displacement.normalized() * bullet_velocity
		var v_v = (displacement.y + (0.5 * bullet_gravity * t * t)) / t
		var initial_velocity = Vector3(h_v.x, v_v, h_v.z)
		
		# initialize the bullet
		b.initialize(initial_velocity, direction, bullet_gravity, self)
		b.position = global_position
		
		World.world.add_child(b)

func goto_cherubim(cherubim: Cherubim) -> void:
	cherubim_alerted = true
	current_state = ENEMY_STATE.cherubim_alert
	cherubim_friend = cherubim

# check if we've reached a cherubim
func _on_hitbox_component_body_entered(body: Node3D) -> void:
	if body is not Cherubim:
		return
	
	print("reached! " + str(body))
	cherubim_node = cherubim_friend._on_ishim_reached_cherubim(self)
	if not cherubim_node:
		current_state = ENEMY_STATE.roam


# when died
func on_reach_zero_health():
	if current_state == ENEMY_STATE.cherubim_sit && cherubim_friend:
		cherubim_friend._on_ishim_died(cherubim_slot)
	super.on_reach_zero_health()
