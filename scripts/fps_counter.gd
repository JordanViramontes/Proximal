extends Label

func _process(delta: float):
	text = "fps: " + str(Engine.get_frames_per_second())
