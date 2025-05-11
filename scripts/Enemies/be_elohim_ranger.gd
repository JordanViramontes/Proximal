extends EnemyBase

# variables
@export var player_run_radius = 10
@export var comfy_radius = 15

@export var bullet: PackedScene
@export var bullet_radius: float = 1.5
@export var bullet_velocity: float = 8
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

# colors
@onready var mat_roam = StandardMaterial3D.new()
@onready var mat_run_away = StandardMaterial3D.new()
@onready var mat_comfy = StandardMaterial3D.new()

# Constructor called by spawner
func bene_initialize(starting_position, init_player_position, init_spawn_direction):
	# spawning
	super.initialize(starting_position, init_player_position)
	spawn_direction = init_spawn_direction


func _ready() -> void:
	# when in the comfy radius, the enemy will stand still
	# when the player gets too close itll run away
	ENEMY_STATE["comfy"] = total_states+1
	ENEMY_STATE["run_away"] = total_states+2
	ENEMY_STATE["spawn_wait"] = total_states+3
	total_states += 3
	
	# colors
	mat_roam.albedo_color = Color("ff79ff")
	mat_run_away.albedo_color = Color("ffcbfd")
	mat_comfy.albedo_color = Color("fe5bff")
	
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
	
	if current_state == ENEMY_STATE.roam:
		if bobbing_dir:
			bobbing_vel += bobbing_acc;
		else:
			bobbing_vel -= bobbing_acc;
		#print("y: " + str(bobbing_vel))
		velocity.y = bobbing_vel
	
	move_and_slide()

# done spawning fully
func _on_spawn_wait_timer_timeout() -> void:
	collision.disabled = false
	current_state = ENEMY_STATE.roam
	velocity = Vector3.ZERO
	pathfind_timer.start()
	bob_timer.start()

func _on_pathfind_timer_timeout() -> void:
	# we want to calculate only based on x and z, effectively an infinite cone
	var our_2D_pos = Vector2(global_position.x, global_position.z)
	var player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	var distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	
	var direction = global_position.direction_to(player.global_position)
	var pathfindVel = direction * movement_speed
	velocity.x = pathfindVel.x
	velocity.z = pathfindVel.z
	#print("vel: " + str(velocity))

# set the movement target for navigation
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	next_path_position = navigation_agent.get_next_path_position()
	print("next: " + str(next_path_position))
	pathfindVel = global_position.direction_to(next_path_position) * movement_speed
	#print("we: " + str(self) + ", p: " + str(pathfindVel))


func get_target_from_state(state):
	if state == ENEMY_STATE.roam:
		print("returning player pos: " + str(player_position))
		return player_position
	elif state == ENEMY_STATE.spawn_edge:
		return global_position
	elif state == ENEMY_STATE.comfy:
		return global_position
	elif state == ENEMY_STATE.run_away:
		var away_direction = (global_position - player.global_position).normalized()
		var new_target = global_position + away_direction * player_run_radius
		return new_target
	else:
		return player_position


func _on_bob_timeout() -> void:
	if bobbing_wait:
		if bobbing_dir:
			bobbing_dir = false;
			bobbing_wait = false;
			if bobbing_vel != bobbing_max:
				bobbing_vel = bobbing_max
			print("bob up: " + str(bobbing_vel))
		else:
			bobbing_dir = true;
			bobbing_wait = false;
			if bobbing_vel != -1 * bobbing_max:
				bobbing_vel = -1 * bobbing_max
			print("bob down: " + str(bobbing_vel))
	else:
		bobbing_wait = true;
	
	#print("dir: " + str(bobbing_dir))
