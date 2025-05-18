extends Node3D

@onready var player: Player = get_tree().get_first_node_in_group("Player")
#@export var player: Player # kind of hate that i have this but o well! 

# weapon variables
var weapon_dictionary
var curr_weapon_index
var curr_weapon # defined in ready
var xp_dictionary = [0.0, 0.0, 0.0, 0.0, 0.0]
var xp_scale = [100.0, 100.0, 500.0, 50.0, 20.0]
var weapon_level = [1, 1, 1, 1, 1]

# hitbox
@onready var hitboxColl: CollisionShape3D = $StunHitbox/CollisionShape3D
@onready var hitboxTimer: Timer = $StunHitboxTimer
@onready var stunEnemyTimer: Timer = $StunEnemyTimer
#@onready var hitboxCol: CollisionShape3D = $StunHitbox/CollisionShape3D
var face_dir: Vector3 = Vector3.ZERO
var currently_stunned_enemies: Array[EnemyBase] = []
var can_stun: bool = true;

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
	
	hitboxColl.disabled = true

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
	
	# debug
	if Input.is_action_just_pressed("debug_enemy_stun"):
		if can_stun == true:
			stun_enemies()

func _physics_process(delta: float) -> void:
	face_dir = Vector3.FORWARD
	hitboxColl.look_at(self.position + to_global(face_dir), Vector3.UP)
	pass

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
		0:
			abilityInput.emit()
			print("vaccum")
			pass
		1:
			if curr_weapon.use_ability():
				disableWeapons(0.5) # disable for whatever the dash length is idk
				dashInput.emit()
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

func disableWeapons(time: float = 0.0):
	if time > 0.0:
		var t: Timer = $DashTimer
		if not t.is_stopped(): t.stop()
		t.wait_time = time
		t.start()
	print("disable weapons")
	canUseWeapon = false

func enableWeapons():
	print("enable weapons")
	canUseWeapon = true

func isCanUseWeapon() -> bool:
	return canUseWeapon

func _on_dash_timer_timeout() -> void:
	enableWeapons()

func stun_enemies() -> void:
	print("weapon_manager.gd: stunning")
	hitboxColl.disabled = false
	can_stun = false
	hitboxTimer.start()
	stunEnemyTimer.start()

func _on_stun_hitbox_timer_timeout() -> void:
	# diabled stun hitbox coll and unstun enemies
	print("weapon_manager.gd: stun hitbox disabled")
	hitboxColl.disabled = true

func _on_stun_hitbox_body_entered(body: EnemyBase) -> void:
	print("weapon_manager.gd: stun hitbox found: " + str(body))
	currently_stunned_enemies.push_back(body)
	body._on_recieve_stun()


func _on_stun_enemy_timer_timeout() -> void:
	print ("weapon_manager.gd: unstunning")
	can_stun = true
	
	# flush stunned array
	for i in currently_stunned_enemies:
		if i:
			i._on_recieve_unstun()
	
	currently_stunned_enemies = []

# recieve signal from earning xp
func _on_earn_experience(xp: float):
	curr_weapon.add_xp(xp)
	print("earned: " + str(xp) + "xp for " + str(curr_weapon))
	curr_weapon.print_xp(str(weapon_dictionary[curr_weapon_index]))
