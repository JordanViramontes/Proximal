extends Area3D

@export var trauma_amount := 0.1

func cause_trauma():
	var trauma_areas = get_overlapping_areas()
	for area in trauma_areas:
		if area.has_method("add_trauma"):
			area.add_trauma(trauma_amount)

func cause_trauma_conditional(thresh: float):
	var trauma_areas = get_overlapping_areas()
	for area in trauma_areas:
		if area.has_method("add_trauma"):
			if area.trauma < clampf(thresh, 0.0, 1.0):
				area.add_trauma(trauma_amount)
