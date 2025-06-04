extends MeshInstance3D

@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	do_appear_animation()

func do_appear_animation() -> void:
	var camcamcam := get_viewport().get_camera_3d()
	sprite.global_basis.z = camcamcam.global_basis.z # face the sprite towards the camera
	
	sprite.visible = true
	sprite.scale = Vector3.ONE # reset scale
	var tw = get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector3.ZERO, 1.5) # tween scale
	tw.tween_property(sprite, "rotation", Vector3(0, 0, deg_to_rad(8*PI)), 1.5)
