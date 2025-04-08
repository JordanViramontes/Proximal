extends Path3D

# which enemy to spawn
@export var mob_scene: PackedScene
@export var amount_per_wave = 1

# modified from squash the creeps lol
func _process(delta):
	if Input.is_action_just_pressed("debug_spawn_wave"):
		for i in range(amount_per_wave):
			# Create a new instance of the Mob scene.
			var mob = mob_scene.instantiate()
			
			# Choose a random location on the SpawnPath.
			# We store the reference to the SpawnLocation node.
			var mob_spawn_location = get_node("EnemySpawner")
			
			# And give it a random offset.
			mob_spawn_location.progress_ratio = randf()
			print("test: " + str(mob_spawn_location.progress_ratio))
			
			var player_position = $"../Player".global_position
			print("mobPos: " + str(mob.position))
			mob.initialize(mob_spawn_location.position, player_position)
			
			# Spawn the mob by adding it to the Main scene.
			add_child(mob)
