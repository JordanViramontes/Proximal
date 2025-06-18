extends Control

@export var timings: Array[float]
var child_tween: Tween

func _ready():
	self.reset()

func do_showing():
	var children := get_children()
	child_tween = get_tree().create_tween() # create the tween here and not in the for loop so they tween in sequence
	for i in range(len(children)):
		var show_time: float
		if len(timings) - 1 < i:
			show_time = timings[-1]
		else:
			show_time = timings[i]
		
		child_tween.tween_property(children[i], "self_modulate", Color(1.0, 1.0, 1.0, 1.0), show_time)

func reset():
	if child_tween and child_tween.is_running(): child_tween.stop()
	var children := get_children()
	for i in range(len(children)):
		children[i].self_modulate = Color(1.0, 1.0, 1.0, 0.0)
