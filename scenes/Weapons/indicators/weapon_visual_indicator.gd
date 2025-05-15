extends MeshInstance3D

@export var highlighted_material: Material
@export var non_highlighted_material: Material

func _ready():
	if not non_highlighted_material: non_highlighted_material = mesh.surface_get_material(0)
	if not highlighted_material: highlighted_material = mesh.surface_get_material(0)
	self.mesh.surface_set_material(0, non_highlighted_material)

func select_weapon():
	self.mesh.surface_set_material(0, highlighted_material)

func deselect_weapon():
	self.mesh.surface_set_material(0, non_highlighted_material)
