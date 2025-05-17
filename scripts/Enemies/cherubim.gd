extends EnemyBase

class_name Cherubim

# variables
@export var player_run_radius = 30
@export var comfy_radius = 35
@export var touch_damage = 3
@export var turn_angle = 0.5
var ishim: IshimRanger
var ishim_count = 0
var ishims = [null, null]
var alerted_ishims = []
var ishim_parent = null
var our_2D_pos: Vector2 = Vector2.ZERO
var player_2D_pos: Vector2 = Vector2.ZERO
var distance_towards_player: float = 0

# bullet vars
@export var bullet: PackedScene
@export var bullet_radius: float = 3
@export var bullet_velocity: float = 15
@export var bullet_gravity: float = -15
@export var bullet_range_close: float = 20
@export var bullet_velocity_close: float = 4
@export var bullet_gravity_close: float = -7

# components
@onready var shoot_timer = $ShootCooldown
@onready var mesh = $MeshInstance3D
@onready var shoot_point = $ShootPoint
@onready var ishim_area = $IshimArea
@onready var ishim_spot1 = $Ishim1
@onready var ishim_spot2 = $Ishim2

# signals
signal ishim_in_range

# colors
@onready var mat_roam: Color
@onready var mat_run_away: Color
@onready var mat_comfy: Color
var current_color

func _ready() -> void:
	# when in the comfy radius, the enemy will stand still
	# when the player gets too close itll run away
	ENEMY_STATE["comfy"] = total_states+1
	ENEMY_STATE["run_away"] = total_states+2
	total_states += 2
	
	# get ishim id
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.name == "Ishim":
			ishim = enemy
	
	# colors
	mat_roam = Color("f03b19")
	mat_run_away = Color("fd7257")
	mat_comfy = Color("991f07")
	current_color = mat_roam
	
	super._ready()

func _process(delta: float) -> void:
	pass
		#look_at(Vector3(player.global_position.x, position.y, player.global_position.z))
	
	#print("ishim count: " + str(ishim_count))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# turn towards the player
	#if current_state != ENEMY_STATE.spawn_edge:
		#if player and player.is_inside_tree():
			## get direction of self
			#var forward = -transform.basis.z
			#var facing_dir = Vector2(forward.x, forward.z).normalized()
			#
			## get direction of player
			#var distance_to_player = player.global_position - global_position
			#var facing_player = Vector2(distance_to_player.x, distance_to_player.z).normalized()
			#
			## angle
			#var angle_to_player = facing_dir.angle_to(facing_player)
			#
			#if abs(angle_to_player) > deg_to_rad(1):
				#var turn_sign = sign(angle_to_player)
				#rotate_y(deg_to_rad(turn_angle * turn_sign * -1))
		
	if current_state != ENEMY_STATE.spawn_edge:
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta
	
	# finally move
	move_and_slide()


func _on_pathfind_timer_timeout() -> void:
	if current_state == ENEMY_STATE.spawn_edge:
		return
	
	# we want to calculate only based on x and z, effectively an infinite cone
	our_2D_pos = Vector2(global_position.x, global_position.z)
	player_2D_pos = Vector2(player.global_position.x, player.global_position.z)
	distance_towards_player = our_2D_pos.distance_to(player_2D_pos)
	
	# change state if needed
	if distance_towards_player <= player_run_radius:
		current_state = ENEMY_STATE.run_away
	elif distance_towards_player <= comfy_radius:
		current_state = ENEMY_STATE.comfy
	else:
		current_state = ENEMY_STATE.roam
	
	# if we're not shooting for some reason?
	if shoot_timer.is_stopped():
		_on_shoot_cooldown_timeout()
		shoot_timer.start()
	
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
	else:
		return global_position

# whenever the timer ends, shoot! 
func _on_shoot_cooldown_timeout() -> void:
	if current_state != ENEMY_STATE.spawn_edge:
		var b = bullet.instantiate()
		if b == null: # just in case
			print("charubim.gd - bullet did not instantiate")
			return
		
		player_position = player.global_position #update the player pos for calculations
		var b_v = bullet_velocity
		var b_g = bullet_gravity
		
		# find displacement, distance, and use that to get time
		var displacement = Vector3(player_position.x, player_position.y + 5, player_position.z) - shoot_point.global_position
		var direction = displacement.normalized()
		var h_displacement: Vector3 = Vector3(displacement.x, 0, displacement.z)
		var h_distance = sqrt(displacement.x * displacement.x + displacement.z * displacement.z) # distance formula!
		if h_distance < bullet_range_close: # set vars to close vars if too close
			b_v = bullet_velocity_close
			b_g = bullet_gravity_close
		var t = max((h_distance / b_v), 0.01)

		# use time and kinematics to get velocity
		var h_v = Vector2(displacement.x, displacement.z).normalized() * b_v
		var v_v = (displacement.y + (0.5 * b_g * t * t)) / t
		var initial_velocity = Vector3(h_v.x, v_v, h_v.y)
		
		# initialize the bullet
		b.initialize(initial_velocity, direction, bullet_gravity, self)
		b.position = shoot_point.global_position
		
		World.world.add_child(b)

# used when a body is found within the hitbox
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

# used when an ishim ranger is found within the ishim range
func _on_ishim_area_body_entered(body: Node3D) -> void:
	if body is not IshimRanger:
		return
	
	# check if we are at max ishim
	if ishim_count < 2 && not body.cherubim_alerted:
		#print("signaling to: " + str(body))
		alerted_ishims.append(body)
		body.goto_cherubim(self)

func _on_ishim_reached_cherubim(ishim: IshimRanger) -> Node3D:
	# avoid duplicate enemies
	if ishim.current_state == ishim.ENEMY_STATE.cherubim_sit:
		return
	
	# get the ishim "slot"
	var ishim_slot = null
	if ishim_count < 2:
		for i in ishims.size():
			if ishims[i] == null:
				ishims[i] = ishim
				ishim.cherubim_slot = i
				if i == 0:
					ishim_slot = ishim_spot1
				else:
					ishim_slot = ishim_spot2
				break
	else:
		return
	
	# if there was no found slot
	if not ishim_slot:
		print("couldnt find slot! current count: " + str(ishim_count) + ", slots: " + str(ishims))
		return null
	
	# set ishim stuff
	ishim.velocity = Vector3.ZERO
	ishim.global_transform = transform
	ishim.current_state = ishim.ENEMY_STATE.cherubim_sit
	ishim_count += 1
	
	# reset alerted ishims if we've reached max
	if ishim_count >= 2:
		print("full:" + str(alerted_ishims))
		for i in alerted_ishims:
			if i is IshimRanger && i.current_state == i.ENEMY_STATE.cherubim_alert:
				i.cherubim_alerted = false
				i.current_state = i.ENEMY_STATE.roam
		alerted_ishims = []
	
	return ishim_slot

func _on_ishim_died(cherubim_slot):
	ishim_count -= 1
	ishims[cherubim_slot] = null
	reset_ishim_check()

# When they dead as hell
func on_reach_zero_health():
	# FREE ISHIMS
	for i in ishims:
		if i:
			if i == ishims[0]:
				i.global_position = ishim_spot1.global_position
			else:
				i.global_position = ishim_spot2.global_position
			i.current_state = i.ENEMY_STATE.roam
			i.cherubim_alerted = false
			i.cherubim_node = null
		
	super.on_reach_zero_health()

func reset_ishim_check():
	# reset the area
	ishim_area.monitoring = false
	ishim_area.monitoring = true
