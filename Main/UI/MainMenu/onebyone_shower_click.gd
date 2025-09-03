extends Control

var child_tween: Tween
@export var show_time := 0.5

var current_tweening_child_index: int = 0


func _gui_input(event: InputEvent):
	if (event.is_action_pressed("shoot")):
		show_next()

func _ready():
	self.reset()
	
	current_tweening_child_index = 0

func show_next():
	var children := get_children()
	if (current_tweening_child_index == children.size()):
		print("done with everything, not doing anything when show_next() is called")
		return
		
	if (child_tween and child_tween.is_running()):
		child_tween.kill()
		children[current_tweening_child_index - 1].modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		child_tween = get_tree().create_tween() # create the tween here. die
		child_tween.tween_property(children[current_tweening_child_index], "modulate", Color(1.0, 1.0, 1.0, 1.0), show_time)
		current_tweening_child_index += 1

func reset():
	if child_tween and child_tween.is_running(): child_tween.kill()
	var children := get_children()
	for i in range(len(children)):
		children[i].modulate = Color(1.0, 1.0, 1.0, 0.0)
	current_tweening_child_index = 0
