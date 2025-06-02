extends WeaponBase

@export var pellet_count: int = 3
@export var pellet_spread: float = 0.1
@export var ability_bullet: PackedScene
@export var base_force: float = 12

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)

func _process(delta: float) -> void:
	#print("ability cooldown: " + str(current_ability_cooldown))
	pass

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("thumb.gd - set my bullet property bro! i dont have it!")
	
	# Number of pellets increase as level increases
	for i in range(pellet_count+level):
		var b = bullet.instantiate()
		if b == null: # just in case
			print("thumb.gd - bullet did not instantiate")
			return
		
		b.position = self.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
		b.bullet_speed = bullet_speed
		b.bullet_damage = bullet_damage
		
		World.world.add_child(b)
		b.direction = permute_vector_weighted(look_direction, pellet_spread, 0.4)
	

# pulls vectors inwards to achieve a tighter spread with similar randomness
func permute_vector_weighted(v: Vector3, spread: float, weight: float):
	var v_unweighted = Util.permute_vector(v, spread)
	return v_unweighted * weight

func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	print("on-on-onability shoot called with %s, %s, %s" % [from_pos, look_direction, velocity])
	if ability_bullet == null:
		print("thumb.gd - set my ability bullet property bro! i dont have it!")
		return
		
	var b = ability_bullet.instantiate()
	if b == null:
		print("thumb.gd - ability bullet did not instantiate")
		return
	
	b.position = self.global_position
	b.face_dir = look_direction
	World.world.add_child(b)

	await get_tree().create_timer(0.1).timeout
	
	# 🧲 Define a **fixed vacuum point** in front of the bullet
	var vacuum_target_pos = b.global_position + b.face_dir.normalized() * 2.0
	
	# Pull enemies toward that point, stop once they're close
	for enemy in b.enemyHit:
		var to_vacuum_point = vacuum_target_pos - enemy.global_position
		var direction = to_vacuum_point.normalized()
		var strength = base_force
		enemy.apply_vacuum_force(direction, strength, vacuum_target_pos)
