extends Node3D

var waited: bool = false

func _ready():
	for child in get_children():
		if child is GPUParticles3D:
			child.emitting = true


func _process(_delta: float):
	# wait one frame
	if not waited:
		waited = true
	else:
		# die
		self.queue_free()
