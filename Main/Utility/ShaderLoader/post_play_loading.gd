extends Node3D

var main_scene_str: String = "res://Main/MainScene/main.tscn"

func _on_shader_loader_done() -> void:
	get_tree().change_scene_to_file(main_scene_str)
