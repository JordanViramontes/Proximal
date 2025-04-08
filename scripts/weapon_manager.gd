extends Node3D

# weapon variables
var weapon_dictionary = [
	"Thumb", # will eventually be references to the objects relating to each gun
	"Index",
	"Middle",
	"Ring",
	"Pinky"
]
var curr_weapon_index = 0
var curr_weapon = weapon_dictionary[curr_weapon_index]

# code for polling inputs
func _process(delta: float):
	if Input.is_action_just_pressed("change_weapon_up"):
		change_weapon_to(curr_weapon_index + 1)
	if Input.is_action_just_pressed("change_weapon_down"):
		change_weapon_to(curr_weapon_index - 1)
	if Input.is_action_just_pressed("hotkey_thumb"):
		change_weapon_to(0)
	if Input.is_action_just_pressed("hotkey_index"):
		change_weapon_to(1)
	if Input.is_action_just_pressed("hotkey_middle"):
		change_weapon_to(2)
	if Input.is_action_just_pressed("hotkey_ring"):
		change_weapon_to(3)
	if Input.is_action_just_pressed("hotkey_pinky"):
		change_weapon_to(4)

# 3 ways of recieving new weapon change, either scroll wheels (handled in _process),
# hotkey (also _process), and weapon wheel (recieve signal from wheel node)
func change_weapon_to(weapon):
	if weapon == curr_weapon_index: # same weapon
		return
	if weapon < -1 || weapon > 5: # invalid weapon
		print("weapon_manager.gd - WARNING: new weapon request invalid: " + weapon)
		return
	if weapon == -1: # scroll wrap
		weapon = 4
	if weapon == 5: # scroll wrap
		weapon = 0
	
	# change weapon variables
	curr_weapon_index = weapon
	curr_weapon = weapon_dictionary[curr_weapon_index]
	print("Changed weapon to: " + curr_weapon)
