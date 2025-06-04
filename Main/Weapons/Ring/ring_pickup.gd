class_name RingPickup extends Node3D

@export var rotation_rate := 30
@export var magnet_speed := 1.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
var target_node: Node3D

var velocity: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	# animate the ring spinnin
	mesh.rotate_x(deg_to_rad(rotation_rate * 0.2) * delta)
	mesh.rotate_y(deg_to_rad(rotation_rate) * delta)
	mesh.rotate_z(deg_to_rad(rotation_rate * 0.4) * delta)

func _physics_process(delta: float) -> void:
	if target_node:
		self.velocity = self.position.direction_to(target_node.global_position) * magnet_speed
	else:
		self.velocity = Vector3.ZERO
	
	self.position += self.velocity


func _on_magnet_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		target_node = body


func _on_magnet_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		target_node = null
