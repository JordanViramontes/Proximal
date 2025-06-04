extends WeaponBase
class_name WeaponMiddle

# middle is hitscan, the hit detection will not be done with a hitscan script and not bullet.gd

@export var bullet_range: float = 1000.0 # long range! make this higher if you need it should be very high
@export var shoot_height_offset: float
var shadow: bool = false
var current_bullet: HitscanBullet
var isAbility: bool = false

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
	current_bullet.bullet_damage = bullet_damage * (3 * level - 1)
	current_bullet.distance = bullet_range
	current_bullet.direction = look_direction
	
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

func _process(delta: float) -> void:
	if isAbility && not sound_effects[SE_ability_middle].is_playing():
		sound_effect_signal_start.emit(SE_ability_middle)
	if not isAbility:
		sound_effect_signal_stop.emit(SE_ability_middle)

# this function is always called if the ability is not on cooldown
func on_used_ability():
	Util.toggle_shield.emit(true)
	isAbility = true
	await get_tree().create_timer(shield_duration).timeout
	Util.toggle_shield.emit(false)
	isAbility = false
