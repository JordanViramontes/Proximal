class_name World extends Node3D

static var world
var timer_off: bool = false
var reset_timer: Timer

#region audio
# sound effects
@onready var audio_manager: Node3D = $AudioManager
signal sound_effect_signal_start(name: String)
signal sound_effect_signal_stop(name: String)

var MUS_ambiance: String = "ambiance"
@onready var music: Dictionary[String, AudioStreamPlayer] = {
	MUS_ambiance:$AudioManager/AudioStreamPlayer,
}
#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = self
	var playerArr = get_tree().get_nodes_in_group("Player")
	if playerArr.size() > 0:
		playerArr[0].die.connect(on_player_die)
	
	# volume level
	AudioServer.set_bus_volume_db(0, 1.0)
	
	# sound effects
	for i in music.keys():
		audio_manager.sound_effects[i] = music[i]
	self.sound_effect_signal_start.connect(audio_manager.play_sfx)
	self.sound_effect_signal_stop.connect(audio_manager.stop_sfx)
	
	sound_effect_signal_start.emit(MUS_ambiance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not music[MUS_ambiance].is_playing():
		sound_effect_signal_start.emit(MUS_ambiance)
	
	if reset_timer:
		if timer_off:
			reset_timer.paused = true
		else:
			reset_timer.paused = false
	#var fps = Engine.get_frames_per_second()  
	#print("fps: " + str(fps))

	
func on_player_die():
	$UI/DeathInterface.activate(3)
	reset_timer = Timer.new()
	add_child(reset_timer)
	reset_timer.start(3.25)
	reset_timer.timeout.connect(func(): get_tree().reload_current_scene())


func stop_timer(should_timer: bool):
	timer_off = should_timer
