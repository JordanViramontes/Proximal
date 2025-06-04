extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@export var lifetime: float = 0.4
var face_dir: Vector3

var explosion_damage: float
@export var type: DamageInstance.DamageType

signal damaged_enemy

@export_group("Damage Type Materials")
@export var thumb_dt_mat: StandardMaterial3D
@export var index_dt_mat: StandardMaterial3D
@export var middle_dt_mat: StandardMaterial3D
@export var pinky_dt_mat: StandardMaterial3D

func _ready():
	
	# real
	match type:
		DamageInstance.DamageType.Thumb: 
			mesh.set_surface_override_material(0, thumb_dt_mat)
		DamageInstance.DamageType.Index:
			mesh.set_surface_override_material(0, index_dt_mat)
		DamageInstance.DamageType.Middle:
			mesh.set_surface_override_material(0, middle_dt_mat)
		DamageInstance.DamageType.Pinky:
			mesh.set_surface_override_material(0, pinky_dt_mat)
		_:
			print("FUCK")
	
	
	#print("MY FACE DIR: %s" % face_dir)
	self.look_at(self.position - face_dir, Vector3.UP)
	var lifetime_tween = get_tree().create_tween()
	lifetime_tween.set_parallel(true)
	var override_mat = mesh.get_surface_override_material(0)
	lifetime_tween.tween_property(override_mat, "albedo_color:a", 0.0, lifetime)
	lifetime_tween.finished.connect(on_lifetime_tween_finished)

func on_lifetime_tween_finished():
	self.queue_free()

func _on_hitbox_area_entered(area: Area3D):
	if area is Hitbox:
		if area.damage:
			var di = DamageInstance.new({ # haha directional input!!! no. not funny.
				"damage" : explosion_damage,
				"type" : DamageInstance.DamageType.Ring # override entry type with ring
			})
			
			#print("ring_shoot_explosion - WOW CHECK: " + str(di.type))
			
			if area.damage(di):
				damaged_enemy.emit(di.damage)

func _on_hitbox_body_entered(body: Node3D):
	pass
