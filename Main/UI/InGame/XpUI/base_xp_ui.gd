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
@onready var weapon_type: int
@onready var weapon_node: Node

# components
@onready var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")
@onready var active = $Active
@onready var minimized = $Minimized
@onready var level_up_timer = $LevelUpTimer

# active nodes
@onready var active_hand_texture_node = $Active/HBoxContainer/TextureRect
@onready var active_xp_progress_bar = $Active/HBoxContainer/VBoxContainer/XpProgressBar
@onready var active_ability_progress_bar = $Active/HBoxContainer/VBoxContainer/AbilityProgressBar
@onready var active_weapon_level_label = $Active/WeaponLevel
@onready var active_level_up = $Active/LevelUp

# minimized nodes
@onready var minimized_hand_texture_node = $Minimized/ColorRect
@onready var minimized_xp_progress_bar = $Minimized/HBoxContainer/VBoxContainer/XpProgressBar
@onready var minimized_ability_progress_bar = $Minimized/HBoxContainer/VBoxContainer/AbilityProgressBar
@onready var minimized_weapon_level_label = $Minimized/WeaponLevel
@onready var minimized_level_up = $Minimized/LevelUp


func initialize(weapon: int):
	var image
	var color
	var component
	
	weapon_type = weapon
	weapon_node = weapon_manager.weapon_dictionary[weapon_type]
	
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
	active_hand_texture_node.texture = image
	minimized_hand_texture_node.color = color[1]
	
	# set ability progress bar texture
	var gradient = create_new_gradient_texture(color)
	active_ability_progress_bar.texture_progress = gradient
	minimized_ability_progress_bar.texture_progress = gradient
	
	# set visibilities
	active_level_up.visible = false
	minimized_level_up.visible = false
	#active_level_up.modulate.a = 1
	
	# reset values
	active_xp_progress_bar.value = 0
	active_xp_progress_bar.max_value = weapon_node.upgrade_quota
	active_ability_progress_bar.value = 100
	
	minimized_xp_progress_bar.value = 0
	minimized_xp_progress_bar.max_value = weapon_node.upgrade_quota
	minimized_ability_progress_bar.value = 100
	
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
	gradient.add_point(0.9999999, color[1])  # End color (blue)

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
	active_ability_progress_bar.value = 0
	minimized_ability_progress_bar.value = 0
	is_ability_cooldown = true

# weapon xp changes
func set_new_xp_ui(xp: float):
	var initial_value: float = xp
	while initial_value > weapon_node.upgrade_quota:
		initial_value -= weapon_node.upgrade_quota
	active_xp_progress_bar.value = initial_value
	minimized_xp_progress_bar.value = initial_value
	#print("setting value to: " + str(initial_value) +  " for " + str(weapon_node))

# weapon level changes
func set_new_xp_level_ui(level_direction: float):
	var initial_level = weapon_level
	weapon_level = level_direction
	active_weapon_level_label.text = "Lvl: " + str(weapon_level)
	minimized_weapon_level_label.text = "Lvl: " + str(weapon_level)
	
	# level up
	if weapon_level > initial_level:
		#print("setting visible: yes")
		active_level_up.self_modulate.a = 1
		active_level_up.visible = true
		minimized_level_up.self_modulate.a = 1
		minimized_level_up.visible = true
		level_up_timer.start()

func _process(delta: float) -> void:
	#print("check: " + str(is_ability_cooldown))
	if is_ability_cooldown:
		# increase the current time and then use that to calculate the current value
		ability_time_current += delta 
		active_ability_progress_bar.value = (ability_time_current / ability_time_max) * 100
		minimized_ability_progress_bar.value = (ability_time_current / ability_time_max) * 100
		
		# check that we're done
		if active_ability_progress_bar.value == 100:
			is_ability_cooldown = false
	
	# level up and down
	if decrease_level_up_alpha:
		active_level_up.self_modulate.a -= 0.5 * delta
		active_level_up.queue_redraw()
		minimized_level_up.self_modulate.a -= 0.5 * delta
		minimized_level_up.queue_redraw()
		if active_level_up.self_modulate.a <= 0:
			active_level_up.visible = false
			minimized_level_up.visible = false
			#print("setting visible: no")

func _on_level_up_timer_timeout() -> void:
	decrease_level_up_alpha = true

func _on_set_active(weapon: int) -> void:
	# active
	if weapon_type == weapon:
		active.visible = true
		minimized.visible = false
		self.size.y = 29
	
	else:
		active.visible = false
		minimized.visible = true
		self.size.y = 17
