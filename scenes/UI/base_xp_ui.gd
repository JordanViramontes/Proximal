extends Control

# variables
var gradiant_colors = [
	[Color("9E4840"), Color("f57164")],
	[Color("3E7099"), Color("5da6e4")],
	[Color("8E6A16"), Color("c7971f")],
	[Color("33702A"), Color("53ba45")],
	[Color("96518E"), Color("d975cc")],
]

# components
@onready var hand_texture_node = $HBoxContainer/TextureRect
@onready var xp_progress_bar = $HBoxContainer/VBoxContainer/XpProgressBar
@onready var ability_progress_bar = $HBoxContainer/VBoxContainer/AbilityProgressBar

func initialize(weapon: int):
	var image
	var color
	
	match weapon:
		0:
			print("im a thumb! " + str(self))
			image = preload("res://assets/textures/hand_xp_ui/thumb.png")
			color = gradiant_colors[0]
		1:
			print("im a index! " + str(self))
			image = preload("res://assets/textures/hand_xp_ui/index.png")
			color = gradiant_colors[1]
		2:
			print("im a middle! " + str(self))
			image = preload("res://assets/textures/hand_xp_ui/middle.png")
			color = gradiant_colors[2]
		3:
			print("im a ring! " + str(self))
			image = preload("res://assets/textures/hand_xp_ui/ring.png")
			color = gradiant_colors[3]
		4:
			print("im a pinky! " + str(self))
			image = preload("res://assets/textures/hand_xp_ui/pinky.png")
			color = gradiant_colors[4]
		_:
			print("im nothing! " + str(self))
			image = preload("res://assets/textures/hand_xp_ui/thumb.png")
			color = gradiant_colors[0]
	
	# set hand ui
	hand_texture_node.texture = image
	
	# set ability progress bar texture
	ability_progress_bar.texture_progress = create_new_gradient_texture(color)

func create_new_gradient_texture(color) -> GradientTexture2D:
	# Create a new Gradient resource
	var gradient := Gradient.new()

	# Set the color points (offsets must be between 0.0 and 1.0)
	gradient.add_point(0.0, color[0])  # Start color (red)
	gradient.add_point(0.999999, color[1])  # End color (blue)

	# Create the GradientTexture2D and assign the gradient
	var grad_texture := GradientTexture2D.new()
	grad_texture.gradient = gradient

	# Optional: Set orientation (default is horizontal)
	grad_texture.fill = GradientTexture2D.FILL_LINEAR  # Or FILL_RADIAL, etc.
	grad_texture.width = 256  # You can set the resolution
	grad_texture.height = 1   # If you want a horizontal strip
	
	return grad_texture
