extends CharacterBody3D
class_name EnemyBase

# vars
@export var max_health: float = 10
@export var xp_on_damaged: float = 1
@export var xp_on_death: float = 2
@export var movement_speed = 5
@export var nav_path_dist = 2 
@export var nav_target_dist = 1 
@onready var next_path_position: Vector3
@onready var pathfindVel: Vector3
var can_damage_player: bool = true
var wave_category: int = 0
var is_dead = false
var health_multiplier = 1
var experience_multiplier = 1
var damage_multiplier = 1

# visual vars
@export var hitflash_material: Material
@export var hitflash_duration: float = 0.1
var hitflash_tween: Tween

# spawning variables
var spawn_distance_vector = Vector3(0, 0, 0)
var spawning_velocity = Vector3(0, 0, 0)
@export var spawning_time = 2
@export var spawn_distance_length = 1 # distance to travel towards origin
@export var spawn_distance_height = 3 # units to travel vertically while in spawning state

#vacuum pull
@export var weight = 1.0
var vacuum_velocity = Vector3.ZERO
var vacuum_timer = 0.0
var vacuum_duration = 3  # seconds
var vacuum_target_position: Vector3

# states
var ENEMY_STATE = {
	"roam":0,
	"spawn_edge":1,
	"dead":2,
	"stunned":3
}
var current_state = ENEMY_STATE.spawn_edge
var total_states = 3

# components
@onready var health_component := $HealthComponent
@onready var hitbox_component := $HitboxComponent
@onready var collision := $CollisionShape3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var pathfind_timer: Timer = $PathfindTimer
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var player_position

# signals
signal die
signal die_from_wave(wave: int)
signal take_damage
signal drop_xp(xp: float)
signal deal_damage(damage: float)

# Constructor called by spawner
func initialize(starting_position, init_player_position, wave, init_health_multiplier, init_damage_multiplier, init_xp_multiplier):
	# spawning
	current_state = ENEMY_STATE.spawn_edge
	position = starting_position
	player_position = init_player_position
	
	# vars
	wave_category = wave
	health_multiplier = init_health_multiplier
	max_health = max_health * health_multiplier
	experience_multiplier = init_xp_multiplier
	damage_multiplier = init_damage_multiplier

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# print:
	print("SPAWNING SELF: " + str(self))
	
	# connect signal to weaponmanager
	drop_xp.connect(weapon_manager._on_earn_experience)
	die.connect(weapon_manager._on_enemy_die)
	# health components
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)
	hitbox_component.damaged.connect(on_damaged)
	
	# values for navigation agent
	navigation_agent.path_desired_distance = nav_path_dist
	navigation_agent.target_desired_distance = nav_target_dist
	
	# set up target distance for spawn_edge, calculate spawn_distance_vector using trig
	if current_state == ENEMY_STATE.spawn_edge:
		spawning_velocity = calculateSpwaningVelocity()
		# disable collision
		collision.disabled = true
	
	# set the target
	set_movement_target(get_target_from_state(current_state))

func calculateSpwaningVelocity() -> Vector3:
	# use trig to find the distances for x and z
	var spawn_angle = (Vector2.ZERO - Vector2(position.x, position.z)).angle() # get the angle
	spawn_distance_vector = Vector3(
		position.x + spawn_distance_length * cos(spawn_angle), 
		global_position.y + spawn_distance_height, 
		position.z + spawn_distance_length * sin(spawn_angle))
	
	# return
	spawning_velocity = Vector3((spawn_distance_vector-global_position)/spawning_time)
	return spawning_velocity

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# kill self if we are out of bounds
	if global_position.y < -20:
		on_reach_zero_health()
	if hitflash_tween and not hitflash_tween.is_valid():
		hitflash_tween.kill()
	pass

func _physics_process(delta):
	if current_state == ENEMY_STATE.stunned:
		if vacuum_timer > 0.0:
			# If close enough to front of player, stop pulling
			if global_position.distance_to(vacuum_target_position) < 1.0:  # <-- Stop distance
				vacuum_velocity = Vector3.ZERO
				velocity = Vector3.ZERO
				#_on_recieve_stun()
				#await get_tree().create_timer(2).timeout # stun for 2 second after pull
				#_on_recieve_unstun() #stun process in the vacuum function
				return
			vacuum_timer -= delta
			velocity = vacuum_velocity
			move_and_slide()
			return
		else:
			vacuum_velocity = Vector3.ZERO
			velocity = Vector3.ZERO
			_on_recieve_stun()
			await get_tree().create_timer(2).timeout # stun for 2 second after pull
			_on_recieve_unstun()  #stun process in the vacuum function
			move_and_slide()
			return
	# Spawning logic
	if current_state == ENEMY_STATE.spawn_edge:
		if global_position.distance_to(spawn_distance_vector) < 0.1:
			collision.disabled = false
			current_state = ENEMY_STATE.roam
			velocity = Vector3.ZERO
			return
		velocity = spawning_velocity

	# Default movement
	move_and_slide()

# When they dead as hell
func on_reach_zero_health():
	# we already died!
	if is_dead:
		return
	
	print("we are dying! emitting signals: " + str(self))
	is_dead = true
	emit_signal("die_from_wave", wave_category)
	die.emit()
	emit_signal("drop_xp", xp_on_death * experience_multiplier) # emit experience points
	self.queue_free()

# when you get damaged
func on_damaged(di: DamageInstance):
	if (hitflash_tween and hitflash_tween.is_running()):
		hitflash_tween.stop()
	hitflash_tween = get_tree().create_tween()
	
	var visual_element = get_node_or_null("MeshInstance3D")
	if not visual_element or not visual_element.visible:
		visual_element = get_node_or_null("Sprite3D")
		if not visual_element:
			print("%s does not have any visual represnetation to put a hitflash material on! resolve this immediately." % self)
	
	if visual_element:
		if visual_element is Sprite3D:
			# hope and pray that the sprite has the shader param we're looking for
			if visual_element.material_override: # baby ass safeguard
				hitflash_tween.tween_method(
					awesome.bind(visual_element),
					2.0, 
					0.0, 
					0.1
				)

		elif visual_element is MeshInstance3D:
			if visual_element.material_overlay == null:
				var new_material := StandardMaterial3D.new()
				visual_element.material_overlay = new_material
			visual_element.material_overlay.albedo_color = Color(1.0, 1.0, 1.0, 1.0) # set alpha
			hitflash_tween.tween_property(visual_element, "material_overlay:albedo_color", Color(1.0, 1.0, 1.0, 0.0), 0.1) # tween alpha

	emit_signal("drop_xp", xp_on_damaged * experience_multiplier) # emit experience points 

func awesome(value: float, visual_element: Sprite3D): 
	if visual_element:
		visual_element.material_override.set_shader_parameter("hitflash_amount", value)

# update pathfind when the timer happens
func _on_pathfind_timer_timeout() -> void:
	# update vars
	player_position = player.global_position
	
	# set new pathfind
	set_movement_target(get_target_from_state(current_state))

# get the nav target based on our state
func get_target_from_state(state):
	if state == ENEMY_STATE.roam:
		return player_position
	elif state == ENEMY_STATE.spawn_edge:
		return spawn_distance_vector
	else:
		return global_position

# set the movement target for navigation
func set_movement_target(movement_target: Vector3):
	# only update if we've moved a good amount
	if navigation_agent.target_position.distance_to(movement_target) > 0.1:
		navigation_agent.set_target_position(movement_target)
	
	next_path_position = navigation_agent.get_next_path_position()
	pathfindVel = global_position.direction_to(next_path_position) * movement_speed

func deal_damage_to_player(di: DamageInstance):
	di.damage *=  damage_multiplier
	# check if the player can take damage
	if player.can_take_damage:
		player.get_node("HitboxComponent").damage(di)

func _on_recieve_stun() -> void:
	print("enemy_base.gd stunned: " + str(self))
	current_state = ENEMY_STATE.stunned
	pathfind_timer.stop() # disable pathfinding
	pathfind_timer.autostart = false
	can_damage_player = false

func _on_recieve_unstun() -> void:
	print("enemy_base.gd un-stunned: " + str(self))
	current_state = ENEMY_STATE.roam
	pathfind_timer.start() # disable pathfinding
	pathfind_timer.autostart = true
	can_damage_player = true
	
func apply_vacuum_force(direction: Vector3, strength: float, target_pos: Vector3):
	vacuum_target_position = target_pos
	vacuum_velocity = direction.normalized() * (strength / weight)
	vacuum_timer = vacuum_duration
	_on_recieve_stun()
	
