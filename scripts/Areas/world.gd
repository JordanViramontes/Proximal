class_name World extends Node3D

static var world

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#var fps = Engine.get_frames_per_second()  
	#print("fps: " + str(fps))
