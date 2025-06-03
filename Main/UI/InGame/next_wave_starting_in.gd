extends Label

var first_wave: bool = true
var is_counting: bool = false
var should_do_anything: bool = true
var time_left: float = 0.0
@onready var enemy_spawn_path = get_tree().get_first_node_in_group("EnemySpawnParent")

# VISIBLE STATES
var VIS_STATES = {
	"on":0,
	"stay":1,
	"off":2
}
var current_vis_state = VIS_STATES.on

func _ready() -> void:
	self.visible = true
	label_settings.font_color.a = 0
	
	# signals
	enemy_spawn_path.updateNextWaveTimer.connect(update_time)
	enemy_spawn_path.updateNextWaveVisibility.connect(update_visibility)

func _process(delta: float):
	if not should_do_anything:
		return
	
	if time_left > 0:
		time_left -= delta
	if time_left < 0:
		time_left = 0 # fix bug related to seeing -1 at low framerates
	
	if first_wave:
		text = "GET READY...\n" + str(int(floor(time_left)))
	else:
		text = "NEXT WAVE SPAWNING IN:\n" + str(int(floor(time_left)))
	
	# visuals
	#print("state: " + str(current_vis_state))
	if current_vis_state == VIS_STATES.on:
		self.visible = true
		label_settings.font_color.a += 1.5 * delta # use delta for framerate independent interpolation
		if label_settings.font_color.a >= 1.0:
			label_settings.font_color.a = 1
			current_vis_state = VIS_STATES.stay
	
	if current_vis_state == VIS_STATES.off:
		self.visible = true
		label_settings.font_color.a -= 1.5 * delta # use delta for framerate independent interpolation
		if label_settings.font_color.a <= 0:
			label_settings.font_color.a = 0
			current_vis_state = VIS_STATES.stay
			
			# end first wave if its the first
			if first_wave:
				first_wave = false

func update_time(time: float):
	#print("recieved: " + str(time))
	if time == 0: # avoid it looking weird
		return
	time_left = time
	is_counting = true

func update_visibility(visiblity: bool):
	#print("has: " + str(visiblity))
	
	if visiblity:
		current_vis_state = VIS_STATES.on 
	else:
		current_vis_state = VIS_STATES.off

func _on_dying_ui():
	self.visible = false
	should_do_anything = false
