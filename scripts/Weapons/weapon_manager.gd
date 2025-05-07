extends Node3D


@export var player: Player # kind of hate that i have this but o well! 

# weapon variables
var weapon_dictionary
var curr_weapon_index
var curr_weapon # defined in ready

# weapon / ability authentication
var canUseWeapon: bool = true
var canDash: bool = true
signal dashInput
signal abilityInput #healing 

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
	# change weapon
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
	
	# abilities
	if Input.is_action_just_pressed("ability"):
		use_ability(curr_weapon_index)
	if Input.is_action_just_pressed("hotkey_dash"): # Index = 1
		use_ability(1)


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
	cease_fire()
	set_weapon_unactive(curr_weapon)
	
	# change weapon variables
	curr_weapon_index = weapon_index
	curr_weapon = weapon_dictionary[curr_weapon_index]
	set_weapon_active(curr_weapon)
	
	print("Changed weapon to: " + str(curr_weapon))

# when shoot, use the weapon currently used
func shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if curr_weapon.is_hitscan:
		curr_weapon.shoot(from_pos, look_direction, velocity)
	else:
		curr_weapon.shoot(position, look_direction, velocity)
	#print("weapon_manager - not shooting atm")

func ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	print("calling ability shoot with params: %s, %s, %s" % [from_pos, look_direction, velocity])
	if curr_weapon.is_hitscan:
		curr_weapon.ability_shoot(from_pos, look_direction, velocity)
	else:
		curr_weapon.ability_shoot(position, look_direction, velocity)
	#print("weapon_manager - not shooting atm")

func cease_fire():
	curr_weapon.cease_fire()

func set_weapon_active(weapon):
	weapon.visible = true
	weapon.active = true

func set_weapon_unactive(weapon):
	weapon.visible = false
	weapon.active = false

func use_ability(finger):
	match finger:
		1:
			disableWeapons()
			dashInput.emit()
			$DashTimer.start()
		2:
			Util.toggle_shield.emit(true)
			await get_tree().create_timer(2).timeout
			Util.toggle_shield.emit(false)
		3:
			abilityInput.emit()
			print("healing deploying")
			pass
		_:
			print("weapon_manager - WARNING: no finger to use for ability")
			return

func disableWeapons():
	print("disable weapons")
	canUseWeapon = false

func enableWeapons():
	print("enable weapons")
	canUseWeapon = true

func isCanUseWeapon() -> bool:
	return canUseWeapon

func _on_dash_timer_timeout() -> void:
	enableWeapons()

# recieve signal from earning xp
func _on_earn_experience(xp: float):
	print("earned: " + str(xp) + "xp")
