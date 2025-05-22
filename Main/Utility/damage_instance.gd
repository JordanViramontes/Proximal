class_name DamageInstance

var damage: float
var creator_position: Vector3
var velocity: Vector3
enum DamageType {None, Thumb, Index, Middle, Ring, Pinky}
var type: DamageType

func _init(params: Dictionary):
	damage = params.damage if "damage" in params else 0
	creator_position = params.creator_position if "creator_position" in params else Vector3.ZERO
	velocity = params.velocity if "velocity" in params else Vector3.ZERO
	type = params.type if "type" in params else DamageType.None
