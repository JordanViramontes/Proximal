extends Label

var letters: Array[Label]

func _ready():
	for i in range(len(text)):
		# create a new child Label for each letter
		var l = Label.new()
		l.text = self.text[i]
		l.theme = self.theme
		l.position = self.get_character_bounds(i).position
		letters.append(l)
		self.add_child(l)
	
	self.text = ""

func _process(delta: float):
	for i in range(len(letters)):
		letters[i].position = Vector2(letters[i].position.x, 8.0 * sin(i + 0.25 * float(Time.get_ticks_msec() * delta)))
