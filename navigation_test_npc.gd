extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D
@onready var player = get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	navigation_agent.set_target_position(player.global_position)
	

func _physics_process(delta: float) -> void:
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	var v = direction * 2
	velocity.x = v.x
	velocity.z = v.z
	move_and_slide()
