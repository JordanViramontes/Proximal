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
	b.tracer_origin = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_damage = bullet_damage
	b.distance = bullet_range
	b.direction = look_direction
	b.damaged_enemy.connect(on_bullet_hit)
	
	World.world.add_child(b)

func on_bullet_hit(damage: float):
	experience += 0.5*(4-level)
	print("my bullet hit an enemy >:)")
	print(experience)
	if experience >= 10.0*(level):
		level += 1
		print("LEVEL UP! ", level)
