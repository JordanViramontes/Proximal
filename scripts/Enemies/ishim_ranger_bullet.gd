extends BulletBase

func _physics_process(delta: float) -> void:
	self.position += direction * bullet_speed * delta
	#if spin:
		#self.rotate_x(x_spin_speed * delta)
		#self.rotate_y(y_spin_speed * delta)
		#self.rotate_z(z_spin_speed * delta)
		#
	## check bounds
	#if abs(self.global_position) > spawn_location + Vector3(despawn_distance, despawn_distance, despawn_distance):
		#self.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	print("entered area %s" % area)
	if area.damage:
		if area.damage(bullet_damage):
			damaged_enemy.emit()
	self.queue_free()
