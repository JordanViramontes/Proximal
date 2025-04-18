class_name DamageInstance

var damage: float
var creator_position: Vector3
enum DamageType {Thumb, Index, Middle, Ring, Pinky}
var type: DamageType

func _init(damage: float = 0.0, creator_position: Vector3 = Vector3.ZERO, type: DamageType = DamageType.Thumb):
	self.damage = damage
	self.creator_position = creator_position
	self.type = type
