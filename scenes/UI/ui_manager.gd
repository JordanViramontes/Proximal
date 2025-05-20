extends Control

@onready var player: Player = get_tree().get_first_node_in_group("Player")
var player_ui_manager: Node

signal manager_ready

func _ready():	
	player_ui_manager = player.get_node("PlayerUIManager")
	
	manager_ready.emit()
