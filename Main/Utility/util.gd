extends Node
#shield
signal toggle_shield(state:bool)
#healing
signal healing(state:bool)
#camera
signal sniper_visual(state:bool)
signal zoom_in
signal zoom_out

signal damage_taken(amount: float)


func permute_vector(v: Vector3, spread: float):
	return Vector3(v.x + randf_range(-spread, spread), v.y + randf_range(-spread, spread), v.z + randf_range(-spread, spread))

func get_play_pos():
	pass
