extends GPUParticles3D

@export var color: Color

func _ready():
	self.draw_pass_1.material.albedo_color = color
	$GPUParticles3D.finished.connect(kill)
	
	self.emitting = true


func kill():
	print("ERM")
	self.queue_free()
