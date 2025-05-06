extends WeaponBase

@export var bullet_spread: float = 0.03

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("index.gd - set my bullet property bro! i dont have it!")
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("index.gd - bullet did not instantiate")
		return
	
	b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_speed = bullet_speed
	b.bullet_damage = bullet_damage*(level)
	b.direction = look_direction
	b.damaged_enemy.connect(on_bullet_hit)
	b.damaged_enemy.connect(weapon_manager._on_earn_experience)
	
	World.world.add_child(b)
	
	# add small permutation to firing direction
	b.direction = Util.permute_vector(look_direction, bullet_spread)
	
	$TraumaCauser.cause_trauma_conditional(0.4)
	
func on_bullet_hit(damage: float):
	experience += 0.1*(4-level)
	print("my bullet hit an enemy >:)")
	print(experience)
	if experience >= 10.0*(level):
		level += 1
		print("LEVEL UP! ", level)
