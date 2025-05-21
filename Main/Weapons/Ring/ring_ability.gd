extends BulletBase

@export var rotation_rate: float = 5.0
@export var terrain_explosion: PackedScene

var facing_axis: Vector3

func _physics_process(delta: float):
	print(direction)
	super(delta)
	
	# TODO: inherit player's velocity when using rings
	# rotate mesh in direction we spawned in from ,. . 
	mesh.rotate(facing_axis.cross(Vector3.UP).normalized(), -rotation_rate * delta)

func _on_hitbox_body_entered(body: Node3D) -> void:
	# hitting terrain
	var e = terrain_explosion.instantiate()
	e.position = position
	World.world.add_child(e)
	self.queue_free()
