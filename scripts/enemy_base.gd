extends CharacterBody3D

@export var max_health: float
@export var hitflash_material: Material
@export var hitflash_duration: float = 0.1
var hitflash_tween: Tween

# components
@onready var health_component := $HealthComponent
@onready var hitbox_component := $HitboxComponent

# signals
signal die
signal take_damage

# Constructor called by spawner
func initialize(starting_position, player_position):
	position = starting_position
	look_at_from_position(position, player_position, Vector3.UP)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)
	hitbox_component.damaged.connect(on_damaged)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_reach_zero_health():
	die.emit()
	self.queue_free()

func on_damaged(amount: float):
	if (hitflash_tween and hitflash_tween.is_running()):
		hitflash_tween.stop()
	hitflash_tween = get_tree().create_tween()
	$MeshInstance3D.material_overlay.albedo_color = Color(1.0, 1.0, 1.0, 1.0) # set alpha
	hitflash_tween.tween_property($MeshInstance3D, "material_overlay:albedo_color", Color(1.0, 1.0, 1.0, 0.0), 0.1) # tween alpha
