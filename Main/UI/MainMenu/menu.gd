extends Control

# preload action input button and grab action list
@onready var input_button_scene = preload("res://Main/UI/MainMenu/input_button.tscn")
@onready var action_list = $"Options Menu/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VBoxContainer"
@onready var volume = $"Options Menu/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Volume"
@onready var fullscreen_checkbox = $"Options Menu/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer2/Fullscreen_Checkbox"
@onready var scroll_checkbox = $"Options Menu/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ScrollWheel/Scroll_Checkbox"
@onready var mouse_sensitivity = $"Options Menu/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Mouse_Sensitivity/Mouse_Slider"
@onready var mouse_sensitivity_label = $"Options Menu/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Mouse_Sensitivity/Mouse_Count_Label"

var is_remapping = false
var action_to_remap = null
var remapping_button = null
@export var default_mouse_sens = 18

# input actions dictionary
var input_actions = {
	"forward": "Move Forward",
	"back": "Move Backward",
	"left": "Strafe Left",
	"right": "Strafe Right",
	"jump": "Jump",
	"hotkey_dash": "Dash",
	"slide": "Slide",
	"shoot": "Shoot",
	"ability": "Weapon Ability",
	"change_weapon_up": "Weapon Cycle Up",
	"change_weapon_down": "Weapon Cycle Down",
	"hotkey_thumb": "Thumb",
	"hotkey_index": "Index",
	"hotkey_middle": "Middle",
	"hotkey_ring": "Ring",
	"hotkey_pinky": "Pinky"
}

func _ready():
	_load_keybindings_from_settings()
	_create_action_list()
	var video_settings = ConfigFileHandler.load_video_settings()
	fullscreen_checkbox.button_pressed = video_settings.fullscreen
	
	var audio_settings = ConfigFileHandler.load_audio_settings()
	volume.value = min(audio_settings.master_volume, 1.0) * 100
	
	mouse_sensitivity.value = default_mouse_sens
	mouse_sensitivity_label.text = str(int(mouse_sensitivity.value))

# play button should send user to game scene
func _on_play_pressed():
	FadeToBlack.transition()
	await FadeToBlack.on_transition_finished
	get_tree().change_scene_to_file("res://Main/MainScene/main.tscn")

# options button should allow to change ui elements, key binds, etc.
func _on_options_pressed():
	$"Options Menu".visible = true
	
func _on_quit_pressed():
	get_tree().quit()

# audio slider function
func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)
	#print("volume set to: " + str(value))


func _on_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_setting("master_volume", volume.value / 100)


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

func _load_keybindings_from_settings():
	var keybindings = ConfigFileHandler.load_keybindings()
	for action in keybindings.keys():
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, keybindings[action])

func _create_action_list() -> void:
	# clear existing buttons
	for child in action_list.get_children():
		child.queue_free()
	
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
			ConfigFileHandler.save_keybinding(action_to_remap, event)
			_update_action_list(remapping_button, event)
			
			is_remapping = false
			action_to_remap = null
			remapping_button = null
			
			accept_event()
			
func _update_action_list(button, event):
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")


func _on_fullscreen_checkbox_toggled(toggled_on: bool) -> void:
	ConfigFileHandler.save_video_setting("fullscreen", toggled_on)
	
	if toggled_on: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		

func _on_reset_button_pressed() -> void:
	InputMap.load_from_project_settings()
	for action in input_actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			ConfigFileHandler.save_keybinding(action, events[0])
	_create_action_list()

# invert the scroll wheel lmfao
func _on_scroll_checkbox_toggled(toggled_on: bool) -> void:
	if toggled_on:
		ConfigFileHandler.save_mouse_inverted_setting("mouse_inverted", true)
	else:
		ConfigFileHandler.save_mouse_inverted_setting("mouse_inverted", false)


func _on_mouse_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_mouse_sens_setting("mouse_sens", mouse_sensitivity.value)
		mouse_sensitivity_label.text = str(int(mouse_sensitivity.value))
	#print("check sens: " + str(int(mouse_sensitivity.value)))
	


func _on_mouse_slider_value_changed(value: float) -> void:
	ConfigFileHandler.save_mouse_sens_setting("mouse_sens", mouse_sensitivity.value)
	mouse_sensitivity_label.text = str(int(mouse_sensitivity.value))
	#print("check sens: " + str(int(mouse_sensitivity.value)))
