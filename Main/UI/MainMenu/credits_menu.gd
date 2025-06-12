extends Control

@onready var menu_bg: ColorRect = $BG
@onready var title_label: Label = $BG/CenterContainer/VBoxContainer/BigLabel
@onready var credits_label: RichTextLabel = $BG/CenterContainer/VBoxContainer/Hello

var is_active: bool

func _ready():
	self.reset_transparency()

func switch_to():
	self.visible = true
	self.is_active = true
	
	var tw = get_tree().create_tween()
	tw.tween_property(menu_bg, "color", Color(0.0, 0.0, 0.0, 1.0), 0.5)
	tw.tween_property(title_label, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	tw.tween_property(credits_label, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)

func _physics_process(delta: float):
	if is_active:
		if Input.is_action_just_pressed("escape"):
			self.close_menu()

func reset_transparency(): # call when switching from
	menu_bg.color.a = 0.0
	title_label.self_modulate.a = 0.0
	credits_label.self_modulate.a = 0.0

func close_menu():
	self.is_active = false
	self.visible = false
	self.reset_transparency()

func _on_return_button_pressed() -> void:
	self.close_menu()
