extends Control

# variables
var gradiant_colors = [
	[Color("9E4840"), Color("f57164")],
	[Color("3E7099"), Color("5da6e4")],
	[Color("8E6A16"), Color("c7971f")],
	[Color("33702A"), Color("53ba45")],
	[Color("96518E"), Color("d975cc")],
]
var is_ability_cooldown = false
var ability_time_max = 0
var ability_time_current = 0

# xp
var weapon_level: int = 1
var decrease_level_up_alpha: bool = false

# components
@onready var hand_texture_node = $HBoxContainer/TextureRect
@onready var xp_progress_bar = $HBoxContainer/VBoxContainer/XpProgressBar
@onready var weapon_level_label = $WeaponLevel
@onready var ability_progress_bar = $HBoxContainer/VBoxContainer/AbilityProgressBar
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")
@onready var level_up = $LevelUp
@onready var level_up_timer = $LevelUpTimer


func initialize(weapon: int):
	var image
	var color
	var component
	
	match weapon:
		0:
			image = preload("res://assets/textures/hand_xp_ui/thumb.png")
			color = gradiant_colors[0]
			component = weapon_manager.weapon_dictionary[0]
		1:
			image = preload("res://assets/textures/hand_xp_ui/index.png")
			color = gradiant_colors[1]
			component = weapon_manager.weapon_dictionary[1]
		2:
			image = preload("res://assets/textures/hand_xp_ui/middle.png")
			color = gradiant_colors[2]
			component = weapon_manager.weapon_dictionary[2]
		3:
			image = preload("res://assets/textures/hand_xp_ui/ring.png")
			color = gradiant_colors[3]
			component = weapon_manager.weapon_dictionary[3]
		4:
			image = preload("res://assets/textures/hand_xp_ui/pinky.png")
			color = gradiant_colors[4]
			component = weapon_manager.weapon_dictionary[4]
		_:
			image = preload("res://assets/textures/hand_xp_ui/thumb.png")
			color = gradiant_colors[0]
			component = weapon_manager.weapon_dictionary[0]
	
	# set hand ui
	hand_texture_node.texture = image
	
	# set ability progress bar texture
	ability_progress_bar.texture_progress = create_new_gradient_texture(color)
	
	# set visibilities
	level_up.visible = false
	#level_up.modulate.a = 1
	
	# reset values
	xp_progress_bar.value = 0
	ability_progress_bar.value = 100
	
	# set signals
	#print("finger: " + str(component))
	component.send_ui_ability_time.connect(self.set_ability_cooldown_ui)
	component.send_ui_xp_updated.connect(self.set_new_xp_ui)
	component.send_ui_xp_level_updated.connect(self.set_new_xp_level_ui)

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

# when an ability gets used
func set_ability_cooldown_ui(time: float):
	ability_time_current = 0
	ability_time_max = time
	ability_progress_bar.value = 0
	is_ability_cooldown = true

# weapon xp changes
func set_new_xp_ui(xp: float):
	var initial_value: float = xp
	while initial_value > 100:
		initial_value -= 100
	xp_progress_bar.value = initial_value
	#print("setting value to: " + str(initial_value))

# weapon level changes
func set_new_xp_level_ui(level_direction: float):
	var initial_level = weapon_level
	weapon_level = level_direction
	weapon_level_label.text = "Lvl: " + str(weapon_level)
	
	# level up
	if weapon_level > initial_level:
		#print("setting visible: yes")
		level_up.self_modulate.a = 1
		level_up.visible = true
		level_up_timer.start()

func _process(delta: float) -> void:
	if is_ability_cooldown:
		# increase the current time and then use that to calculate the current value
		ability_time_current += delta 
		ability_progress_bar.value = (ability_time_current / ability_time_max) * 100
		
		# check that we're done
		if ability_progress_bar.value == 100:
			is_ability_cooldown = false
	
	# level up and downt
	if decrease_level_up_alpha:
		level_up.self_modulate.a -= 0.5 * delta
		level_up.queue_redraw()
		if level_up.self_modulate.a <= 0:
			level_up.visible = false
			#print("setting visible: no")


func _on_level_up_timer_timeout() -> void:
	decrease_level_up_alpha = true
