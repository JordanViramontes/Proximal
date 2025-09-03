@tool
class_name RichTextCoolWave extends RichTextEffect

# syntax: [construction freq=5.0 span=10.0][/construction]

var bbcode = "cool_wave"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var speed = char_fx.env.get("freq", 5.0)
	var amp = char_fx.env.get("amp", 10.0)
	var period = char_fx.env.get("period", 1.0)
	
	#char_fx.offset.x = 100 * char_fx.range.x
	char_fx.offset.y = amp * sin(char_fx.elapsed_time * speed + period * char_fx.range.x)
	
	return true
