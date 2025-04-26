class_name Hitbox extends Area3D

#@export var shape: Shape3D

@export var health_component: Node

@export var has_health: bool = true

signal damaged(di: DamageInstance)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#$CollisionShape3D.shape = shape


func damage(di: DamageInstance) -> bool:
	if not health_component and has_health:
		health_component = get_parent().get_node("HealthComponent")
	if health_component:
		health_component.damage(di.damage)
	damaged.emit(di)
	return true
