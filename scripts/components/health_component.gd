extends Node

var max_health: float
var current_health: float

signal reached_zero_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func damage(amount: float) -> void:
	#print("hp: " + str(current_health))
	current_health = clamp(current_health - amount, 0.0, max_health)
	if current_health == 0.0:
		reached_zero_health.emit()

# pls dont call with negative values
func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
