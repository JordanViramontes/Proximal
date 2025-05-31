extends HBoxContainer

# components
@onready var rings = $RingCount
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")

func _ready() -> void:
	# set up signals
	weapon_manager.update_ring.connect(self._on_update_rings)
	
	# set text
	rings.text = "3"

func _on_update_rings(ring_count: int):
	print("got signals: " + str(ring_count))
	rings.text = str(ring_count)
