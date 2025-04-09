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

@export var WALKING_SPEED = 20.0
@export var CROUCH_SPEED = 3.0
@export var JUMP_VELOCITY = 4.5

@export var accel_speed = 10.0
var direction = Vector3.ZERO

# jumping
var double_jumpable := false

# h
const height = 1.8
@export var DEATH_HEIGHT = -200.0

# leaning
@export var LEAN_MULT = 0.066
@export var LEAN_SMOOTH = 10.0
@export var LEAN_AMOUNT = 0.7 
var current_strafe_dir = 0

# nodes
@onready var head := $Head
@onready var camera := $Head/Camera3D
@onready var weapon := $Head/Weapon_Manager

# inputs
func _input(event: InputEvent) -> void:
	# input state 
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if current_state == INPUT_STATE.normal:
				rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
				head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-75), deg_to_rad(80))

# frame by frame
func _process(delta: float):
	head.rotation.z = lerp(head.rotation.z, current_strafe_dir * LEAN_MULT, delta * LEAN_SMOOTH) # this causes some weirdness when you look down/up, working on a fix

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
		

		var input_dir := Input.get_vector("left", "right", "forward", "back")
		
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
			velocity.x = direction.x * cur_speed
			velocity.z = direction.z * cur_speed
		else:
			velocity.x = move_toward(velocity.x, 0, cur_speed)
			#head.rotate_object_local()
			velocity.z = move_toward(velocity.z, 0, cur_speed)
		
		# shooting
		if Input.is_action_pressed("shoot"):
			weapon.shoot()

	move_and_slide()

# you dead
func die():
	current_state = INPUT_STATE.dead
