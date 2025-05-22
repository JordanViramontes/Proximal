extends WeaponBase

# pinky is hitscan, the hit detection will not be done with a hitscan script and not bullet.gd

@export var bullet_range: float = 1000.0 # long range! make this higher if you need it should be very high
@export var shoot_height_offset: float
@export var ability_bullet: PackedScene
@export var amp_damage: float = 50 # dmg-amp during sniper ability
signal timer_reset


func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)

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
	
	World.world.add_child(b)

func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	# Start slow motion
	Util.zoom_in.emit()
	Util.sniper_visual.emit(true)
	print(Util.sniper_visual.get_connections())
	Engine.time_scale = 0.3  # 30% of normal speed
	bullet_damage = bullet_damage*(1 + level*0.5) + amp_damage
	can_shoot = true
	# Narrower FOV = zoom in
	await on_shoot
	# Restore normal zoom
	Util.sniper_visual.emit(false)
	Engine.time_scale = 1.0
	Util.zoom_out.emit()
	print("slowing")
	# Restore time later
	
	bullet_damage = (bullet_damage-amp_damage)/(1 + level*0.5)
