extends Node3D
class_name WeaponBase

# shoots projectiles with a travel time
var shoot_cooldown: float = 0.05 # seconds
@export var fire_rate: float = 2 # shots per second
@onready var shoot_timer: Timer = $ShootCooldown
var can_shoot: bool = true
@export var active = false

@export var bullet: PackedScene
@export var bullet_damage: float
@export var bullet_speed: float

@export var is_hitscan: bool

# reference to manager
@onready var weapon_manager = $".."
signal on_shoot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shoot_timer.wait_time = 1/fire_rate
	shoot_timer.timeout.connect(func(): can_shoot = true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# shoot a bullet from the weapon
func shoot(from_pos: Vector3, direction: Vector3) -> void:
	if not can_shoot or not weapon_manager.isCanUseWeapon():
		return
	
	
	# doing bullet stuff in inheritors instead :3
	
	#var b = bullet.instantiate()
	#if b == null: # just in case
		#print("weapon_base.gd - bullet did not instantiate")
		#return
	#
	#b.position = $BulletEmergePoint.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	#b.bullet_speed = bullet_speed
	#b.bullet_damage = bullet_damage
	#
	#World.world.add_child(b)
	##var look_direction = $"../Head/Camera3D/LookDirection".global_position - $"../Head/Camera3D".global_position
	#var look_direction = ($BulletEmergePoint.global_position - global_position).normalized()
	#b.direction = look_direction
	#shoot_timer.start()
	#can_shoot = false
	
	shoot_timer.start()
	can_shoot = false
	#var look_direction = ($BulletEmergePoint.global_position - global_position).normalized()# there's zefinitely a better way to get the look direction
	if on_shoot != null: on_shoot.emit(from_pos, direction) 
	else: print("hello from weapon_base! you probably forgot to set the on_shoot signal on the inheritor of this script :3")
