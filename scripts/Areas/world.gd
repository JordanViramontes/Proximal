class_name World extends Node3D

static var world

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = self
	var playerArr = get_tree().get_nodes_in_group("Player")
	if playerArr.size() > 0:
		playerArr[0].die.connect(on_player_die)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#var fps = Engine.get_frames_per_second()  
	#print("fps: " + str(fps))


func on_player_die():
	$UI/DeathInterface.activate(3)
	var reset_timer = get_tree().create_timer(3)
	reset_timer.timeout.connect(func(): get_tree().reload_current_scene())
