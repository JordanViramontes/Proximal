extends Node3D

var bullet_damage: float = 2.5
var bullet_speed: float = 10.0

var direction: Vector3 = Vector3.ZERO

var spawn_location: Vector3
var despawn_distance: float = 50.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_location = self.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	self.position += direction * bullet_speed * delta
	# check bounds
	if abs(self.global_position) > spawn_location + Vector3(despawn_distance, despawn_distance, despawn_distance):
		self.queue_free()


func _on_hitbox_area_entered(area: Area3D) -> void:
	#print("entered area %s" % area)
	if area.damage:
		area.damage(bullet_damage)
	self.queue_free()


func _on_hitbox_body_entered(body: Node3D) -> void:
	#print("entered body %s" % body)
	self.queue_free()
