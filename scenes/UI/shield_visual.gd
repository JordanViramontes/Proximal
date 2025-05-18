extends ColorRect

func _ready():
	Util.toggle_shield.connect(on_toggle_shield)

func on_toggle_shield(state: bool):
	if state == true:
		self.show()
	else:
		self.hide()
