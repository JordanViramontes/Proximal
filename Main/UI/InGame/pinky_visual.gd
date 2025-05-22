extends ColorRect

func _ready():
	Util.sniper_visual.connect(on_sniper_visual)

func on_sniper_visual(state: bool):
	if state == true:
		self.show()
	else:
		self.hide()
