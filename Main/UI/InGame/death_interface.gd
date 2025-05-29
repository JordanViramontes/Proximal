extends Control

var countdown: float
var activated: bool = false
@onready var death_timer = $Timer

func activate(dur: float):
	if activated:
		return
	self.visible = true
	countdown = dur
	activated = true
	var fade_twn = get_tree().create_tween()
	fade_twn.tween_property($ColorRect, "color", Color(0.0, 0.0, 0.01, 1.0), dur) # near pure black but not full black to avoid screen issues
	print("this is getting called uh")

func _process(delta: float):
	if !activated: return
	if countdown > 0:
		countdown -= delta
	$Label.text = "YOU DIED! RESPAWNING IN:\n%d" % ceil(countdown)
	print("check: " + str(countdown))
