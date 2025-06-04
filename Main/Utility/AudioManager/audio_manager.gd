extends Node

var sound_effects: Dictionary = { }

func _ready() -> void:
	pass

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("debug_play_effect"):
		#play_sfx("player", "effect_player_gets_damaged") 


func play_sfx(name: String):
	#print("audio_manager.gd - receiving sound: " + category + ", " + name)
	
	if name not in sound_effects:
		print("audio_manager.gd - this sound effect doesnt exist: " + name)
	
	var sound_effect = sound_effects[name]
	
	#print("audio_manager.gd - sounding: " + str(sound_effect)) 
	sound_effect.play()
