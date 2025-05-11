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
var cur_speed = 5.0
@export_category("Movement")
@export var MAX_WALKING_SPEED = 15.0
@export var WALKING_SPEED = 50.0
@export var MAX_AIR_SPEED = 30.0
@export var CROUCH_SPEED = 3.0
@export var JUMP_VELOCITY = 4.5

@export var accel_speed = 10.0
@export var ground_friction: float = 10.0
@export var air_friction: float = 2.0

var direction = Vector3.ZERO

var look_direction = Vector3.ZERO

# jumping
var double_jumpable := false

# sliding
@export_category("Sliding")
@export var slide_height: float = 0.5
@export var slide_deccel: float = 6.0
@export var slide_speed_boost: float = 10.0
var normal_height: float
var is_sliding: bool = false

# Abilities
@export_category("Abilities")
@export var DASH_SPEED = 40
@export var dash_accel = 5
@export var DASH_COOLDOWN := 0.5
var last_dash_time := -DASH_COOLDOWN

# h
const height = 1.8

# leaning
@export_category("Camera Properties")
@export var LEAN_MULT = 0.66
@export var LEAN_SMOOTH = 10.0
@export var LEAN_AMOUNT = 0.7 
var current_strafe_dir = 0

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
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-75), deg_to_rad(80))

# frame by frame
func _process(delta: float):
	lean_pivot.rotation.z = lerp(lean_pivot.rotation.z, current_strafe_dir * LEAN_MULT, delta * LEAN_SMOOTH) # this causes some weirdness when you look down/up, working on a fix
	look_direction = -head.global_basis.z
	
	if is_healing == true:
		healing_timer -= delta
		if healing_timer <= 0:
			health_component.heal(60);
			print("healing! total health: " + str(health_component.current_health))
			healing_timer = 0.5

	
	if Input.is_action_just_pressed("slide"):
		is_sliding = true
	if Input.is_action_just_released("slide"):
		is_sliding = false

# frame by frame physics
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else: 
		double_jumpable = true # when you touch the ground you can double jump again
	
	
	
	if current_state == INPUT_STATE.normal:
		var h_rot = global_transform.basis.get_euler().y
		if self.position.y < DEATH_HEIGHT:
			kill_player()
			
		cur_speed = WALKING_SPEED
		
		# jumping
		handle_jumping()
		
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		if (input_dir.x < 0):
			current_strafe_dir = LEAN_AMOUNT
		elif (input_dir.x > 0):
			current_strafe_dir = -LEAN_AMOUNT
		else:
			current_strafe_dir = 0
		
		
		
		#direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
		direction = lerp(direction, Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, h_rot).normalized(), delta * accel_speed)
		
		#direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, h_rot).normalized()
		
		# moving somewhere
		if direction:
			#velocity.x += direction.x * cur_speed * delta
			#velocity.z += direction.z * cur_speed * delta
			#
			## decceleration
			var fric = Vector3.ZERO
			if is_on_floor():
				fric = ground_friction
			else: 
				fric = air_friction
			#
			##print(Vector3(velocity.x, 0.0, velocity.z).length())
			#var max_speed = Vector3.ZERO
			#if is_on_floor():
				#max_speed = MAX_WALKING_SPEED
			#else:
				#max_speed = MAX_AIR_SPEED
			#
			#if Vector3(velocity.x, 0.0, velocity.z).length() >= max_speed:
				#var vectorized_max_speed = Vector3(velocity.x, 0.0, velocity.z).normalized() * max_speed
				#velocity.x = move_toward(velocity.x, vectorized_max_speed.x, fric * delta)
				#velocity.z = move_toward(velocity.z, vectorized_max_speed.z, fric * delta)
			
			
			# X check if we're above walking speed (dashing)
			if Vector3(velocity.x, 0.0, velocity.z).length() <= WALKING_SPEED:
				velocity.x = direction.x * cur_speed
				velocity.z = direction.z * cur_speed
			else:
				var vectorized_max_speed = Vector3(velocity.x, 0.0, velocity.z).normalized() * WALKING_SPEED
				velocity.x = move_toward(velocity.x, vectorized_max_speed.x, fric * delta)
				velocity.z = move_toward(velocity.z, vectorized_max_speed.z, fric * delta)
				#velocity.x = move_toward(velocity.x, sign(velocity.x) * WALKING_SPEED, fric)
			#elif velocity.x > 0:
				#velocity.x -= dash_accel
			#elif velocity.x < 0:
				#velocity.x += dash_accel
			
			## Z check if we're above walking speed (dashing)
			#if abs(velocity.z) <= WALKING_SPEED:
				#velocity.z = direction.z * cur_speed
			#else:
				#velocity.z = move_toward(velocity.z, sign(velocity.z) * WALKING_SPEED, fric)
			##elif velocity.z > 0:
				##velocity.z -= dash_accel
			##elif velocity.z < 0:
				##velocity.z += dash_accel
		
		else:
			var fric = Vector2.ZERO
			if is_on_floor():
				fric = ground_friction
			else: 
				fric = air_friction
			velocity.x = move_toward(velocity.x, 0.0, fric * delta)
			velocity.z = move_toward(velocity.z, 0.0, fric * delta)
			#head.rotate_object_local()
		
		# transition to sliding state
		if is_sliding: 
			current_state = INPUT_STATE.sliding
			head.position.y = slide_height
			# give initial boost of speed if we're grounded
			if is_on_floor():
				var add_amount = velocity.normalized() * slide_speed_boost
				velocity += add_amount
		
		# shooting
		handle_shooting()
		
		
	if current_state == INPUT_STATE.sliding:
		# keep velocity we entered with, slowly decrease it
		velocity.x = move_toward(velocity.x, 0, slide_deccel*delta)
		velocity.z = move_toward(velocity.z, 0, slide_deccel*delta)
		
		handle_jumping()
		handle_shooting()
		
		if !is_sliding:
			current_state = INPUT_STATE.normal
			head.position.y = normal_height
	
	move_and_slide()

func handle_jumping():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_sliding = false
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and double_jumpable:
		# double jumping
		double_jumpable = false
		velocity.y = JUMP_VELOCITY
		is_sliding = false

func handle_shooting():
	if Input.is_action_pressed("shoot"):
		weapon.shoot(head.global_position, -head.global_basis.z, velocity) # pass player "eye" position
	if Input.is_action_just_released("shoot"):
		weapon.cease_fire()

# health specific functionality
#func take_damage(amount: int) -> void:
	#if current_state == INPUT_STATE.dead:
		#return
		#
	#current_health -= amount
	#health_change.emit()
	#print("Player took", amount, "damage. Health:", current_health)
	#
	#if current_health <= 0:
		#die()

# you dead
#func die():
	## omae wa mou shindeiru
	#if current_state == INPUT_STATE.dead:
		#return
		#
	## invoke player_die signal
	#current_state = INPUT_STATE.dead
	#emit_signal("player_die")
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#print("Player has died.")

# recieve dash input from WeaponManager
func _on_weapon_manager_dash_input() -> void:
	if current_state != INPUT_STATE.normal:
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0 # get time in seconds
	if current_time - last_dash_time < DASH_COOLDOWN:
		return # skip dash
	
	last_dash_time = current_time # timer reset
	#var dash_vel: Vector3 = direction.normalized()
	var dash_vel: Vector3 = look_direction.normalized()
	print("dashing! input: " + str(dash_vel))
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

func on_ability_shoot():
	weapon.ability_shoot(head.global_position, -head.global_basis.z, velocity)
	
func on_heal(state: bool) -> void:
	is_healing = state
		
