class_name Player extends CharacterBody3D

# signals
signal die
signal take_damage
signal player_die
signal health_change

# input stuff
# states
enum INPUT_STATE {normal, sliding, dead}
var current_state = INPUT_STATE.normal
@export_category("Input Settings")
@export var MOUSE_SENS = 0.3

# speed and walking
# OVERHAUL CONTROLLER
var wish_dir := Vector3.ZERO
@export_category("Movement")
# ground movement settings
@export var walk_speed := 20.0
@export var ground_accel := 14.0
@export var ground_deccel := 10.0
@export var ground_friction := 2.5

# air movement settings
@export var air_cap := 10.0
@export var air_accel := 50.0
@export var air_move_speed := 50.0
@export var air_speed_limit := 20.0 # hard limit on air speed
@export var air_deccel := 0.5
@export var air_friction := 1.0
@export var jump_velocity = 4.5

var look_direction = Vector3.ZERO


const HEADBOB_MOVE_AMOUNT = 0.01
const HEADBOB_FREQUENCY = 1.0
var headbob_time := 0.0

# jumping
var double_jumpable := false

# sliding
@export_category("Sliding")
@export var slide_height: float = 0.5
@export var slide_deccel: float = 0.80
@export var slide_speed_boost: float = 10.0
var normal_height: float
var buffered_slide: bool = false
var is_sliding: bool = false

# Abilities
@export_category("Abilities")
# dashing
@export var DASH_SPEED = 20
@export var dash_accel = 5
@export var dash_cooldown := 0.5
@export var dash_timer := 0.4 # dash lasts for this long
var current_dash_time := 0.0 
var last_dash_time := -dash_cooldown
@export var ring_healing_amount: float = 5

# h
const height = 1.8

# leaning
@export_category("Camera Properties")
@export var LEAN_MULT = 0.01
@export var LEAN_SMOOTH = 10.0
@export var LEAN_AMOUNT = 0.0005
var current_strafe_dir = 0
var current_forward_dir = 0

# components
@onready var lean_pivot := $LeanPivot
@onready var head := $LeanPivot/Head
@onready var camera := $LeanPivot/Head/ShakeableCamera
@onready var weapon := $LeanPivot/Head/Weapon_Manager
@onready var health_component := $HealthComponent
@onready var hitbox_component := $HitboxComponent

# health variables
@export_category("Misc Health and Damage")
@export var DEATH_HEIGHT = -200.0
@export var max_health: float = 100
var current_health: int = max_health
var can_take_damage: bool = true
var is_healing: bool = false
var healing_timer: float = 0.5

func is_dashing() -> bool:
	return current_dash_time > 0

func _ready() -> void:
	# setup health component
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)
	hitbox_component.damaged.connect(on_damaged)
	# slide height
	normal_height = head.position.y
	Util.toggle_shield.connect(on_toggle_shield)
	weapon.abilityInput.connect(on_ability_shoot)
	Util.healing.connect(on_heal)

# inputs
func _input(event: InputEvent) -> void:
	# input state 
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		if current_state != INPUT_STATE.dead:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS)) # yaw
			head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS)) # pitch
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	camera.position = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0.0
	)

# frame by frame
func _process(delta: float):
	lean_pivot.rotation.z = lerp(lean_pivot.rotation.z, -current_strafe_dir * LEAN_MULT, delta * LEAN_SMOOTH) # this causes some weirdness when you look down/up, working on a fix
	lean_pivot.rotation.x = lerp(lean_pivot.rotation.x, 0.5 * current_forward_dir * LEAN_MULT, delta * LEAN_SMOOTH)
	look_direction = -head.global_basis.z
	
	if is_healing == true:
		healing_timer -= delta
		if healing_timer <= 0:
			health_component.heal(ring_healing_amount);
			print("healing! total health: " + str(health_component.current_health))
			healing_timer = 0.5

	
	if Input.is_action_just_pressed("slide"):
		buffered_slide = true
	if Input.is_action_just_released("slide"):
		buffered_slide = false
		if is_sliding: exit_slide()


func _handle_air_physics(delta: float) -> void:
	if is_dashing(): return
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_til_cap = capped_speed - (cur_speed_in_wish_dir)
	if add_speed_til_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_til_cap)
		if self.velocity.length() < air_speed_limit:
			self.velocity += accel_speed * wish_dir


func _handle_ground_physics(delta: float) -> void:
	if is_dashing(): return
	
	if is_sliding:
		# keep the same velocity that they entered with
		var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
		var vel_change_dir = (self.velocity.normalized() + wish_dir).normalized() * cur_speed_in_wish_dir * delta
		
		self.velocity += vel_change_dir
		
		
		# just add some friction
		var drop = slide_deccel * delta * 0.01
		var new_speed = max(self.velocity.length() - drop, 0.0)
		if self.velocity.length() > 0:
			new_speed /= self.velocity.length()
		self.velocity *= new_speed
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_til_cap = walk_speed - cur_speed_in_wish_dir
	if add_speed_til_cap > 0:
		var accel_speed = ground_accel * delta * walk_speed
		accel_speed = min(accel_speed, add_speed_til_cap)
		self.velocity += accel_speed * wish_dir
	
	# friction
	var control = max(self.velocity.length(), ground_deccel)
	#print("velocity length: %s" % self.velocity.length())
	var drop = control * ground_friction * delta * 0.05
	#print("drop: %s" % drop)
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	_headbob_effect(delta)

# frame by frame physics
func _physics_process(delta: float) -> void:
		
		## transition to sliding state
		#if is_sliding: 
			#current_state = INPUT_STATE.sliding
			#head.position.y = slide_height
			## give initial boost of speed if we're grounded
			#if is_on_floor():
				#var add_amount = velocity.normalized() * slide_speed_boost
				#velocity += add_amount
		#
		## shooting
		#handle_shooting()
		#
		#
	
	var input_dir = Input.get_vector("left", "right", "forward", "back").normalized()
	
	current_strafe_dir = input_dir.x
	current_forward_dir = input_dir.y
	
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	handle_jumping()
	handle_shooting()
	if is_dashing():
		current_dash_time -= delta
		if current_dash_time <= 0.0:
			handle_finish_dash()
	
	if is_on_floor():
		if buffered_slide: enter_slide()
		_handle_ground_physics(delta)
		double_jumpable = true
	else:
		_handle_air_physics(delta)
	
	if self.position.y < DEATH_HEIGHT:
		kill_player()
	
	move_and_slide()

func handle_jumping():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if is_dashing:
			current_dash_time = 0.0 # stop dash
		self.velocity.y = jump_velocity
		is_sliding = false
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and double_jumpable:
		# double jumping
		double_jumpable = false
		self.velocity.y = jump_velocity
		is_sliding = false

func handle_shooting():
	if Input.is_action_pressed("shoot"):
		weapon.shoot(head.global_position, -head.global_basis.z, velocity) # pass player "eye" position
	if Input.is_action_just_released("shoot"):
		weapon.cease_fire()

func handle_finish_dash() -> void:
	self.velocity /= 5

func enter_slide() -> void:
	is_sliding = true
	head.position.y = slide_height
	#if is_on_floor():
		## add slide boost velocity
		#var add_amount = self.velocity.normalized() * slide_speed_boost
		#self.velocity += add_amount

func exit_slide() -> void:
	is_sliding = false
	head.position.y = normal_height

# recieve dash input from WeaponManager
func _on_weapon_manager_dash_input() -> void:
	if current_state != INPUT_STATE.normal or is_dashing():
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0 # get time in seconds
	if current_time - last_dash_time < dash_cooldown:
		return # skip dash
	
	last_dash_time = current_time # timer reset
	var dash_vel: Vector3 = wish_dir.normalized()
	if dash_vel.is_zero_approx():
		dash_vel = Vector3(look_direction.x, 0.0, look_direction.z)
	#var dash_vel: Vector3 = look_direction.normalized()
	print("dashing! input: " + str(dash_vel))
	
	current_dash_time = dash_timer
	
	velocity += dash_vel * DASH_SPEED * Vector3(1, 0.2, 1)
	#velocity.y = 0
	#print("velocity: " + str(velocity))

func kill_player():
	die.emit()
	current_state = INPUT_STATE.dead
	print("player dead!")

# When they dead as hell
func on_reach_zero_health():
	health_component.damageable = false
	kill_player()

# when you get damaged
func on_damaged(di: DamageInstance):
	print("damage deal to me!: " + str(di.damage) + ",\ttotal health: " + str(health_component.current_health))
	
func on_toggle_shield(state:bool):
	if state == true:
		$UI/shield_visual.show()
		can_take_damage = false
	else:
		$UI/shield_visual.hide()
		can_take_damage = true
	pass

# for shooting/projectile abilities
func on_ability_shoot():
	weapon.ability_shoot(head.global_position, -head.global_basis.z, velocity)
	
func on_heal(state: bool) -> void:
	is_healing = state
		
