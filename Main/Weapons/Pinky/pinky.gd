extends WeaponBase
class_name WeaponPinky

# pinky is hitscan, the hit detection will not be done with a hitscan script and not bullet.gd

@export var bullet_range: float = 1000.0 # long range! make this higher if you need it should be very high
@export var shoot_height_offset: float
@export var ability_bullet: PackedScene
@export var amp_damage: float = 50 # dmg-amp during sniper ability
signal timer_reset

var is_scoped: bool = false
var can_escape_ability:bool = true


func _ready() -> void:
	super._ready()
	on_shoot.connect(on_on_shoot)
	on_ability_shoot.connect(on_on_ability_shoot)

func _process(delta: float) -> void:
	if is_scoped && can_escape_ability:
		if Input.is_action_just_pressed("shoot"):
			stop_ability()
	
	# logic so we cant cancel scope
	if not can_escape_ability:
		if Input.is_action_just_released("shoot"):
			can_escape_ability = true
			can_shoot = true

func on_on_shoot(from_position: Vector3, look_direction: Vector3, velocity: Vector3):
	if bullet == null:
		print("pinky.gd - set my bullet property bro! i dont have it!")
		
	var b = bullet.instantiate()
	if b == null: # just in case
		print("pinky.gd - bullet did not instantiate")
		return
	
	b.position = from_position
	b.tracer_origin = bullet_emerge_point.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_damage = bullet_damage * (1 + level * 0.05)
	b.distance = bullet_range
	b.direction = look_direction
	
	World.world.add_child(b)

func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if is_scoped:
		return  # already scoped

	can_escape_ability = Input.is_action_just_pressed("shoot") == false
	can_shoot = false

	# Start slow motion
	Util.zoom_in.emit()
	Util.sniper_visual.emit(true)
	Engine.time_scale = 0.3
	bullet_damage = bullet_damage * (1 + level * 0.5) + amp_damage
	is_scoped = true
	if can_escape_ability:
		can_shoot = true

#func on_on_ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	#if Input.is_action_pressed("shoot"):
		#can_escape_ability = false
		##can_shoot = true
		##return
	#
	#can_shoot = false
	## Start slow motion
	#Util.zoom_in.emit()
	#Util.sniper_visual.emit(true)
	#print(Util.sniper_visual.get_connections())
	#Engine.time_scale = 0.3  # 30% of normal speed
	#bullet_damage = bullet_damage*(1 + level*0.5) + amp_damage
	#is_scoped = true
	#
	#if can_escape_ability:
		#can_shoot = true

func stop_ability() -> void:
	# Restore normal zoom
	Util.sniper_visual.emit(false)
	Engine.time_scale = 1.0
	Util.zoom_out.emit()
	bullet_damage = (bullet_damage - amp_damage) / (1 + level * 0.5)
	is_scoped = false
	can_shoot = true
	# reset flag
	#can_escape_ability = true
	
