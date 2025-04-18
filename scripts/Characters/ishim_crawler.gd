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
				velocity = Vector3.ZERO
			else:
				velocity -= friction_force
		
		# gravity
		if not is_on_floor():
			velocity += get_gravity() * delta
	
	# finally move
	move_and_slide()

func _on_pathfind_timer_timeout() -> void:
	#super._on_pathfind_timer_timeout()
	player_position = player.global_position
	
	# the t value for the equation is the same as the pathfind timer,
	# AKA every time the pathfinder timer is called, the enemy should reach the intended spot
	# using kinematics,
	
	var d = global_position.distance_to(player_position)
	if d > lunge_dist: # floor the distance to lung_dist if player is too far
		d = lunge_dist
	var t = pathfind_timer.wait_time
	var init_v = (d + (1/2 * friction * t*t)) / t # kinematics
	var direction = player_position - global_position
	direction.y = 0 # remove y element
	direction = direction.normalized() # normalize
	
	# velocity for this cycle
	velocity = direction * init_v * velocity_offset
