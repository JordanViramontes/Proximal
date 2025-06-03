extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var timer: Timer = $Timer
@export var lifetime: float = 0.4
var face_dir: Vector3
var enemyHit: Array[EnemyBase]

func _ready():
	#print("MY FACE DIR: %s" % face_dir)
	self.look_at(self.position - face_dir, Vector3.UP)
	var lifetime_tween = get_tree().create_tween()
	lifetime_tween.set_parallel(true)
	lifetime_tween.tween_property(mesh.mesh.material, "albedo_color:a", 0.0, lifetime)
	#lifetime_tween.finished.connect(on_lifetime_tween_finished)s
	timer.start()

#func on_lifetime_tween_finished():
	#self.queue_free()

func _on_hitbox_area_entered(area: Area3D):
	#print("hit something")
	if area is Hitbox:
		#print("hit enemy!")
		enemyHit.append(area.get_parent())
	

func _on_hitbox_body_entered(body: Node3D):
	pass

func _on_timer_timeout() -> void:
	for i in enemyHit:
		if i:
			i._on_recieve_unstun()
	self.queue_free()
