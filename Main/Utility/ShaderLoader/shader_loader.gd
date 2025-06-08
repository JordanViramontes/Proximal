extends Node3D

var waited: bool = false

signal done

func _ready():
	for child in get_children():
		if child is GPUParticles3D:
			child.restart()


func _process(_delta: float):
	# wait one frame
	if not waited:
		waited = true
	else:
		# die
		done.emit()
		self.queue_free()
