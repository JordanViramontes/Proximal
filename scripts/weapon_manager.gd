extends Node3D

# weapon variables
var weapon_dictionary
var curr_weapon_index
var curr_weapon # defined in ready

func _ready():
	weapon_dictionary = [
		$Thumb,
		$Index,
		$Middle,
		$Ring,
		$Pinky
	]
	curr_weapon_index = 1
	curr_weapon = weapon_dictionary[curr_weapon_index]
	set_weapon_active(curr_weapon)

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
func change_weapon_to(weapon_index):
	if weapon_index == curr_weapon_index: # same weapon
		return
	if weapon_index < -1 || weapon_index > 5: # invalid weapon
		print("weapon_manager.gd - WARNING: new weapon request invalid: " + weapon_index)
		return
	if weapon_index == -1: # scroll wrap
		weapon_index = 4
	if weapon_index == 5: # scroll wrap
		weapon_index = 0
	
	# set previous weapon stuff
	set_weapon_unactive(curr_weapon)
	
	# change weapon variables
	curr_weapon_index = weapon_index
	curr_weapon = weapon_dictionary[curr_weapon_index]
	set_weapon_active(curr_weapon)
	
	print("Changed weapon to: " + str(curr_weapon))

# when shoot, use the weapon currently used
func shoot():
	curr_weapon.shoot()
	#print("weapon_manager - not shooting atm")

func set_weapon_active(weapon):
	weapon.visible = true
	weapon.active = true

func set_weapon_unactive(weapon):
	weapon.visible = false
	weapon.active = false
