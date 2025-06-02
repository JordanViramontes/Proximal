extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@export var lifetime: float = 0.2
@export var expand_max_radius: float = 6.0

var explosion_damage: float
@export var type: DamageInstance.DamageType

signal damaged_enemy

func _ready():
	var lifetime_tween = get_tree().create_tween()
	lifetime_tween.set_parallel(true)
	lifetime_tween.tween_property(mesh.mesh.material, "albedo_color:a", 0.0, lifetime)
	lifetime_tween.tween_property(mesh.mesh, "radius", expand_max_radius, lifetime)
	lifetime_tween.tween_property(mesh.mesh, "height", expand_max_radius*2, lifetime)
	lifetime_tween.finished.connect(on_lifetime_tween_finished)

func on_lifetime_tween_finished():
	self.queue_free()

func _on_hitbox_area_entered(area: Area3D):
	if area is Hitbox:
		if area.damage:
			var di = DamageInstance.new({ # haha directional input!!! no. not funny.
				"damage" : explosion_damage,
				"type" : type
			})
			
			#print("ring_terrain_explosion - WOW CHECK: " + str(di.type))
			
			if area.damage(di):
				damaged_enemy.emit(di.damage)

func _on_hitbox_body_entered(body: Node3D):
	pass
