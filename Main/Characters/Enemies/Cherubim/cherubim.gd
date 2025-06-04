extends EnemyBase

class_name Cherubim
func get_custom_class(): return "Cherubim"

# variables
@export var player_run_radius = 30
@export var comfy_radius = 35
@export var touch_damage = 3
@export var turn_angle = 0.5
var ishim: IshimRanger
var ishim_count = 0
var ishims = [null, null]
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
signal tell_ishim_to_come(cherubim: Cherubim)
signal tell_ishim_to_stop_coming
signal sit_ishim_on_me(node: Node3D)
signal tell_ishim_i_died

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
	#for enemy in get_tree().get_nodes_in_group("Enemies"):
		#if enemy.name == "Ishim":
			#ishim = enemy
	
	# colors
	mat_roam = Color("f03b19")
	mat_run_away = Color("fd7257")
	mat_comfy = Color("991f07")
	current_color = mat_roam
	
	# disable hitbox
	ishim_area.set_deferred("monitoring", false)
	
	super._ready()

func _process(delta: float) -> void:
	pass
		#look_at(Vector3(player.global_position.x, position.y, player.global_position.z))
	
	#print("ishim count: " + str(ishim_count))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# turn towards the player
	if current_state != ENEMY_STATE.spawn_edge:
		if player and player.is_inside_tree():
			# get direction of self
			var forward = -transform.basis.z
			var facing_dir = Vector2(forward.x, forward.z).normalized()
			
			# get direction of player
			var distance_to_player = player.global_position - global_position
			var facing_player = Vector2(distance_to_player.x, distance_to_player.z).normalized()
			
			# angle
			var angle_to_player = facing_dir.angle_to(facing_player)
			
			if abs(angle_to_player) > deg_to_rad(1):
				var turn_sign = sign(angle_to_player)
				rotate_y(deg_to_rad(turn_angle * turn_sign * -1))
	
	# gravity
	if current_state not in [ENEMY_STATE.spawn_edge, ENEMY_STATE.stunned]:
		if not is_on_floor():
			velocity += get_gravity() * delta
	
	# finally move
	move_and_slide()


func _on_pathfind_timer_timeout() -> void:
	if current_state in [ENEMY_STATE.spawn_edge, ENEMY_STATE.stunned]:
		return
	
	# enable hitbox if not already
	if ishim_area.monitoring == false:
		ishim_area.set_deferred("monitoring", true)
	
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
		
	# check for ishim
	if ishim_count < 2:
		#print("need ishim!")
		ishim_area.set_deferred("monitoring", false)
		ishim_area.set_deferred("monitoring", true)
	
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
	if not can_damage_player:
		return
	
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
	# check
	if body is not IshimRanger:
		return
	
	# avoid alreting cherubims that are already alerted
	if body.cherubim_alerted:
		return
	
	#print("found: " + str(body))
	if ishim_count < 2:
		# connect signals to the desired ishim ranger
		#print("connecting to and signlaing to: " + str(body))
		self.tell_ishim_to_come.connect(body.on_alerted_to_run_to_cherubim)
		self.tell_ishim_to_stop_coming.connect(body.on_alerted_to_stop_running_to_cherubim)
		body.tell_cherubim_we_died.connect(self.on_ishim_dies_while_running)
		body.reached_cherubim_friend.connect(self.on_ishim_reaches_cherubim)
		emit_signal("tell_ishim_to_come", self)
		#alerted_ishims.push_back(body)
		ishim_count += 1
		#print("COUNT NOW: " + str(ishim_count))
		
		# disable area if we hit 2
		if ishim_count >= 2:
			ishim_area.set_deferred("monitoring", false)

# signal recieved from cherubim when it reaches me!
func on_ishim_reaches_cherubim(ishim: IshimRanger):
	#print("cherubim.gd: reached: " + str(ishim))
	# get the next availble seat
	var nodeCnt = 0
	for i in ishims:
		if not i: # seat available
			#print("seat available at " + str(nodeCnt))
			ishims[nodeCnt] = ishim
			self.tell_ishim_to_come.disconnect(ishim.on_alerted_to_run_to_cherubim)
			self.tell_ishim_to_stop_coming.disconnect(ishim.on_alerted_to_stop_running_to_cherubim)
			ishim.reached_cherubim_friend.disconnect(self.on_ishim_reaches_cherubim)
			break
		nodeCnt += 1
	
	# sit them
	if nodeCnt == 0:
		#emit_signal("sit_ishim_on_me", ishim_spot1)
		ishim.on_cherubim_wants_us_seated(ishim_spot1, 0)
	elif nodeCnt == 1:
		#emit_signal("sit_ishim_on_me", ishim_spot2)
		ishim.on_cherubim_wants_us_seated(ishim_spot2, 1)
	else:
		print("cherubim.gd: NOWERE FOR ISHIM TO SIT!!")
		return
	
	# connect
	self.tell_ishim_i_died.connect(ishim.on_alerted_cherubim_died)

func on_ishim_dies_while_running(ishim: IshimRanger, index: int) -> void:
	ishim_count -= 1
	
	# remove ishim from node
	if index != -1:
		ishims[index] = null
	
	# look for ishims
	if ishim_area.monitoring == false:
		ishim_area.set_deferred("monitoring", true)

# When they dead as hell
func on_reach_zero_health():
	# FREE ISHIMS
	for i in ishims:
		if i:
			emit_signal("tell_ishim_i_died")
		
	super.on_reach_zero_health()
