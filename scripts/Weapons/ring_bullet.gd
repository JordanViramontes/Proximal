extends GravityProjectile

@export var bullet_damage: float
@export var rotation_rate: float = 5.0
@export var explosion: PackedScene
signal damaged_enemy

@onready var mesh: MeshInstance3D = $MeshInstance3D

var facing_axis: Vector3

func _ready():
	super()
	$Hitbox.damaged.connect(_on_hitbox_damaged)

func _physics_process(delta: float):
	super(delta)
	
	# TODO: inherit player's velocity when using rings
	mesh.rotate(facing_axis.cross(Vector3.UP).normalized(), -rotation_rate * delta)


func _on_hitbox_damaged(amount: float):
	self.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	var e = explosion.instantiate()
	e.position = position
	World.world.add_child(e)
	self.queue_free()


func _on_hitbox_body_entered(body: Node3D) -> void:
	var e = explosion.instantiate()
	e.position = position
	World.world.add_child(e)
	self.queue_free()
