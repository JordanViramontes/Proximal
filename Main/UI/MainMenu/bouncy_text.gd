extends Label

var letters: Array[Label]

@export var amplitude: float = 8.0
@export var lag_point: float = 0.0
@export var speed: float = 1.0

var time_passed: float = 0.0

var total_width: float = 0.0



func _ready():
	self.add_theme_font_size_override("meow?", 57)
	for i in range(len(text)):
		# create a new child Label for each letter
		var l = Label.new()
		l.text = self.text[i]
		l.theme = self.theme
		l.position = self.get_character_bounds(i).position * self.scale
		l.add_theme_font_size_override("meow?", 57)
		l.scale = self.scale
		l.texture_filter = self.texture_filter
		letters.append(l)
		self.add_child(l)
		
		total_width += self.get_character_bounds(i).size.x * self.scale.x
	
	self.text = ""
	
	self.position.x -= total_width / 2.0

func _process(delta: float):
	pass

func _physics_process(delta: float):
	time_passed += delta
	for i in range(len(letters)):
		letters[i].position = Vector2(letters[i].position.x, sin(time_passed * speed - deg_to_rad(lag_point * i)) * amplitude)
