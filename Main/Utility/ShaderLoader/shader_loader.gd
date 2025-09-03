extends Node3D

var waited: bool = false

signal done

func _ready():
	print("SHADER LOADER")
	for child in get_children():
		child.visible = false
		if child is GPUParticles3D:
			child.restart()
	
	load_stuff()

func load_stuff():
	var children := get_children()
	for child in children:
		print("loading %s" % child)
		child.visible = true
		await get_tree().process_frame
		child.visible = false
	
	done.emit()
	self.queue_free()
