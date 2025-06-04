class_name World extends Node3D

static var world
var timer_off: bool = false
var reset_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = self
	var playerArr = get_tree().get_nodes_in_group("Player")
	if playerArr.size() > 0:
		playerArr[0].die.connect(on_player_die)
	
	# volume level
	AudioServer.set_bus_volume_db(0, 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hotkey_index"):
		print("playing")
		var audio = AudioStreamPlayer.new()
		audio.stream = load("res://assets/Sounds/Sound Effects/Player/jumping.wav")
		add_child(audio)
		audio.play()
	
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
