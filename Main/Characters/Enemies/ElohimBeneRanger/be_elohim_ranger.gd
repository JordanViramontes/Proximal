extends EnemyBase

class_name BeneElohimRanger

# variables
@export var player_run_radius = 8
@export var comfy_radius = 18
@export var comfy_stop_timer = 1
@export var comfy_friction = 0.075
@export var comfy_bool: bool = true
var comfy_stop_friction: Vector3 = Vector3.ZERO
var our_2D_pos: Vector2 = Vector2.ZERO
var player_2D_pos: Vector2 = Vector2.ZERO
var distance_towards_player: float = 0

@export var air_friction: float = 0.5
@export var air_preferred_dist: float = 3
var air_y_distance: float = 0

@export var bullet: PackedScene
@export var bullet_radius: float = 1.5
@export var bullet_velocity: float = 13
@export var bullet_max_range:float = 13
@export var bullet_gravity: float = -2

@export var spawn_acc: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var spawn_zero_bound: float = 0.1
var spawn_direction: Vector3 = Vector3.ZERO

# components
@onready var shoot_timer = $ShootCooldown
@onready var mesh = $MeshInstance3D
@onready var spawn_wait_timer = $SpawnWaitTimer
@onready var bob_timer = $Bob
@onready var cherubim_node: Node3D = null

# bobbing
var bobbing_dir: bool = true;
var bobbing_wait: bool = true;
var bobbing_vel:float = 0;
@export var bobbing_acc: float = 0.05;
@onready var bobbing_max: float = bobbing_acc * 60 * bob_timer.wait_time;
var bob_distance: float = 0

# colors
@onready var mat_roam = StandardMaterial3D.new()
@onready var mat_run_away = StandardMaterial3D.new()
@onready var mat_comfy = StandardMaterial3D.new()

# Constructor called by spawner
func bene_initialize(starting_position, init_player_position, init_spawn_direction, init_wave, init_health_multiplier, init_damage_multiplier, init_xp_multiplier):
	# spawning
	super.initialize(starting_position, init_player_position, init_wave, init_health_multiplier, init_damage_multiplier, init_xp_multiplier)
	spawn_direction = init_spawn_direction


func _ready() -> void:
	# when in the comfy radius, the enemy will stand still
	# when the player gets too close itll run away
	ENEMY_STATE["comfy"] = total_states+1
	ENEMY_STATE["run_away"] = total_states+2
	ENEMY_STATE["spawn_wait"] = total_states+3
	total_states += 3
	
	# colors
	mat_roam.albedo_color = Color("6d9939")
	mat_run_away.albedo_color = Color("85b947")
	mat_comfy.albedo_color = Color("4b6b25")
	
	super._ready()
	
	# using spawn_distance as initial velocity
	velocity.y = spawn_distance_height
	
	# calculate time
	var t = spawn_distance_height / spawn_acc.y
	spawn_direction *= spawn_distance_length
	var newAcc = spawn_direction / t
	spawn_acc.x = abs(newAcc.x)
	spawn_acc.z = abs(newAcc.z)
	
	velocity.x = spawn_direction.x
	velocity.z = spawn_direction.z

func _physics_process(delta: float) -> void:
	#super._physics_process(delta)
	if current_state == ENEMY_STATE.spawn_edge:
		#print("v: " + str(velocity.y))
		if abs(velocity.y) != 0: # air friction while spawning
			velocity.y -= spawn_acc.y
			if velocity.x > 0:
				velocity.x -= spawn_acc.x
			else:
				velocity.x += spawn_acc.x
			if velocity.z > 0:
				velocity.z -= spawn_acc.z
			else:
				velocity.z += spawn_acc.z
		
		if abs(velocity.y) <= spawn_zero_bound: # we're done spawning, change state
			velocity = Vector3.ZERO
			current_state = ENEMY_STATE.spawn_wait
			spawn_wait_timer.start()
	
	if current_state == ENEMY_STATE.comfy:
		#print("vel: " + str(velocity))
		if abs(velocity.x) > 0.1:
			velocity.x += sign(velocity.x) * -1 * comfy_stop_friction.x
		else:
			velocity.x = 0
		
		if abs(velocity.z) > 0.1:
			velocity.z += sign(velocity.z) * -1 * comfy_stop_friction.z
		else:
			velocity.z = 0
	
	if current_state != ENEMY_STATE.spawn_edge:
		# set bobbing vel
		if bobbing_dir:
			bobbing_vel += bobbing_acc;
		else:
			bobbing_vel -= bobbing_acc;
		
		velocity.y = bobbing_vel
		bob_distance += bobbing_vel * delta
		
		# check for height compared to player
		if air_y_distance > air_preferred_dist + 0.5:
			velocity.y -= air_friction
		if air_y_distance < air_preferred_dist - 0.5:
			velocity.y += air_friction
		#print("y: " + str(global_position.y))
		#print("b: " + str(bob_distance))
		#print("d: " + str(y_distance))

	move_and_slide()

# done spawning fully
func _on_spawn_wait_timer_timeout() -> void:
	collision.disabled = false
	current_state = ENEMY_STATE.roam
	velocity = Vector3.ZERO
	pathfind_timer.start()
	bob_timer.start()

func _on_pathfind_timer_timeout() -> void:
	if current_state == ENEMY_STATE.spawn_edge:
		return
	
	# update distance for vertical movement
	air_y_distance = (global_position.y - bob_distance) - player.global_position.y
	
	# start shoot cooldown
	if shoot_timer.is_stopped():
		shoot_timer.start()
	
	# we want to calculate only based on x and z, effectively an infinite cone
	our_2D_pos = Vector2(global_position.x, global_position.z)
	player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	var init_state = current_state
	
	# if we're in radius distance, change state 
	if distance_towards_player <= player_run_radius:
		current_state = ENEMY_STATE.run_away
	elif distance_towards_player <= comfy_radius:
		#print("NOW COMFY!")
		current_state = ENEMY_STATE.comfy
	else:
		current_state = ENEMY_STATE.roam
	
	if init_state != current_state:
		get_mesh_mat_from_state(current_state)
	
	var pathfindVel: Vector3 = Vector3.ZERO
	if current_state == ENEMY_STATE.roam:
		var direction = global_position.direction_to(player.global_position)
		pathfindVel = direction * movement_speed
	elif current_state == ENEMY_STATE.comfy:
		if comfy_bool:
			var normal = velocity.normalized().abs()
			comfy_stop_friction = Vector3(
				normal.x * comfy_friction / comfy_stop_timer, 
				0, 
				normal.z * comfy_friction/ comfy_stop_timer)
			#print("F: " + str(comfy_stop_friction))
			comfy_bool = false
		return
	elif current_state == ENEMY_STATE.run_away:
		var away_direction = (global_position - player.global_position).normalized()
		pathfindVel = away_direction * movement_speed
	
	# reset comfy bool
	if current_state != ENEMY_STATE.comfy:
		comfy_bool = true
	
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

func _on_bob_timeout() -> void:
	if bobbing_wait:
		if bobbing_dir:
			bobbing_dir = false;
			bobbing_wait = false;
			if bobbing_vel != bobbing_max:
				bobbing_vel = bobbing_max
			#print("bob up: " + str(bobbing_vel))
		else:
			bobbing_dir = true;
			bobbing_wait = false;
			if bobbing_vel != -1 * bobbing_max:
				bobbing_vel = -1 * bobbing_max
			#print("bob down: " + str(bobbing_vel))
	else:
		bobbing_wait = true;
	
	#print("dir: " + str(bobbing_dir))

func _on_shoot_cooldown_timeout() -> void:
	if current_state != ENEMY_STATE.spawn_edge && current_state != ENEMY_STATE.spawn_wait:
		var b = bullet.instantiate()
		if b == null: # just in case
			print("be_elohim_ranger.gd - bullet did not instantiate")
			return
		
		player_position = player.global_position #update the player pos for calculations
		
		# find displacement, distance, and use that to get time
		var direction_transform = Vector3(0, 2, 0)
		if current_state == ENEMY_STATE.roam:
			direction_transform = Vector3(0, 4, 0)
		var direction = (player.global_transform.origin + direction_transform - self.global_transform.origin).normalized()
		var initial_velocity = direction * bullet_velocity
		
		# initialize the bullet
		b.initialize(initial_velocity, self)
		b.position = global_position
		
		World.world.add_child(b)
		
		#print("bene shot: " + str(b))
