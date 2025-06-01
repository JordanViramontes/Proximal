extends Control

@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var death_interface: Control = $DeathInterface
@onready var next_wave_starting: Label = $SingleElements/NextWaveStartingIn
var player_ui_manager: Node


signal manager_ready

func _ready():	
	player_ui_manager = player.get_node("PlayerUIManager")
	
	manager_ready.emit()
	
	# set signals
	death_interface.death_ui_active.connect(next_wave_starting._on_dying_ui)
