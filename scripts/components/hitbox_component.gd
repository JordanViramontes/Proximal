class_name Hitbox extends Area3D

@export var shape: Shape3D

@export var health_component: Node

@export var has_health: bool = true

signal damaged(amount: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CollisionShape3D.shape = shape


func damage(amount: float) -> bool:
	if not health_component and has_health:
		health_component = get_parent().get_node("HealthComponent")
	if health_component:
		health_component.damage(amount)
	damaged.emit(amount)
	return true
