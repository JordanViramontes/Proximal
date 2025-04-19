extends GravityProjectile

@export var bullet_damage: float
@export var rotation_rate: float = 5.0
@export var terrain_explosion: PackedScene
@export var shoot_explosion: PackedScene
signal damaged_enemy

@onready var mesh: MeshInstance3D = $MeshInstance3D

var facing_axis: Vector3

func _ready():
	super()
	$Hitbox.damaged.connect(_on_hitbox_damaged)

func _physics_process(delta: float):
	super(delta)
	
	# TODO: inherit player's velocity when using rings
	# rotate mesh in direction we spawned in from ,. . 
	mesh.rotate(facing_axis.cross(Vector3.UP).normalized(), -rotation_rate * delta)


func _on_hitbox_damaged(di: DamageInstance):
	# getting hit by a bullet!
	var e = shoot_explosion.instantiate()
	e.position = position
	e.face_dir = -di.velocity.normalized()
	World.world.add_child(e)
	self.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	# hitting Guys (actors/hitboxes)
	var e = terrain_explosion.instantiate()
	e.position = position
	World.world.add_child(e)
	self.queue_free()


func _on_hitbox_body_entered(body: Node3D) -> void:
	# hitting terrain
	var e = terrain_explosion.instantiate()
	e.position = position
	World.world.add_child(e)
	self.queue_free()
