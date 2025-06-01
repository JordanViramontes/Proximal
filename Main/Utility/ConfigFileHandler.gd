extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("keybinding", "forward", "W")
		config.set_value("keybinding", "back", "S")
		config.set_value("keybinding", "left", "A")
		config.set_value("keybinding", "right", "D")
		config.set_value("keybinding", "jump", "Space")
		config.set_value("keybinding", "hotkey_dash", "Shift")
		config.set_value("keybinding", "slide", "Ctrl")
		config.set_value("keybinding", "shoot", "mouse_1")
		config.set_value("keybinding", "ability", "mouse_2")
		config.set_value("keybinding", "change_weapon_up", "mouse_4")
		config.set_value("keybinding", "change_weapon_down", "mouse_5")
		config.set_value("keybinding", "hotkey_thumb", "1")
		config.set_value("keybinding", "hotkey_index", "2")
		config.set_value("keybinding", "hotkey_middle", "3")
		config.set_value("keybinding", "hotkey_ring", "4")
		config.set_value("keybinding", "hotkey_pinky", "5")
		
		config.set_value("video", "fullscreen", false)
		
		config.set_value("audio", "master_volume", 1.0)
		
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)

func save_video_setting(key: String, value):
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_video_settings():
	var video_settings = {}
	for key in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings

func save_mouse_sens_setting(key: String, value):
	config.set_value("mouse_sens", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_mouse_sens_settings():
	var found_sens: float = 11.0
	var video_settings = {}
	for key in config.get_section_keys("mouse_sens"):
		video_settings[key] = config.get_value("mouse_sens", key)
		found_sens = float(video_settings[key])
	return found_sens

func save_mouse_inverted_setting(key: String, value):
	config.set_value("mouse_inverted", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_mouse_inverted_settings():
	var found_inverted: bool = false
	var video_settings = {}
	for key in config.get_section_keys("mouse_inverted"):
		video_settings[key] = config.get_value("mouse_inverted", key)
		found_inverted = bool(video_settings[key])
	return found_inverted


func save_audio_setting(key: String, value):
	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_audio_settings():
	var audio_settings = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings

func save_keybinding(action: StringName, event: InputEvent):
	var event_str
	if event is InputEventKey:
		event_str = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		event_str = "mouse_" + str(event.button_index)
		
	config.set_value("keybinding", action, event_str)
	config.save(SETTINGS_FILE_PATH)

func load_keybindings():
	var keybindings = {}
	var keys = config.get_section_keys("keybinding")
	for key in keys:
		var input_event
		var event_str = config.get_value("keybinding", key)
		
		if event_str.contains("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(event_str.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(event_str)
			
		keybindings[key] = input_event
	return keybindings
