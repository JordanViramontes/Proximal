extends Node3D

@onready var player: Player = get_tree().get_first_node_in_group("Player")
@export var hand_visual_base: MeshInstance3D

# weapon variables
var weapon_dictionary
var curr_weapon_index
var curr_weapon # defined in ready
var xp_dictionary = [0.0, 0.0, 0.0, 0.0, 0.0]
var xp_scale = [100.0, 100.0, 500.0, 50.0, 20.0]
var weapon_level = [1, 1, 1, 1, 1]
@onready var inverted_scroll: bool = ConfigFileHandler.load_scroll_inverted_settings()

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
var shield_duration: float = 2.0
signal dashInput
signal abilityInput #healing

# recoil stuff
var total_recoil: float
var max_recoil: float = 1.0
var recoil_direction: Vector3 = Vector3.BACK # recoil should be in positive z direction....!
@export var recoil_recovery_rate: float # amount per frame we recover from recoil
@export var recoil_reduction_rate: float

# signals
signal update_ring(ring_count: int)
signal update_weapon_gui(weapon: int)

func _ready():
	weapon_dictionary = [
		$Thumb,
		$Index,
		$Middle,
		$Ring,
		$Pinky
	]
	curr_weapon_index = 1
	set_current_weapon(curr_weapon_index)
	
	# move them to where the visual base is
	for i in range(len(weapon_dictionary)):
		weapon_dictionary[i].position = hand_visual_base.position
		weapon_dictionary[i].bullet_emerge_point = $BulletEmergePoint
	
	# signals
	$Ring.used_ring.connect(on_used_ring)
	
	# disable enemy stun hitbox
	hitboxColl.disabled = true

# code for polling inputs
func _process(delta: float):
	# change weapon
	if not inverted_scroll:
		if Input.is_action_just_pressed("change_weapon_up"):
			change_weapon_to(curr_weapon_index - 1)
		if Input.is_action_just_pressed("change_weapon_down"):
			change_weapon_to(curr_weapon_index + 1)
	else:
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
	
	# recoil
	update_recoil(delta)

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
	set_current_weapon(weapon_index)
	
	#print("Changed weapon to: " + str(curr_weapon))

# when shoot, use the weapon currently used
func shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	if curr_weapon.is_hitscan:
		curr_weapon.shoot(from_pos, look_direction, velocity)
	else:
		curr_weapon.shoot(position, look_direction, velocity)
	#print("weapon_manager - not shooting atm")

func ability_shoot(from_pos: Vector3, look_direction: Vector3, velocity: Vector3):
	#print("calling ability shoot with params: %s, %s, %s" % [from_pos, look_direction, velocity])
	if curr_weapon.is_hitscan:
		curr_weapon.ability_shoot(from_pos, look_direction, velocity)
	else:
		curr_weapon.ability_shoot(position, look_direction, velocity)
	#print("weapon_manager - not shooting atm")

func cease_fire():
	curr_weapon.cease_fire()

func set_current_weapon(index: int):
	curr_weapon = weapon_dictionary[index]
	hand_visual_base.select_finger(index)
	curr_weapon_index = index
	#curr_weapon.visible = true
	curr_weapon.active = true
	update_weapon_gui.emit(index)

func set_weapon_unactive(weapon):
	#weapon.visible = false
	weapon.active = false

func use_ability(finger):
	if not canUseWeapon:
		print("WeaponManager: Can't use ability right now (weapons disabled).")
		return
		
	match finger:
		0:
			if curr_weapon.use_ability():
				abilityInput.emit()
				print(abilityInput.get_connections())
			
		1:
			if weapon_dictionary[finger].use_ability():
				disableWeapons(0.5) # disable for whatever the dash length is idk
				dashInput.emit()
		2:
			weapon_dictionary[finger].use_ability()
			# DONT NEED THE IF STATEMENT because the ability logic is handled on the middle finger weapon
		3:
			if weapon_dictionary[finger].use_ability():
				abilityInput.emit()
				#print("healing deploying")
		4:
			if weapon_dictionary[finger].use_ability():
				abilityInput.emit()
				#print("sniping")
		_:
			print("weapon_manager - WARNING: no finger to use for ability")
			return

func disableWeapons(time: float = 0.0):
	if time > 0.0:
		var t: Timer = $DashTimer
		if not t.is_stopped(): t.stop()
		t.wait_time = time
		t.start()
	#print("disable weapons")
	canUseWeapon = false

func enableWeapons():
	#print("enable weapons")
	canUseWeapon = true

func isCanUseWeapon() -> bool:
	return canUseWeapon

func _on_dash_timer_timeout() -> void:
	enableWeapons()

func stun_enemies() -> void:
	#print("weapon_manager.gd: stunning")
	hitboxColl.disabled = false
	can_stun = false
	hitboxTimer.start()
	stunEnemyTimer.start()

func _on_stun_hitbox_timer_timeout() -> void:
	# diabled stun hitbox coll and unstun enemies
	#print("weapon_manager.gd: stun hitbox disabled")
	hitboxColl.disabled = true

func _on_stun_hitbox_body_entered(body: EnemyBase) -> void:
	#print("weapon_manager.gd: stun hitbox found: " + str(body))
	currently_stunned_enemies.push_back(body)
	body._on_recieve_stun()

func _on_stun_enemy_timer_timeout() -> void:
	#print ("weapon_manager.gd: unstunning")
	
	# flush stunned array
	for i in currently_stunned_enemies:
		if i:
			i._on_recieve_unstun()
	
	currently_stunned_enemies = []
	
	can_stun = true

# recieve signal from earning xp
func _on_earn_experience(xp: float):
	curr_weapon.add_xp(xp)
	#print("earned: " + str(xp) + "xp for " + str(curr_weapon))
	curr_weapon.print_xp(str(weapon_dictionary[curr_weapon_index]))
	

func _on_enemy_die():
	#ammo
	var dice = randi_range(0, 10) # omg d10
	if dice < 2:
		if weapon_dictionary[3].ammo_count < weapon_dictionary[3].max_ammo:
			weapon_dictionary[3].add_ring()
			hand_visual_base.gain_ring()
			update_ring.emit(weapon_dictionary[3].ammo_count)
		#print("woah a ring! ring count: " + str(weapon_dictionary[3].ammo_count))



#region Recoil Causing
# cause recoil, intended to be called from BaseWeapon inheritors that are my children
func cause_recoil(amount: float) -> void:
	total_recoil = clamp(total_recoil + amount, 0.0, max_recoil)

func cause_recoil_clamped(amount: float, limit: float) -> void:
	total_recoil = clamp(total_recoil + amount, 0.0, max(max_recoil, limit))

# update the current recoil of the hand_visual, uses total_recoil variable
# should be called in _process() probably
func update_recoil(delta: float):
	total_recoil = max(total_recoil - delta * recoil_reduction_rate, 0.0)
	hand_visual_base.position = clamp(hand_visual_base.position + recoil_direction * total_recoil * total_recoil * delta, Vector3.ZERO, recoil_direction)
	
	# scale the speed at which we recover by how far away we are
	hand_visual_base.position = hand_visual_base.position.move_toward(Vector3.ZERO, delta * recoil_recovery_rate * hand_visual_base.position.length())
#endregion

# provide connection to the hand visual to update the ring visual when the ring uses ammunition
func on_used_ring():
	hand_visual_base.lose_ring()
	update_ring.emit(weapon_dictionary[3].ammo_count)
