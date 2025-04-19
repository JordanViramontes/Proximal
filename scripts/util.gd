extends Node

func permute_vector(v: Vector3, spread: float):
	return Vector3(v.x + randf_range(-spread, spread), v.y + randf_range(-spread, spread), v.z + randf_range(-spread, spread))

func get_play_pos():
	pass
