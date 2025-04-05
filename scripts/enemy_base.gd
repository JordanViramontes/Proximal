extends CharacterBody3D

@export var max_health: float

# components
@onready var health_component := $HealthComponent
@onready var hitbox_component := $HitboxComponent

# signals
signal die

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.reached_zero_health.connect(on_reach_zero_health)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_reach_zero_health():
	die.emit()
	self.queue_free()
