extends Node3D
class_name HitscanBullet

var direction: Vector3
var distance: float
var bullet_damage: float

signal damaged_enemy
@export var mesh_material: StandardMaterial3D
@export var tracer_fade_time: float = 0.2
@export var if_laser: bool = false

@onready var tracer_transform_origin: Node3D = $TracerTransformOrigin
@onready var tracer: MeshInstance3D = $TracerTransformOrigin/Tracer

@onready var raycast: RayCast3D = $RayCast3D
var mesh_fade_tween: Tween

var tracer_origin: Vector3 # set in creator, is just the position of the bullet_emerge_point

func _ready():
	tracer_func()
	
	if !if_laser:
		fade()

func _process(delta: float):
	pass

func on_finish_tweening():
	self.queue_free()

func fade():
	mesh_fade_tween = get_tree().create_tween()
	mesh_fade_tween.set_parallel()
	mesh_fade_tween.tween_property(tracer.mesh.material, "albedo_color:a", 0.0, tracer_fade_time)
	mesh_fade_tween.tween_property(tracer.mesh, "top_radius", 0.0, tracer_fade_time)
	mesh_fade_tween.tween_property(tracer.mesh, "bottom_radius", 0.0, tracer_fade_time)
	mesh_fade_tween.finished.connect(on_finish_tweening)

func tracer_func():
	# mesh (tracer) should come out of "gun barrel", while raycast should come out of player's "eyes"
	tracer_transform_origin.global_position = tracer_origin 
	
	raycast.target_position = raycast.to_local(global_position + direction * distance)
	
	# mateiral stuff
	tracer.mesh.material = mesh_material
	
	
	var hit_point = global_position + distance * direction
	var hit_dist = distance
	raycast.force_raycast_update() # so we can get the result in _ready() 
	# (would otherwise have to wait for next physics frame, should be fine performance-wise for this weapon only)
	if raycast.is_colliding():
		hit_point = raycast.get_collision_point()
		hit_dist = (hit_point - global_position).length()
		
		var col = raycast.get_collider()
		if col is Hitbox:
			if col.damage:
				var di = DamageInstance.new({
					"damage" : bullet_damage,
					"creator_position" : self.global_position
				})
				if col.damage(di):
					damaged_enemy.emit()
	
	tracer_transform_origin.look_at(hit_point, Vector3.UP)
	tracer.mesh.height = hit_dist

	tracer.position.z = 0 - hit_dist/2
