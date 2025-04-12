extends EnemyBase

func _ready():
	super._ready()  # calls EnemyBase's _ready()
	print("Child _ready()")
	print("Nav: " + str(navigation_agent))

func _process(delta: float) -> void:
	super._process(delta)
	
	if current_state == ENEMY_STATE.spawn_edge:
		print("SPAWN!")
	if current_state == ENEMY_STATE.roam:
		print("ROAM!")
