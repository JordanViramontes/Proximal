extends WeaponBase

# pinky is hitscan, the hit detection will not be done with a hitscan script and not bullet.gd

@export var bullet_range: float = 1000.0 # long range! make this higher if you need it should be very high
@export var shoot_height_offset: float

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)

func on_on_shoot(from_position: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("pinky.gd - set my bullet property bro! i dont have it!")
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("pinky.gd - bullet did not instantiate")
		return
	
	b.position = from_position
	b.tracer_origin = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	print(b.tracer_origin)
	b.bullet_damage = bullet_damage
	b.distance = bullet_range
	b.direction = look_direction
	
	World.world.add_child(b)
