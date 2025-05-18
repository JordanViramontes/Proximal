extends Control

var player: Player
var player_ui_manager: Node

signal manager_ready

func _ready():
	var ps = get_tree().get_nodes_in_group("Player")
	if not ps.is_empty():
		player = ps[0]
	
	player_ui_manager = player.get_node("PlayerUIManager")
	
	manager_ready.emit()
