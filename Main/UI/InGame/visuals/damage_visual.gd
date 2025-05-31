extends ColorRect

@onready var trauma: float = 0.0
@export var trauma_reduction_rate: float = 0.3

var base_color: Color

func _ready():
	Util.damage_taken.connect(add_trauma) # util is just our signal bus at this point
	
	# get the current color param
	var c = material.get_shader_parameter("color")
	# base_color should ignore its alpha value
	base_color = Color(c.r, c.g, c.b)
	# set the color's alpha to 0, prevents the alpha from being really high at the start
	material.set_shader_parameter("color", Color(base_color, 0.0))

func _process(delta: float):
	if trauma > 0.0:
		trauma -= trauma_reduction_rate * delta
		
		material.set_shader_parameter("color", Color(base_color, trauma))
	else:
		trauma = 0.0


func add_trauma(amount: float):
	trauma = clampf(trauma + amount, 0.0, 1.0)
	
