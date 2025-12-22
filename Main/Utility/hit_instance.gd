class_name HitInstance

var victim: Node3D
var damage_instance: DamageInstance
var true_damage_dealt: float

func _init(_victim: Node3D, _damage_instance: DamageInstance, _true_damage_dealt: float):
	victim = _victim
	damage_instance = _damage_instance
	true_damage_dealt = _true_damage_dealt
