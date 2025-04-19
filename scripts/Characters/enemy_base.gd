extends CharacterBody3D
class_name EnemyBase

# vars
@export var max_health: float
@export var hitflash_material: Material
@export var hitflash_duration: float = 0.1
var hitflash_tween: Tween
@export var movement_speed = 5
@export var nav_path_dist = 2 
@export var nav_target_dist = 1 
#@onready var current_agent_position: Vector3
@onready var next_path_position: Vector3
@onready var pathfindVel: Vector3

# spawning variables
var spawn_distance_vector = Vector3(0, 0, 0)
var spawning_velocity = Vector3(0, 0, 0)
@export var spawning_time = 2
@export var spawn_distance_length = 1 # distance to travel towards origin
@export var spawn_distance_height = 3 # units to travel vertically while in spawning state

# states
var ENEMY_STATE = {
	"roam":0,
	"spawn_edge":1,
	"dead":2
}
var current_state = ENEMY_STATE.spawn_edge
var total_states = 2

# components
@onready var health_component := $HealthComponent
@onready var hitbox_component := $HitboxComponent
@onready var collision := $CollisionShape3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var pathfind_timer: Timer = $PathfindTimer

# signals
signal die
signal take_damage

# player information
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var player_position = player.global_position

# basic attack-within-range information
@export var attack_range: float = 3.0
@export var damage_amount: float = 10.0
@export var attack_cooldown: float = 2.0

var can_damage_player: bool = true
@onready var attack_timer := Timer.new()

# Constructor called by spawner
func initialize(starting_position, init_player_position):
	# spawning
	current_state = ENEMY_STATE.spawn_edge
	position = starting_position
	player_position = init_player_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)
	hitbox_component.damaged.connect(on_damaged)
	
	# values for navigation agent
	navigation_agent.path_desired_distance = nav_path_dist
	navigation_agent.target_desired_distance = nav_target_dist
	
	# do not call await during ready (await is called in actor_setup)
	actor_setup.call_deferred()
	
	# adding attack cooldown timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	add_child(attack_timer)
	
	# set up target distance for spawn_edge, calculate spawn_distance_vector using trig
	if current_state == ENEMY_STATE.spawn_edge:
		var spawn_angle = (Vector2.ZERO - Vector2(position.x, position.z)).angle() # get the angle
		var spawn_distance_x = position.x + spawn_distance_length * cos(spawn_angle) # do trig to find the distance
		var spawn_distance_z = position.z + spawn_distance_length * sin(spawn_angle)
		
		spawn_distance_vector = Vector3(spawn_distance_x, global_position.y + spawn_distance_height, spawn_distance_z)
		spawning_velocity = Vector3((spawn_distance_vector-global_position)/spawning_time)
		
		# disable collision
		collision.disabled = true
	
	# set the target
	set_movement_target(get_target_from_state(current_state))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta):
	# spawning along the edge, you will have a straight line to path towards until you reach the target
	if current_state == ENEMY_STATE.spawn_edge:
		if global_position.distance_to(spawn_distance_vector) < 0.1:
				# disable collision
				collision.disabled = false
				current_state = ENEMY_STATE.roam
				return
		velocity = spawning_velocity
	
	# finally move
	move_and_slide()

# When they dead as hell
func on_reach_zero_health():
	die.emit()
	self.queue_free()

# when you get damaged
func on_damaged(di: DamageInstance):
	if (hitflash_tween and hitflash_tween.is_running()):
		hitflash_tween.stop()
	hitflash_tween = get_tree().create_tween()
	$MeshInstance3D.material_overlay.albedo_color = Color(1.0, 1.0, 1.0, 1.0) # set alpha
	hitflash_tween.tween_property($MeshInstance3D, "material_overlay:albedo_color", Color(1.0, 1.0, 1.0, 0.0), 0.1) # tween alpha
	

# update pathfind when the timer happens
func _on_pathfind_timer_timeout() -> void:
	# update vars
	player_position = player.global_position
	
	# set new pathfind
	set_movement_target(get_target_from_state(current_state))

# setup for the actor to pathfind
func actor_setup():
	# wait for first physics frame
	await get_tree().physics_frame
	# set the movement target
	set_movement_target(get_target_from_state(current_state))

# get the nav target based on our state
func get_target_from_state(state):
	if state == ENEMY_STATE.roam:
		return player_position
	elif state == ENEMY_STATE.spawn_edge:
		return spawn_distance_vector

# set the movement target for navigation
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	next_path_position = navigation_agent.get_next_path_position()
	pathfindVel = global_position.direction_to(next_path_position) * movement_speed
