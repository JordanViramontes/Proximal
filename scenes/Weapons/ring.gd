extends WeaponBase

@export var bullet_spread: float = 0.03
@export var shoot_velocity_inherit_damping: float = 0.1
@export var bullet_velocity_damping: float = 0.01
@export var bullet_gravity: float = -10

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	print("shooting ring")
	
	b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.facing_axis = look_direction
	b.initial_velocity = velocity * shoot_velocity_inherit_damping
	b.speed = bullet_speed
	b.bullet_damage = bullet_damage
	b.initial_direction = (look_direction + Vector3.UP).normalized()
	b.horizontal_damping = bullet_velocity_damping
	b.gravity = bullet_gravity
	
	World.world.add_child(b)
	
	
