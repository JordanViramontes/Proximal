extends Area3D

@export var trauma_reduction_rate := 1.0

@export var max_x := 10.0
@export var max_y := 10.0
@export var max_z := 5.0

@export var noise: FastNoiseLite
@export var noise_speed := 50.0

var trauma := 0.0
var time := 0.0

@onready var cam: Camera3D = $Camera3D
@onready var initial_rotation: Vector3 = cam.rotation_degrees

func _ready():
	Util.zoom_in.connect(zoom_in)
	Util.zoom_out.connect(zoom_out)

func _process(delta: float) -> void:
	time += delta
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	
	cam.rotation_degrees.x = initial_rotation.x + max_x * get_shake_intensity() * get_noise_from_seed(0)
	cam.rotation_degrees.y = initial_rotation.y + max_y * get_shake_intensity() * get_noise_from_seed(1)
	cam.rotation_degrees.z = initial_rotation.z + max_z * get_shake_intensity() * get_noise_from_seed(2)

func add_trauma(trauma_amount: float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(seed: int) -> float:
	noise.seed = seed
	return noise.get_noise_1d(time * noise_speed)
	
func zoom_in():
	var a = get_tree().create_tween()
	a.tween_property($Camera3D,"fov",25, 0.2)
	pass
func zoom_out():
	var a = get_tree().create_tween()
	a.tween_property($Camera3D,"fov",75, 0.2)
	pass
