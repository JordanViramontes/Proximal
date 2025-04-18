extends EnemyBase

# var
@export var friction = 2
@export var lunge_dist = 10
@export var velocity_offset =  0.75 

func _ready():
	super._ready()  # calls EnemyBase's _ready()

func _process(delta: float) -> void:
	super._process(delta)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if current_state == ENEMY_STATE.roam:
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

func _on_pathfind_timer_timeout() -> void:
	# updates path including next_path_position
	super._on_pathfind_timer_timeout()
	
	if not is_on_floor():
		return
	
	# the t value for the equation is the same as the pathfind timer,
	# AKA every time the pathfinder timer is called, the enemy should reach the intended spot
	# use kinematics to find init v in reguards to the lung dist, direction is found by pathfinder
	var local_destination = next_path_position - global_position
	var t = pathfind_timer.wait_time
	var init_v = (lunge_dist + (1/2 * friction * t*t)) / t # kinematics
	var direction = local_destination.normalized()
	direction.y = 0
	
	# velocity for this cycle
	velocity = direction * init_v * velocity_offset
