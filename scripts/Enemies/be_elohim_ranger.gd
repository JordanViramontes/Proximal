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
@onready var cherubim_node: Node3D = null

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
	
	move_and_slide()

# done spawning fully
func _on_spawn_wait_timer_timeout() -> void:
	current_state = ENEMY_STATE.roam

func _on_pathfind_timer_timeout() -> void:
	super._on_pathfind_timer_timeout()
	velocity.x = pathfindVel.x
	velocity.z = pathfindVel.z
