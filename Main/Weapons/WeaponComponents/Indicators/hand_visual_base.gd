extends MeshInstance3D

@export var finger_list: Array[MeshInstance3D]
@export var finger_materials: Array[Material]

@export var ring_indicator_list: Array[MeshInstance3D]
var top_ring_idx: int = 2

var current_idx: int = -1

var fresnel_shader: ShaderMaterial = preload("res://assets/materials/weapons/weap_transparent_fresnel.tres")

func _ready():
	assert(finger_list.size() == finger_materials.size())

func _process(delta: float):
	var selected_finger_albedo = finger_materials[current_idx].albedo_color
	fresnel_shader.set_shader_parameter("fresnel_color", Vector3(selected_finger_albedo.r, selected_finger_albedo.g, selected_finger_albedo.b))
	

func select_finger(idx: int):
	if current_idx >= 0:
		finger_list[current_idx].deselect_weapon()
	finger_list[idx].select_weapon()
	current_idx = idx


func lose_ring():
	ring_indicator_list[top_ring_idx].visible = false
	top_ring_idx -= 1

func gain_ring():
	top_ring_idx += 1
	ring_indicator_list[top_ring_idx].visible = true
	ring_indicator_list[top_ring_idx].do_appear_animation()
