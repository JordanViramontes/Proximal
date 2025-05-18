extends WeaponBase

# middle is hitscan, the hit detection will not be done with a hitscan script and not bullet.gd

@export var bullet_range: float = 1000.0 # long range! make this higher if you need it should be very high
@export var shoot_height_offset: float
var shadow: bool = false
var current_bullet: HitscanBullet

@export var shield_duration: float

func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ceasefire.connect(on_on_ceasefire)
	used_ability.connect(on_used_ability)

func on_on_shoot(from_position: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("middle.gd - set my bullet property bro! i dont have it!")
		
		
	if !shadow:
		var b = bullet.instantiate()
		if b == null: # just in case
			print("middle.gd - bullet did not instantiate")
			return
		current_bullet = b
		
	current_bullet.position = to_local(from_position)
	current_bullet.tracer_origin = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	current_bullet.bullet_damage = bullet_damage*(level)
	current_bullet.distance = bullet_range
	current_bullet.direction = look_direction
	#current_bullet.damaged_enemy.connect(on_bullet_hit)
	
	if !shadow:
		#World.world.add_child(current_bullet)
		add_child(current_bullet)
		shadow = true
	current_bullet.tracer_func()
	
func on_on_ceasefire():
	if current_bullet:
		current_bullet.fade()
		current_bullet = null
		shadow = false
	
func player_pos():
	Util.get_play_pos()
	pass

func on_bullet_hit(damage: float):
	experience += 0.02*(4-level)
	print("my bullet hit an enemy")
	print(experience)
	if experience >= 10.0*(level):
		level += 1
		print("LEVEL UP! ", level)

# this function is always called if the ability is not on cooldown
func on_used_ability():
	Util.toggle_shield.emit(true)
	await get_tree().create_timer(shield_duration).timeout
	Util.toggle_shield.emit(false)
