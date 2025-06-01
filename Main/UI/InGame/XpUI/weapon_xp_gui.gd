extends VBoxContainer

# variables
var y_minimized = 17
var y_active = 29

# components
@onready var thumb = $Thumb
@onready var index = $Index
@onready var middle = $Middle
@onready var ring = $Ring
@onready var pinky = $Pinky
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")

@onready var weapons: Array[Control]

func _ready() -> void:
	if OptionsRuntime.inverted_scroll:
		weapons = [
			pinky,
			ring,
			middle,
			index,
			thumb,
		]
		pinky.initialize(0)
		ring.initialize(1)
		middle.initialize(2)
		index.initialize(3)
		thumb.initialize(4)
	else:
		weapons = [
			thumb,
			index,
			middle,
			ring,
			pinky,
		]
		thumb.initialize(0)
		index.initialize(1)
		middle.initialize(2)
		ring.initialize(3)
		pinky.initialize(4)
	
	
	weapon_manager.update_weapon_gui.connect(thumb._on_set_active)
	weapon_manager.update_weapon_gui.connect(index._on_set_active)
	weapon_manager.update_weapon_gui.connect(middle._on_set_active)
	weapon_manager.update_weapon_gui.connect(ring._on_set_active)
	weapon_manager.update_weapon_gui.connect(pinky._on_set_active)
	weapon_manager.update_weapon_gui.connect(self._update)
	
	# signal to ourselves
	weapon_manager.update_weapon_gui.emit(1)

func _update(weapon: int) -> void:
	for i in range(weapons.size()):
		if i == weapon:
			weapons[i].custom_minimum_size.y = y_active
		else:
			weapons[i].custom_minimum_size.y = y_minimized
	
	self.queue_redraw()
