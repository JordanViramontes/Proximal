extends Sprite2D

@export var move_force : int = 1
@export var amplitude: float = 4.0
@export var speed: float = 1
# lag_point delays the bobbing animation
@export var lag_point: float = 0

var time_passed: float = 0.0

func _physics_process(delta: float) -> void:
	time_passed += delta
	# parallax effect - moves UI element based on global mouse position
	position += (get_global_mouse_position() / move_force * delta) - position
	
	# bobbing
	position.y = position.y + sin((time_passed * speed) - deg_to_rad(lag_point)) * amplitude
