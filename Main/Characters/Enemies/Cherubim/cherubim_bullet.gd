extends BulletBase

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 0
var vertical_velocity: Vector3 = Vector3.ZERO
@onready var enemy # whatever enemy spawned this bullet

# signals
signal damage_player(di: DamageInstance)

func initialize(initial_velocity, init_direction, init_gravity, creator):
	velocity = initial_velocity
	velocity.y = velocity.y * -1
	direction = init_direction
	gravity = init_gravity
	enemy = creator
	
	# this will send a signal to enemy which will send signal to player to take damage
	damage_player.connect(creator.deal_damage_to_player)

func _physics_process(delta: float) -> void:
	#print("speed: " + str(bullet_speed) + ", pos: " + str(self.global_position))
	self.position += velocity * delta
	velocity.y += gravity * delta

func _on_hitbox_area_entered(area: Area3D) -> void:
	# check that we are in a player
	var area_owner = area.get_owner()
	if area_owner is  Player:
		var di = DamageInstance.new({
			"damage" : bullet_damage,
			#"velocity" : velocity,
			#"creator_position" : Vector3.ZERO
		})
		# assign damage isntance and deal damage from the enemy POV
		if enemy:
			enemy.deal_damage_to_player(di) # will deal damage from the enemy's pov
		else:
			area.damage(di) # in case the enemy dies before proj reaches
	
		self.queue_free()
