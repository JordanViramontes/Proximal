extends Sprite2D

@export var move_force : int = 1
@export var amplitude: float = 4.0
@export var speed: float = 0.5

var start_position: Vector2
var time_passed: float = 0.0

func _ready() -> void:
	start_position = position

func _physics_process(delta: float) -> void:
	time_passed += delta
	position += (get_global_mouse_position() / move_force * delta) - position
	position.y = position.y + sin(time_passed * speed) * amplitude
