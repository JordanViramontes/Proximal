extends GravityProjectile

@export var bullet_damage: float
@export var rotation_rate: float = 5.0
@export var terrain_explosion: PackedScene
@export var shoot_explosion: PackedScene
signal damaged_enemy

@onready var mesh: MeshInstance3D = $MeshInstance3D

var facing_axis: Vector3

@export var type: DamageInstance.DamageType

#region sound effects
var audio_manager: Node3D # this should not be onready
signal sound_effect_signal_start(name: String)
signal sound_effect_signal_stop(name: String)

var SE_ring_explosion: String = "enemy_dies"
@onready var sound_effects: Dictionary
#@onready var scn_oneshot_sfx: PackedScene = preload("res://Main/Utility/AudioManager/audio_stream_player_oneshot.tscn")
#endregion

func _ready():
	#region setup audio
	audio_manager = Node3D.new()
	audio_manager.set_script(load("res://Main/Utility/AudioManager/audio_manager.gd"))
	add_child(audio_manager)
	
	# oneshot
	var SE_ring_explosion_stream = load("res://assets/Sounds/Sound Effects/Weapon/Weapons/ring_explosion.mp3")
	
	# this is a dictionary of either strings -> audiostreamplayers (for non oneshot sounds) or strings -> audiostreams. 
	# you can mix n match the contents of the dict because we're using a dynamically types language :D 
	sound_effects = {
		SE_ring_explosion:SE_ring_explosion_stream,
	}
	
	for i in sound_effects.keys():
		if sound_effects[i] is AudioStreamPlayer or sound_effects[i] is AudioStreamPlayer3D: # if it's the NODE add it as the child # FIXME if the SE_..._node's type changes this will break :D
			audio_manager.add_child(sound_effects[i])
			audio_manager.sound_effects[i] = sound_effects[i] # add the element to the dict in either case
		elif sound_effects[i] is AudioStream:
			audio_manager.oneshot_sound_effects[i] = sound_effects[i]
	
	# audio signal
	self.sound_effect_signal_start.connect(audio_manager.play_sfx)
	#endregion
	
	super()
	$Hitbox.damaged.connect(_on_hitbox_damaged)

func _physics_process(delta: float):
	super(delta)
	
	# TODO: inherit player's velocity when using rings
	# rotate mesh in direction we spawned in from ,. . 
	mesh.rotate(facing_axis.cross(Vector3.UP).normalized(), -rotation_rate * delta)


func _on_hitbox_damaged(di: DamageInstance):
	# sound effect
	sound_effect_signal_start.emit(SE_ring_explosion)
	
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
	# sound effect
	sound_effect_signal_start.emit(SE_ring_explosion)
	
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
