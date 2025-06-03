extends Node

#region sound effects

# sub dictionaries
#region player effects
@onready var effect_player: Dictionary = {
	"effect_player_dies": $Effects/Player/PlayerDies,
	"effect_player_gets_damaged": $Effects/Player/PlayerGetsDamaged,
}
#endregion

#region weapon effects
@onready var effect_weapon: Dictionary = {
	"effect_weapon_level_up": $Effects/Weapon/WeaponLevelUp,
	"effect_weapon_shoot": $Effects/Weapon/WeaponShoot,
	"effect_weapon_xp_earned": $Effects/Weapon/WeaponXpEarned,
}
#endregion

#region enemy effects
@onready var effect_enemy: Dictionary = {
	"effect_enemy_dies": $Effects/Enemy/EnemyDies,
}
#@onready var effect_enemy_dies = $Effects/EnemyDies
#endregion

# main dictionary
@onready var sound_effects: Dictionary = {
	"player":effect_player,
	"weapon":effect_weapon,
	"enemy":effect_enemy,
}

#endregion

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_play_effect"):
		play_sfx("player", "effect_player_gets_damaged") 


func play_sfx(category: String, name: String):
	if category not in sound_effects:
		print("audio_manager.gd - this sound effect CATEGORY doesnt exist: " + category)
	
	if name not in sound_effects[category]:
		print("audio_manager.gd - this sound effect doesnt exist: " + name + ", in category: " + category)
	
	var sound_effect = sound_effects[category][name]
	
	#print("audio_manager.gd - sounding: " + str(sound_effect)) 
	sound_effect.play()
