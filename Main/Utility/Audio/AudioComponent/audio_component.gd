class_name AudioComponent extends Node

# component intended to be added as a child of any node that wants to play audio and things
# the parent node (or whatever is trying to play the audio) should have a reference to the audiostream it wants to play,
# and should pass it as an argument to this node's functions

@export var oneshot_audio_stream_scene: PackedScene = preload("res://Main/Utility/Audio/AudioManager/audio_stream_player_oneshot.tscn")

@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func play_oneshot_sound(audio_stream: AudioStream) -> void:
	var osp: AudioStreamPlayerOneshot = oneshot_audio_stream_scene.instantiate()
	osp.initialize(audio_stream)


func play_sound_no_oneshot(audio_stream: AudioStream) -> void:
	audio_stream_player.stream = audio_stream
	audio_stream_player.play()
