extends WeaponBase

@export var bullet_spread: float = 0.03
@export var shoot_velocity_inherit_damping: float = 0.1
@export var bullet_velocity_damping: float = 0.01
@export var bullet_gravity: float = -10
@export var ability_bullet: PackedScene

@export var max_ammo: int = 3
var ammo_count: int = max_ammo


signal used_ring

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)


func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if ammo_count <= 0:
		#print("ring.gd - carrying no rings. no firing will be occuring.")
		return
	
	if bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
		return

	var b = bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.facing_axis = look_direction
	b.initial_velocity = velocity * shoot_velocity_inherit_damping
	b.speed = bullet_speed
	b.bullet_damage = bullet_damage*(1 + level*0.8)
	b.initial_direction = (look_direction + Vector3.UP).normalized()
	b.horizontal_damping = bullet_velocity_damping
	b.gravity = bullet_gravity
	
	World.world.add_child(b)
	
	ammo_count -= 1
	used_ring.emit() # emitted so that the weapon_manager can detect and update the hand_visual for the ring count

#shooting healing bullet
func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if ammo_count <= 0:
		#print("carrying no rings. healing will not be occuring.")
		return
	
	#print("on-on-onability shoot called with %s, %s, %s" % [from_pos, look_direction, velocity])
	if ability_bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
		return
	
	
	var b = ability_bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_speed = bullet_speed
	
	# Weapon gets more powerful as level increases
	b.bullet_damage = bullet_damage*(1 + level*0.8)
	
	b.facing_axis = look_direction
	b.direction = look_direction
	
	World.world.add_child(b)
	
	ammo_count -= 1

	used_ring.emit() # emitted so that the weapon_manager can detect and update the hand_visual for the ring count

func add_ring():
	ammo_count = clamp(ammo_count + 1, 0, max_ammo)
