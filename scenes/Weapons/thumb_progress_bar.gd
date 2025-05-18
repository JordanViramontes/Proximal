extends TextureProgressBar

@export var thumb_experience: Node
var initial_value: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if thumb_experience:
		thumb_experience.experience_change.connect(update)
		update()
	else:
		pass

func update():
	initial_value = thumb_experience.experience
	while initial_value > 150.0:
		initial_value -= 150.0
	value = initial_value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
