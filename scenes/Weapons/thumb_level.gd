extends RichTextLabel

@export var thumb_experience: Node
var level: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if thumb_experience:
		thumb_experience.experience_change.connect(update)
		update()
	else:
		pass

func update():
	level = thumb_experience.level
	text = "Lv. " + str(level)
	if level >= 4:
		text = "MAX"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
