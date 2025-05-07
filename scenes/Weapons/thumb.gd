extends WeaponBase

@export var pellet_count: int = 3
@export var pellet_spread: float = 0.1

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("thumb.gd - set my bullet property bro! i dont have it!")
	
	for i in range(pellet_count+level):
		var b = bullet.instantiate()
		if b == null: # just in case
			print("thumb.gd - bullet did not instantiate")
			return
		
		b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
		b.bullet_speed = bullet_speed
		b.bullet_damage = bullet_damage
		
		World.world.add_child(b)
		b.direction = permute_vector_weighted(look_direction, pellet_spread, 0.4)
	

# pulls vectors inwards to achieve a tighter spread with similar randomness
func permute_vector_weighted(v: Vector3, spread: float, weight: float):
	var v_unweighted = Util.permute_vector(v, spread)
	return v_unweighted * weight
