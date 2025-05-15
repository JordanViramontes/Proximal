extends Control

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
