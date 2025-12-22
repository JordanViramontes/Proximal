extends Node3D

@export var rotation_rate := 30.0
var initial_position: Vector3

var oneshot_audio: PackedScene = preload("res://Main/Utility/Audio/AudioManager/audio_stream_player_oneshot.tscn") # ah
var pickup_sound: AudioStream = preload("res://assets/Sounds/Sound Effects/Misc/hand_pickup.wav")

signal collected # should be listened for by the world to start the game

func _ready() -> void:
	initial_position = position


func _process(delta: float) -> void:
	rotate_x(deg_to_rad(rotation_rate * 0.1) * delta)
	rotate_y(deg_to_rad(rotation_rate) * delta)
	rotate_z(deg_to_rad(rotation_rate * 0.2) * delta)
	
	position.y = initial_position.y + 0.25 * sin(Time.get_ticks_msec() / 1000.0)


func collect():
	collected.emit() # hopefully the World is listening for this
	var osa = oneshot_audio.instantiate()
	osa.initialize(pickup_sound)
	get_parent().add_child(osa)
	self.queue_free()


func _on_area_3d_area_entered(area: Area3D) -> void:
	collect()
