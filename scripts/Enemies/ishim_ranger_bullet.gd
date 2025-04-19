extends BulletBase

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 0
var vertical_velocity: Vector3 = Vector3.ZERO

func initialize(initial_velocity, init_direction, init_gravity):
	velocity = initial_velocity
	velocity.y = velocity.y * -1
	direction = init_direction
	gravity = init_gravity

func _physics_process(delta: float) -> void:
	#print("speed: " + str(bullet_speed) + ", pos: " + str(self.global_position))
	self.position += velocity * delta
	velocity.y += gravity * delta
	#print("vely: " + str(velocity.y))
	
	
	#if spin:
		#self.rotate_x(x_spin_speed * delta)
		#self.rotate_y(y_spin_speed * delta)
		#self.rotate_z(z_spin_speed * delta)
		#
	## check bounds
	#if abs(self.global_position) > spawn_location + Vector3(despawn_distance, despawn_distance, despawn_distance):
		#self.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	#print("entered area %s" % area)
	return
	if area.damage:
		var di = DamageInstance.new({
			"damage" : bullet_damage,
			"velocity" : velocity,
			"creator_position" : Vector3.ZERO
		})
		if area.damage(di):
			damaged_enemy.emit()
	self.queue_free()
