class_name GravityProjectile extends Node3D

@onready var speed: float # initial velocity :)
@onready var direction_i: Vector3

@export var gravity: float = -9.8
@export var horizontal_damping: float = 0.0

var velocity: Vector3

# i love kinematic equations!

func _ready():
	velocity = direction_i * speed

func _physics_process(delta: float):
	velocity = Vector3(velocity.x - velocity.x * horizontal_damping, velocity.y + gravity * delta, velocity.z - velocity.z * horizontal_damping)
	position += velocity * delta
