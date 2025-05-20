extends WeaponBase

@export var bullet_spread: float = 0.03
@export var shoot_velocity_inherit_damping: float = 0.1
@export var bullet_velocity_damping: float = 0.01
@export var bullet_gravity: float = -10
@export var ability_bullet: PackedScene
var ammo_count: int
@export var max_ammo: int = 3
func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)
	ammo_count = max_ammo

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
	#if no ammo
	if ammo_count <= 0:
		print("no ammo")
		return
	else:
		ammo_count -= 1
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.facing_axis = look_direction
	b.initial_velocity = velocity * shoot_velocity_inherit_damping
	b.speed = bullet_speed
	b.bullet_damage = bullet_damage*(1 + level*0.8)
	b.initial_direction = (look_direction + Vector3.UP).normalized()
	b.horizontal_damping = bullet_velocity_damping
	b.gravity = bullet_gravity
	
	World.world.add_child(b)
	
#shooting healing bullet
func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if ability_bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
	
	#if no ammo
	if ammo_count <= 0:
		print("no ammo")
		return
	else:
		ammo_count -= 1
	
	var b = ability_bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_speed = bullet_speed
	
	# Weapon gets more powerful as level increases
	b.bullet_damage = bullet_damage*(1 + level*0.8)
	
	b.facing_axis = look_direction
	b.direction = look_direction
	
	World.world.add_child(b)
