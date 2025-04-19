class_name Player extends CharacterBody3D

# signals
signal player_die

# input stuff
# states
enum INPUT_STATE {normal, dead}
var current_state = INPUT_STATE.normal
@export var MOUSE_SENS = 0.3

# speed and walking
var cur_speed = 5.0

@export var WALKING_SPEED = 15.0
@export var CROUCH_SPEED = 3.0
@export var JUMP_VELOCITY = 4.5

@export var accel_speed = 10.0
var direction = Vector3.ZERO

# jumping
var double_jumpable := false

# Abilities
@export var DASH_SPEED = 40
@export var dash_accel = 5

# h
const height = 1.8
@export var DEATH_HEIGHT = -200.0

# leaning
@export var LEAN_MULT = 0.066
@export var LEAN_SMOOTH = 10.0
@export var LEAN_AMOUNT = 0.7 
var current_strafe_dir = 0

# nodes
@onready var lean_pivot := $LeanPivot
@onready var head := $LeanPivot/Head
@onready var camera := $LeanPivot/Head/Camera3D
@onready var weapon := $LeanPivot/Head/Weapon_Manager



# inputs
func _input(event: InputEvent) -> void:
	# input state 
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		if current_state == INPUT_STATE.normal:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS)) # yaw
			head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS)) # pitch
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-75), deg_to_rad(80))

# frame by frame
func _process(delta: float):
	lean_pivot.rotation.z = lerp(lean_pivot.rotation.z, current_strafe_dir * LEAN_MULT, delta * LEAN_SMOOTH) # this causes some weirdness when you look down/up, working on a fix

# frame by frame physics
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else: 
		double_jumpable = true # when you touch the ground you can double jump again
	
	if self.position.y < DEATH_HEIGHT:
		die()
	
	if current_state == INPUT_STATE.normal:
		cur_speed = WALKING_SPEED
		# jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif Input.is_action_just_pressed("jump") and not is_on_floor() and double_jumpable:
			# double jumping
			double_jumpable = false
			velocity.y = JUMP_VELOCITY
		

		var input_dir = Input.get_vector("left", "right", "forward", "back")
		
		if (input_dir.x < 0):
			current_strafe_dir = LEAN_AMOUNT
		elif (input_dir.x > 0):
			current_strafe_dir = -LEAN_AMOUNT
		else:
			current_strafe_dir = 0
		#var target_rot
		#if input_dir:
			#var val = Quaternion(camera.transform.basis)
			#var target_rot = Vector3(input_dir.normalized().y, camera.rotation.y, -input_dir.normalized().x)
			#var smooth_rot = val.slerp(target, 0.4)
			#
			#camera.transform.basis = Basis(smooth_rot)
		#else:
			#target_rot = Vector3(0, camera.rotation.y, 0).normalized()
		
		var h_rot = global_transform.basis.get_euler().y
		
		#direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
		direction = lerp(direction, Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, h_rot).normalized(), delta * accel_speed)
		
		
		
		if direction:
			# X check if we're above walking speed (dashing)
			if abs(velocity.x) <= WALKING_SPEED:
				velocity.x = direction.x * cur_speed
			elif velocity.x > 0:
				velocity.x -= dash_accel
			elif velocity.x < 0:
				velocity.x += dash_accel
			
			# Z check if we're above walking speed (dashing)
			if abs(velocity.z) <= WALKING_SPEED:
				velocity.z = direction.z * cur_speed
			elif velocity.z > 0:
				velocity.z -= dash_accel
			elif velocity.z < 0:
				velocity.z += dash_accel
		else:
			velocity.x = move_toward(velocity.x, 0, cur_speed)
			#head.rotate_object_local()
			velocity.z = move_toward(velocity.z, 0, cur_speed)
		
		# shooting
		if Input.is_action_pressed("shoot"):
			weapon.shoot(head.global_position, -head.global_basis.z, velocity) # pass player "eye" position
		if Input.is_action_just_released("shoot"):
			weapon.cease_fire()
	move_and_slide()

# you dead
func die():
	current_state = INPUT_STATE.dead

# recieve dash input from WeaponManager
func _on_weapon_manager_dash_input() -> void:
	var dash_vel: Vector3 = direction.normalized()
	print("dashing! input: " + str(dash_vel))
	velocity.x += dash_vel.x * DASH_SPEED
	velocity.z += dash_vel.z * DASH_SPEED
	#velocity.y = 0
	print("velocity: " + str(velocity))
