extends Control

@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var death_interface: Control = $DeathInterface
@onready var next_wave_starting: Label = $SingleElements/NextWaveStartingIn
@onready var debug_pause_menu: Control = $DebugPauseMenu
var player_ui_manager: Node

signal manager_ready
#signal change_debug_visibility

func _ready():	
	player_ui_manager = player.get_node("PlayerUIManager")
	
	manager_ready.emit()
	
	# set signals
	death_interface.death_ui_active.connect(next_wave_starting._on_dying_ui)
	#self.change_debug_visibility.connect(debug_pause_menu._on_change_visibility)

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("debug_pause_menu"):
		#change_debug_visibility.emit()
