extends MeshInstance3D

@export var finger_list: Array[MeshInstance3D]

var current_idx: int = -1

func select_finger(idx: int):
	if current_idx > 0:
		finger_list[current_idx].deselect_weapon()
	finger_list[idx].select_weapon()
	current_idx = idx
