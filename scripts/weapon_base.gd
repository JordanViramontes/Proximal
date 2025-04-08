extends Node3D

# shoots projectiles with a travel time

var shoot_cooldown: float = 0.05 # seconds
@onready var shoot_timer: Timer = $ShootCooldown
var can_shoot: bool = true

@export var bullet: PackedScene
@export var bullet_damage: float
@export var bullet_speed: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.timeout.connect(func(): can_shoot = true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# shoot a bullet from the weapon
func shoot() -> void:
	if not can_shoot:
		return
	var b = bullet.instantiate()
	b.position = $Help.global_position # is one meter ahead of the player, which lines up with the barrel of the weapon
	b.bullet_speed = bullet_speed
	b.bullet_damage = bullet_damage
	
	World.world.add_child(b)
	#var look_direction = $"../Head/Camera3D/LookDirection".global_position - $"../Head/Camera3D".global_position
	var look_direction = ($Help.global_position - global_position).normalized()
	b.direction = look_direction
	shoot_timer.start()
	can_shoot = false
