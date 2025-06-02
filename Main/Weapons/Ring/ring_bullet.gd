extends GravityProjectile

@export var bullet_damage: float
@export var rotation_rate: float = 5.0
@export var terrain_explosion: PackedScene
@export var shoot_explosion: PackedScene
signal damaged_enemy

@onready var mesh: MeshInstance3D = $MeshInstance3D

var facing_axis: Vector3

@export var type: DamageInstance.DamageType

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
	e.face_dir = (self.global_position - di.creator_position).normalized()
	
	# give the shoot explosion the damage and damage type of the damageinstance!
	e.explosion_damage = bullet_damage * di.damage
	e.type = di.type
	
	var de_connections = damaged_enemy.get_connections()
	#print(de_connections)
	for conn in de_connections:
		e.damaged_enemy.connect(conn.callable)
	
	World.world.add_child(e)
	self.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	# hitting Guys (actors/hitboxes)
	var e = terrain_explosion.instantiate()
	e.position = position
	
	e.explosion_damage = bullet_damage
	e.type = DamageInstance.DamageType.Ring
	
	var de_connections = damaged_enemy.get_connections()
	#print(de_connections)
	for conn in de_connections:
		e.damaged_enemy.connect(conn.callable)
	
	World.world.add_child(e)
	self.queue_free()


func _on_hitbox_body_entered(body: Node3D) -> void:
	# hitting terrain
	var e = terrain_explosion.instantiate()
	e.position = position
	
	e.explosion_damage = bullet_damage
	e.type = DamageInstance.DamageType.Ring
	
	var de_connections = damaged_enemy.get_connections()
	#print(de_connections)
	for conn in de_connections:
		e.damaged_enemy.connect(conn.callable)
	
	World.world.add_child(e)
	self.queue_free()
