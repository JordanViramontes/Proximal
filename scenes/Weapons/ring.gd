extends WeaponBase

@export var bullet_spread: float = 0.03
@export var shoot_velocity_inherit_damping: float = 0.1
@export var bullet_velocity_damping: float = 0.01
@export var bullet_gravity: float = -10
@export var ability_bullet: PackedScene

@export var max_carried_rings: int = 3
var carried_rings: int = max_carried_rings

signal used_ring

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)

func _process(delta: float) -> void:
	super._process(delta)
	$RingDisplay/Label.text = ("carried rings: %s" % carried_rings)

func on_on_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if carried_rings <= 0:
		print("carrying no rings. no firing will be occuring.")
		return
	
	if bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.facing_axis = look_direction
	b.initial_velocity = velocity * shoot_velocity_inherit_damping
	b.speed = bullet_speed
	b.bullet_damage = bullet_damage
	b.initial_direction = (look_direction + Vector3.UP).normalized()
	b.horizontal_damping = bullet_velocity_damping
	b.gravity = bullet_gravity
	b.damaged_enemy.connect(on_bullet_hit)
	
	World.world.add_child(b)
	
	carried_rings -= 1
	used_ring.emit() # emitted so that the weapon_manager can detect and update the hand_visual for the ring count

#shooting healing bullet
func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if carried_rings <= 0:
		print("carrying no rings. no healing will be occuring.")
		return
	
	print("on-on-onability shoot called with %s, %s, %s" % [from_pos, look_direction, velocity])
	if ability_bullet == null:
		print("ring.gd - set my bullet property bro! i dont have it!")
		
	var b = ability_bullet.instantiate()
	if b == null: # just in case
		print("ring.gd - bullet did not instantiate")
		return
	
	b.position = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_speed = bullet_speed
	b.bullet_damage = bullet_damage
	b.facing_axis = look_direction
	b.direction = look_direction
	
	World.world.add_child(b)
	
	carried_rings -= 1
	used_ring.emit() # emitted so that the weapon_manager can detect and update the hand_visual for the ring count

func on_bullet_hit(damage: float):
	experience += 1.0*(4-level)
	print("my bullet hit an enemy >:)")
	print(experience)
	if experience >= 10.0*(level):
		level += 1
		print("LEVEL UP! ", level)


func add_ring():
	carried_rings = clamp(carried_rings + 1, 0, max_carried_rings)
