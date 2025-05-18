extends Control

# preload action input button and grab action list
@onready var input_button_scene = preload("res://input_button.tscn")
@onready var action_list = $"Options Menu/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer"

var is_remapping = false
var action_to_remap = null
var remapping_button = null

# input actions dictionary
var input_actions = {
	"forward": "Move Forward",
	"back": "Move Backward",
	"left": "Strafe Left",
	"right": "Strafe Right",
	"jump": "Jump",
	"shoot": "Shoot"
}

func _ready():
	_create_action_list()

# play button should send user to game scene
func _on_play_pressed():
	FadeToBlack.transition()
	await FadeToBlack.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# options button should allow to change ui elements, key binds, etc.
func _on_options_pressed():
	$"Options Menu".visible = true
	
func _on_quit_pressed():
	get_tree().quit()

# audio slider function
func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)
	print("volume set to: " + str(value))

# resolution setting
func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600, 900))
		2:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		3:
			DisplayServer.window_set_size(Vector2i(1024, 576))
		4:
			DisplayServer.window_set_size(Vector2i(640, 360))
		5:
			DisplayServer.window_set_size(Vector2i(256, 144))

func _on_options_exit_pressed() -> void:
	$"Options Menu".visible = false

func _create_action_list() -> void:
	InputMap.load_from_project_settings()
		
	for action in input_actions:
		var button = input_button_scene.instantiate()
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
			
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))
		
func _on_input_button_pressed(button, action):
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."
		
func _input(event):
	if is_remapping:
		if (event is InputEventKey || (event is InputEventMouseButton && event.pressed)):
			# edge case, don't accept double click as keybind
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
			
			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(remapping_button, event)
			
			is_remapping = false
			action_to_remap = null
			remapping_button = null
			
			accept_event()
			
func _update_action_list(button, event):
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")
