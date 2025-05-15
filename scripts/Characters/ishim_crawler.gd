extends EnemyBase

class_name IshimCrawler

# var
@export var friction = 12
@export var lunge_dist = 16
@export var lunge_range = 12
@export var is_lunging = false
@export var touch_damage = 1

# components
@onready var lunge_timer = $LungeTimer
@onready var mesh = $MeshInstance3D

# colors
@onready var mat_roam = StandardMaterial3D.new()
@onready var mat_lunge = StandardMaterial3D.new()

func _ready():
	# update states
	ENEMY_STATE["lunge"] = total_states+1
	total_states += 1
	
	# set colors
	mat_roam.albedo_color = Color("4185ff")
	mat_lunge.albedo_color = Color("003187")
	
	super._ready()  # calls EnemyBase's _ready()

func _process(delta: float) -> void:
	super._process(delta)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if current_state == ENEMY_STATE.roam:
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta
	elif current_state == ENEMY_STATE.lunge:
		# friction
		if velocity.length() > 0: # check if the enemy is moving
			# velocity.normalized gives direction, friction * delta gives friction for this frame
			var friction_force = velocity.normalized() * friction * delta 
			if friction_force.length() > velocity.length(): # checks if it will overshoot
				velocity.x = 0
				velocity.z = 0
			else:
				velocity.x -= friction_force.x
				velocity.z -= friction_force.z
		
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta
	
	# finally move
	move_and_slide()

func get_target_from_state(state):
	if state == ENEMY_STATE.roam:
		return player_position
	elif state == ENEMY_STATE.lunge:
		return player_position
	elif state == ENEMY_STATE.spawn_edge:
		return spawn_distance_vector
	else:
		return global_position

# pathfinding state
func _on_pathfind_timer_timeout() -> void:
	# check for spawn edge
	if current_state == ENEMY_STATE.spawn_edge:
		return
	
	# updates path including next_path_position
	super._on_pathfind_timer_timeout()
	
	# if we weren't in lunge distance but now are, update state 
	if current_state != ENEMY_STATE.lunge && (global_position - player_position).length() < lunge_range:
		current_state = ENEMY_STATE.lunge # change state
		mesh.set_surface_override_material(0, mat_lunge)
		lunge() # force a lunge
		lunge_timer.start()
		lunge_timer.autostart = true
	elif current_state == ENEMY_STATE.roam:
		velocity.x = pathfindVel.x
		velocity.z = pathfindVel.z

# timer for the lunge in lunge state
func _on_lunge_timer_timeout() -> void:
	# check if we're done with lunging
	if not (global_position - player_position).length() < lunge_range:
		current_state = ENEMY_STATE.roam
		mesh.set_surface_override_material(0, mat_roam)
		return
	
	# update nav stuff
	super._on_pathfind_timer_timeout()
	
	# to avoid wonky movement
	if not is_on_floor():
		return
	
	lunge()

# the code for actually lunging the enemy
func lunge():
	# the t value for the equation is the same as the pathfind timer,
	# AKA every time the pathfinder timer is called, the enemy should reach the intended spot
	# use kinematics to find init v in reguards to the lung dist, direction is found by pathfinder
	var local_destination = next_path_position - global_position
	var t = lunge_timer.wait_time
	var init_v = (lunge_dist + (1/2 * friction * t*t)) / t # kinematics
	var direction = local_destination.normalized()
	direction.y = 0
	
	# velocity for this cycle
	velocity = direction * init_v

# when it physically touches the player
func _on_hitbox_component_body_entered(body: Node3D) -> void:
	if (body != player):
		return
	
	# create damage instance
	var di = DamageInstance.new({ # haha directional input!!! no. not funny.
		"damage" : touch_damage,
		"creator_position" : global_position,
		#"velocity" : direction * bullet_speed,
		#"type" : type
	})
	deal_damage_to_player(di)
