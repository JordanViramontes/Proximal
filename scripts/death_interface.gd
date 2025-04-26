extends Control

var countdown: float
var activated: bool = false

func activate(dur: float):
	self.visible = true
	countdown = dur
	activated = true
	var fade_twn = get_tree().create_tween()
	fade_twn.tween_property($ColorRect, "color", Color(0.0, 0.0, 0.0, 0.75), dur)

func _process(delta: float):
	if !activated: return
	if countdown > 0:
		countdown -= delta
	$Label.text = "you are dead! resetting in %d" % ceil(countdown)
