extends Node3D

@onready var scn_oneshot_sfx: PackedScene = preload("res://Main/Utility/AudioManager/audio_stream_player_oneshot.tscn")

var sound_effects: Dictionary = { }
var oneshot_sound_effects: Dictionary = { } # TWO dictionaries

func _ready() -> void:
	pass
	

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("debug_play_effect"):
		#play_sfx("player", "effect_player_gets_damaged") 


func play_sfx(name: String):
	#print("audio_manager.gd - receiving sound: " + category + ", " + name)
	
	if name in sound_effects:
		var sound_effect = sound_effects[name]
		#print("doing: " + str(sound_effect))
		
		#if sound_effect is AudioStreamPlayer3D:
			#print("Global position:", sound_effect.global_transform.origin)
			#print("Stream assigned:", sound_effect.stream)
		sound_effect.play()
	elif name in oneshot_sound_effects:
		play_sfx_oneshot(name)
	else:
		print("audio_manager.gd - this sound effect doesnt exist to start: " + name)

func stop_sfx(name: String):
	if name in sound_effects:
		var sound_effect = sound_effects[name]
		sound_effect.stop()
	#elif name in oneshot_sound_effects:
		#play_sfx_oneshot(name)
	else:
		print("audio_manager.gd - this sound effect doesnt exist to stop: " + name)

func play_sfx_oneshot(name: String):
	if name not in sound_effects:
		print("audio_manager.gd - this ONESHOT sound effect does not exist: " + name)
	
	# this is assuming the dictionary holds the sound effect resource itself, not the node like the other ones use
	var oneshot_sound_effect = scn_oneshot_sfx.instantiate().initialize(oneshot_sound_effects[name])
	get_tree().root.add_child(oneshot_sound_effect)
	# it is set to autoplay so we don't need to do oneshot_sound_effect.play()
