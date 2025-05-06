extends WeaponBase

@export var bullet_spread: float = 0.03
@export var shoot_velocity_inherit_damping: float = 0.1
@export var bullet_velocity_damping: float = 0.01
@export var bullet_gravity: float = -10
@export var ability_bullet: PackedScene

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.facing_axis = look_direction
	b.initial_velocity = velocity * shoot_velocity_inherit_damping
	b.speed = bullet_speed
	b.bullet_damage = bullet_damage
	b.initial_direction = (look_direction + Vector3.UP).normalized()
	b.horizontal_damping = bullet_velocity_damping
	b.gravity = bullet_gravity
	b.damaged_enemy.connect(on_bullet_hit)
	
	World.world.add_child(b)
	
#shooting healing bullet
func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if ability_bullet == null:
		print("index.gd - set my bullet property bro! i dont have it!")
		
	var b = ability_bullet.instantiate()
	if b == null: # just in case
		print("index.gd - bullet did not instantiate")
		return
	
	b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_speed = bullet_speed
	b.bullet_damage = bullet_damage
	
	World.world.add_child(b)
	
	# add small permutation to firing direction
	b.direction = Util.permute_vector(look_direction, bullet_spread)

func on_bullet_hit(damage: float):
	experience += 1.0*(4-level)
	print("my bullet hit an enemy >:)")
	print(experience)
	if experience >= 10.0*(level):
		level += 1
		print("LEVEL UP! ", level)
