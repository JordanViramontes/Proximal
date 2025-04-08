extends CharacterBody3D

@export var max_health: float
@export var hitflash_material: Material
@export var hitflash_duration: float = 0.1
var hitflash_tween: Tween

# components
@onready var health_component := $HealthComponent
@onready var hitbox_component := $HitboxComponent

# signals
signal die
signal take_damage

# player information
var player
var player_position
var path

# self information
@export var movement_speed = 5
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var nav_path_dist = 5
@export var nav_target_dist = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)
	hitbox_component.damaged.connect(on_damaged)
	
	# variables
	player = get_tree().get_first_node_in_group("Player")
	player_position = player.position
	path = 0
	
	# values for navigation agent
	navigation_agent.path_desired_distance = nav_path_dist
	navigation_agent.target_desired_distance = nav_target_dist
	
	# do not call await during ready (await is called in actor_setup)
	actor_setup.call_deferred()

# Constructor called by spawner
func initialize(starting_position, init_player_position):
	position = starting_position
	player_position = init_player_position
	look_at_from_position(position, init_player_position, Vector3.UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta):	
	# pathfinding
	if navigation_agent.is_navigation_finished():
		return
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var pathfindVel = current_agent_position.direction_to(next_path_position) * movement_speed
	velocity.x = pathfindVel.x
	velocity.z = pathfindVel.z
	
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# finally move
	move_and_slide()

# When they dead as hell
func on_reach_zero_health():
	die.emit()
	self.queue_free()

# when you get damaged
func on_damaged(amount: float):
	if (hitflash_tween and hitflash_tween.is_running()):
		hitflash_tween.stop()
	hitflash_tween = get_tree().create_tween()
	$MeshInstance3D.material_overlay.albedo_color = Color(1.0, 1.0, 1.0, 1.0) # set alpha
	hitflash_tween.tween_property($MeshInstance3D, "material_overlay:albedo_color", Color(1.0, 1.0, 1.0, 0.0), 0.1) # tween alpha

# update pathfind when the timer happens
func _on_pathfind_timer_timeout() -> void:
	player_position = player.global_position
	#look_at(player_position)
	set_movement_target(player_position)
	print("pos: " + str(global_position))
	print("player: " + str(player_position))

# setup for the actor to pathfind
func actor_setup():
	# wait for first physics frame
	await get_tree().physics_frame
	# set the movement target
	set_movement_target(player_position)

# set the movement target for navigation
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
