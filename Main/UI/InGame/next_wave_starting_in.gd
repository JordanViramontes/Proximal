extends Label

var first_wave: bool = true
var is_counting: bool = false
var time_left: float = 0.0
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")

func _ready() -> void:
	self.visible = true
	label_settings.font_color.a = 0
	
	# signals
	enemy_spawn_path.updateNextWaveTimer.connect(update_time)
	enemy_spawn_path.updateNextWaveVisibility.connect(update_visibility)

func _process(delta: float):
	# timer finishes
	if time_left <= 0 && is_counting:
		# update first wave flag
		if first_wave:
			first_wave = false
		update_visibility(false)
		is_counting = false
	
	if is_counting:
		time_left -= delta
		#print("time: " + str(time_left))
	
	if first_wave:
		self.visible = true
		if label_settings.font_color.a < 1:
			label_settings.font_color.a += 0.01
		text = "GET READY...\n" + str(int(floor(time_left)))
		return
		
	text = "NEXT WAVE SPAWNING IN:\n" + str(int(floor(time_left)))

func update_time(time: float):
	#print("recieved: " + str(time))
	if time == 0: # avoid it looking weird
		return
	time_left = time
	is_counting = true

func update_visibility(visiblity: bool):
	self.visible = visiblity
