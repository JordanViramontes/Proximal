extends Node3D
class_name BulletBase

@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var bullet_damage: float = 2.5
@export var bullet_speed: float = 10.0
var x_spin_speed: float
var y_spin_speed: float
var z_spin_speed: float

var direction: Vector3 = Vector3.ZERO

var spawn_location: Vector3
@export var despawn_distance: float = 1000.0

@export var spin: bool = false

var type: DamageInstance.DamageType

signal damaged_enemy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_location = self.global_position
	x_spin_speed = randf_range(-2*PI, 2*PI)
	y_spin_speed = randf_range(-2*PI, 2*PI)
	z_spin_speed = randf_range(-2*PI, 2*PI)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	self.position += direction * bullet_speed * delta
	if spin:
		mesh.rotate_x(x_spin_speed * delta)
		mesh.rotate_y(y_spin_speed * delta)
		mesh.rotate_z(z_spin_speed * delta)
		
	# check bounds
	if abs(self.global_position) > spawn_location + Vector3(despawn_distance, despawn_distance, despawn_distance):
		self.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area is Hitbox:
		if area.damage:
			var di = DamageInstance.new({ # haha directional input!!! no. not funny.
				"damage" : bullet_damage,
				"creator_position" : spawn_location,
				"velocity" : to_global(direction) * bullet_speed,
				"type" : type
			})
			
			print(di.damage)
			print(bullet_damage)
			if area.damage(di):
				damaged_enemy.emit(di.damage)
		self.queue_free()

func _on_hitbox_body_entered(body: Node3D) -> void:
	self.queue_free()
