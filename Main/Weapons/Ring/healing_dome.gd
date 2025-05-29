extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@export var lifetime: float = 0.2
@export var expand_time: float = 0.5
@export var expand_max_radius: float = 6.0

func _ready():
	var lifetime_tween = get_tree().create_tween()
	lifetime_tween.set_parallel(true)
	lifetime_tween.tween_property(mesh.mesh, "radius", expand_max_radius, expand_time)
	lifetime_tween.tween_property(mesh.mesh, "height", expand_max_radius*2, expand_time)
	await lifetime_tween.finished
	var lifetime2_tween = get_tree().create_tween()
	lifetime2_tween.tween_property(mesh.mesh.material, "albedo_color:a", 0.0, lifetime)
	lifetime2_tween.finished.connect(on_lifetime_tween_finished)

func on_lifetime_tween_finished():
	self.queue_free()

func _on_hitbox_area_entered(area: Area3D):
	pass

func _on_hitbox_body_entered(body: Node3D):
	if body is Player:
		#print("healing")
		Util.healing.emit(true)

func _on_hitbox_body_exited(body: Node3D) -> void:
	if body is Player:
		#print("stop healing")
		Util.healing.emit(false)
