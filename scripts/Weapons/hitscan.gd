extends Node3D

var direction: Vector3
var distance: float
var hit_point: Vector3
var bullet_damage: float

signal damaged_enemy
@export var mesh_material: StandardMaterial3D

@onready var transform_root: Node3D = $TransformRoot
@onready var mesh: MeshInstance3D = $TransformRoot/MeshInstance3D
@onready var hitbox: Area3D = $TransformRoot/MeshInstance3D/Hitbox
@onready var coll_shape: CollisionShape3D = $TransformRoot/MeshInstance3D/Hitbox/CollisionShape3D

@onready var shapecast: ShapeCast3D = $TransformRoot/ShapeCast3D
var mesh_fade_tween: Tween

var meower: bool = false

func _ready():
	# set direction of cylinder
	look_at((global_position - direction), Vector3.UP)
	
	shapecast.shape.height = distance
	shapecast.position.y -= distance/2
	
	# mateiral stuff
	mesh.mesh.material = mesh_material
	
	#mesh_fade_tween = get_tree().create_tween()
	#mesh_fade_tween.tween_property(mesh.mesh.material, "albedo_color:a", 0.0, 0.2)
	#mesh_fade_tween.finished.connect(on_finish_tweening)

func _process(delta: float):
	if !meower:
		meower = true
		var hit_dist = distance
		if shapecast.get_collision_count() > 0:
			hit_point = shapecast.get_collision_point(0)
			hit_dist = hit_point - global_position
		
		
		mesh.mesh.height = hit_dist
		
		mesh.position.y -= hit_dist/2
	pass

#func _on_hitbox_area_entered(area):
	#if area.damage:
		#if area.damage(bullet_damage):
			#damaged_enemy.emit()
	#self.queue_free()

#func _on_hitbox_body_entered(body: Node3D) -> void:
	#self.queue_free()

func on_finish_tweening():
	self.queue_free()
