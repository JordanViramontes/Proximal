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
var MOUSE_SENS = remap(ConfigFileHandler.load_mouse_sens_settings(), 0.0, 100.0, 0.05, 1.0)

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
@export var DEATH_HEIGHT = -40.0
@export var max_health: float = 100
@export var damage_visual_per_hit: float = 0.1
var current_health: int = max_health
var can_take_damage: bool = true
var is_healing: bool = false
var healing_timer: float = 0.5

#sliding
var slide_velocity: Vector3 = Vector3.ZERO
@export var slide_duration := 0.75
var current_slide_time := 0.0
@export var slide_cooldown := 1.5 # cooldown in seconds
var last_slide_time := -1.5 # start it negative so you can slide immediately

func is_dashing() -> bool:
	return current_dash_time > 0

func _ready() -> void:
	# update sensitivity during gameplay
	var options_menu = $"../../../UI/PauseMenu"
	options_menu.mouse_sens_changed.connect(_on_mouse_sens_changed)
	
	# setup health component
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)
	hitbox_component.damaged.connect(on_damaged)
	# slide height
	normal_height = head.position.y
	#shield visual
	Util.toggle_shield.connect(on_toggle_shield)
	weapon.abilityInput.connect(on_ability_shoot)
	#healing
	Util.healing.connect(on_heal)
	#damage amp visual on sniper ability
	#Util.sniper_visual.connect(on_sniper_visual)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
			#print("healing! total health: " + str(health_component.current_health))
			healing_timer = 0.5

	
	if Input.is_action_just_pressed("slide") and is_on_floor():
		buffered_slide = true


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
		var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
		var vel_change_dir = (self.velocity.normalized() + wish_dir).normalized() * cur_speed_in_wish_dir * delta
		self.velocity += vel_change_dir

		# and this friction
		var drop = slide_deccel * delta * 0.01
		var new_speed = max(self.velocity.length() - drop, 0.0)
		if self.velocity.length() > 0:
			new_speed /= self.velocity.length()
		self.velocity *= new_speed

		
	if is_sliding and velocity.length() < 2.0:
		exit_slide()

	
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
	var input_dir = Input.get_vector("left", "right", "forward", "back").normalized()

	current_strafe_dir = input_dir.x
	current_forward_dir = input_dir.y
	wish_dir = global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)

	handle_jumping()
	handle_shooting()

	if is_on_floor():
		if buffered_slide and not is_sliding:
			enter_slide()
			buffered_slide = false  # reset to avoid repeated sliding

		if is_sliding:
			current_slide_time -= delta
			
			# decelerate slide velocity
			var friction := 10.0
			slide_velocity = slide_velocity.move_toward(Vector3.ZERO, friction * delta)
			velocity = slide_velocity
			
			# exit slide when time runs out or speed too low
			if current_slide_time <= 0.0 or slide_velocity.length() < 1.0:
				exit_slide()
		else:
			_handle_ground_physics(delta)

		double_jumpable = true
	else:
		_handle_air_physics(delta)

	if is_dashing():
		current_dash_time -= delta
		if current_dash_time <= 0.0:
			handle_finish_dash()
	
	if position.y < DEATH_HEIGHT && current_state != INPUT_STATE.dead:
		kill_player()

	move_and_slide()


func handle_jumping():
	if is_sliding:
		return  # prevent jumping during slide
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if is_dashing():
			current_dash_time = 0.0  # stop dash
		velocity.y = jump_velocity
		is_sliding = false
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and double_jumpable:
		# double jumping
		double_jumpable = false
		velocity.y = jump_velocity
		is_sliding = false

func handle_shooting():
	if Input.is_action_pressed("shoot"):
		weapon.shoot(head.global_position, -head.global_basis.z, velocity) # pass player "eye" position
	if Input.is_action_just_released("shoot"):
		weapon.cease_fire()

func handle_finish_dash() -> void:
	self.velocity /= 5

func enter_slide() -> void:

	var current_time = Time.get_ticks_msec() / 1000.0

	if not is_on_floor() or is_sliding:
		return
	
	if current_time - last_slide_time < slide_cooldown:
		return  # still in cooldown

	last_slide_time = current_time  # set new cooldown timer
	#print("sliding")
	is_sliding = true
	current_state = INPUT_STATE.sliding
	current_slide_time = slide_duration

	head.position.y = slide_height

	if velocity.length() > 0.5:
		slide_velocity = velocity.normalized() * (walk_speed + slide_speed_boost)
	else:
		slide_velocity = look_direction.normalized() * (walk_speed + slide_speed_boost)

func exit_slide() -> void:
	is_sliding = false
	current_state = INPUT_STATE.normal
	head.position.y = normal_height
	slide_velocity = Vector3.ZERO
	velocity = Vector3.ZERO  # reset player velocity when slide ends


# recieve dash input from WeaponManager
func _on_weapon_manager_dash_input() -> void:
	if is_dashing():
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - last_dash_time < dash_cooldown:
		return

	# Cancel slide if dashing during slide
	if is_sliding:
		exit_slide()

	last_dash_time = current_time
	current_dash_time = dash_timer

	var dash_vel: Vector3 = wish_dir.normalized()
	if dash_vel.is_zero_approx():
		dash_vel = Vector3(look_direction.x, 0.0, look_direction.z)

	velocity = dash_vel * DASH_SPEED * Vector3(1, 0.2, 1)
	#velocity.y = 0
	#print("velocity: " + str(velocity))

func kill_player():
	# dont call signals a bunch
	if current_state == INPUT_STATE.dead:
		return
	
	die.emit()
	current_state = INPUT_STATE.dead
	#print("player dead!")

# When they dead as hell
func on_reach_zero_health():
	health_component.damageable = false
	kill_player()

# when you get damaged
func on_damaged(di: DamageInstance):
	#print("damage deal to me!: " + str(di.damage) + ",\ttotal health: " + str(health_component.current_health))
	Util.damage_taken.emit(damage_visual_per_hit)
	
func on_toggle_shield(state:bool):
	if state == true:
		can_take_damage = false
	else:
		can_take_damage = true

# for shooting/projectile abilities
func on_ability_shoot():
	if is_dashing():
		return
	else:
		weapon.ability_shoot(head.global_position, -head.global_basis.z, velocity)
	
func on_heal(state: bool) -> void:
	is_healing = state
		
#func on_sniper_visual(state:bool):
	#if state == true:
		#$UI/sniper_visual.show()
	#else:
		#$UI/sniper_visual.hide()

# when the hitbox area is entered!!!!!!!!!!!!!!!!!!!!
func _on_ring_pickup_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("RingPickup"):
		weapon.add_ring()
		area.get_parent().queue_free()
func _on_mouse_sens_changed(new_sens):
	MOUSE_SENS = remap(ConfigFileHandler.load_mouse_sens_settings(), 0.0, 100.0, 0.05, 1.0)
