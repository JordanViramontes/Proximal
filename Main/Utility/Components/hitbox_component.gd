class_name Hitbox extends Area3D

#@export var shape: Shape3D

@export var health_component: Node

@export var has_health: bool = true

signal damaged(di: DamageInstance)
signal drop_xp_to_weapon(weapon: DamageInstance.DamageType)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#$CollisionShape3D.shape = shape


func damage(di: DamageInstance) -> bool:
	if not health_component and has_health:
		health_component = get_parent().get_node("HealthComponent")
	if health_component:
		health_component.damage(di.damage)
		
		# we're from a weapon -> enemy
		#if di.type != DamageInstance.DamageType.None:
			#print("from: " + str(di.type))
			#drop_xp_to_weapon.emit(di.type)
			
	damaged.emit(di)
	return true
