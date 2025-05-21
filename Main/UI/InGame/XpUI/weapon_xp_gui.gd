extends VBoxContainer

# components
@onready var thumb = $Thumb
@onready var index = $Index
@onready var middle = $Middle
@onready var ring = $Ring
@onready var pinky = $Pinky

func _ready() -> void:
	thumb.initialize(0)
	index.initialize(1)
	middle.initialize(2)
	ring.initialize(3)
	pinky.initialize(4)
