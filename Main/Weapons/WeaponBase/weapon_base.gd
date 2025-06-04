extends Node3D
class_name WeaponBase

# misc
var bullet_emerge_point: Node3D # should be set in the parent WeaponManager

# Experience Points
@export_group("Experience & Levels")
@export var xp_gain_multiplier: float = 1 # for each weapon
@export var experience: float = 0
var level_experience: float
@export var level: int = 1
@export var max_level: int = 5
@export var max_level_decay_timer: float = 5.0
var max_level_timer: float
signal experience_change

# Quota and degradation rate is different for every weapon
@export var upgrade_quota: float = 100.0
@export var degradation: float = 2.0 # decrease xp by this amount per second
@export var expected_usage: int = 10
@export var expected_usage_rate: int = 10
@export var fire_rate_scaling: float = 0.2
var tick: int = 0
var weapon_usage: int = 0

@export_group("Shooting & Bullets")
var shoot_cooldown: float = 0.05 # seconds
@export var fire_rate: float = 2 # shots per second
@onready var shoot_timer: Timer = $ShootCooldown
var can_shoot: bool = true
@export var active = false
@export var bullet: PackedScene
@export var bullet_damage: float
@export var bullet_speed: float
@export var is_hitscan: bool
@export var depleted_material: Material
var normal_material: Material

@export_group("Abilities")
# ability stuff
@export var ability_cooldown: float = 5.0 # default 5 seconds
var current_ability_cooldown: float = 0.0 # <= 0 if the ability is off cooldown
@export var ability_recharge_particle_color: Color
@export var ability_recharge_particles: PackedScene
var recharge_particles: GPUParticles3D
@export var depleted_color: Color
var default_material: Material


@export_group("Trauma & Recoil")
@export var trauma_amount: float
@export var recoil_limit: float
@export var recoil_amount: float

# reference to manager
@onready var weapon_manager = $".."
signal on_shoot
signal on_ceasefire
signal on_ability_shoot
signal used_ability

# signals
signal send_ui_ability_time(time_left: float)
signal send_ui_xp_updated(xp: float)
signal send_ui_xp_level_updated(level: int) 
signal send_ui_xp_max_level

#region audio
# sound effects
@onready var audio_manager: Node3D
signal sound_effect_signal_start(name: String)
signal sound_effect_signal_stop(name: String)

var SE_xp_earned: String = "xp_earned"
var SE_level_up: String = "level_up"
var SE_shoot: String = "shoot"
var SE_pinky_shoot: String = "pinky_shoot"
var SE_middle_hit: String = "middle_hit"

var SE_ability_thumb: String = "ability_thumb"
var SE_ability_index: String = "ability_index"
var SE_ability_pinky: String = "ability_pinky"
var SE_ability_middle: String = "ability_middle"
var SE_ability_ring: String = "ability_middle_ring"

@onready var sound_effects: Dictionary = { }
#endregion

func _ready() -> void:
	shoot_timer.wait_time = 1/(fire_rate*level)
	shoot_timer.timeout.connect(func(): can_shoot = true)
	if ability_recharge_particles:
		recharge_particles = ability_recharge_particles.instantiate()
		add_child(recharge_particles)
		recharge_particles.draw_pass_1.surface_get_material(0).albedo_color = ability_recharge_particle_color
	
	init_set_audio()

func init_set_audio():
	# sound effect nodes
	audio_manager = Node3D.new()
	audio_manager.set_script(load("res://Main/Utility/AudioManager/audio_manager.gd"))
	add_child(audio_manager)
	#print("manager: " + str(audio_manager))
	
	# use this code if you don't want to use a oneshot
	var SE_xp_earned_node = AudioStreamPlayer.new()
	SE_xp_earned_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/xp_earned.wav")
	var SE_level_up_node  = AudioStreamPlayer.new()
	SE_level_up_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/level_up.wav")
	var SE_shoot_node  = AudioStreamPlayer.new()
	SE_shoot_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/shoot.wav")
	var SE_pinky_shoot_node  = AudioStreamPlayer.new()
	SE_pinky_shoot_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Weapons/pinky.wav")
	var SE_middle_hit_node = AudioStreamPlayer.new()
	SE_middle_hit_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Weapons/middle_hit.wav")
	
	var SE_ability_thumb_node = AudioStreamPlayer.new()
	SE_ability_thumb_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Abilities/vacuum.wav")
	var SE_ability_index_node = AudioStreamPlayer.new()
	SE_ability_index_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Abilities/dash.wav")
	var SE_ability_pinky_node = AudioStreamPlayer.new()
	SE_ability_pinky_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Abilities/pinky_scope.wav")
	var SE_ability_middle_node = AudioStreamPlayer.new()
	SE_ability_middle_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Abilities/shielding.mp3")
	var SE_ability_ring_node = AudioStreamPlayer.new()
	SE_ability_ring_node.stream = load("res://assets/Sounds/Sound Effects/Weapon/Abilities/ring_ability.wav")
	SE_ability_ring_node.volume_db = -5.0
	# this is a dictionary of either strings -> audiostreamplayers (for non oneshot sounds) or strings -> audiostreams. 
	# you can mix n match the contents of the dict because we're using a dynamically types language :D 
	sound_effects = {
		SE_xp_earned:SE_xp_earned_node,
		SE_level_up:SE_level_up_node,
		SE_shoot:SE_shoot_node,
		SE_pinky_shoot:SE_pinky_shoot_node,
		SE_middle_hit:SE_middle_hit_node,
		
		SE_ability_thumb:SE_ability_thumb_node,
		SE_ability_index:SE_ability_index_node,
		SE_ability_pinky:SE_ability_pinky_node,
		SE_ability_middle:SE_ability_middle_node,
		SE_ability_ring:SE_ability_ring_node,
	}
	
	for i in sound_effects.keys():
		if sound_effects[i] is AudioStreamPlayer or sound_effects[i] is AudioStreamPlayer3D: # if it's the NODE add it as the child # FIXME if the SE_..._node's type changes this will break :D
			audio_manager.add_child(sound_effects[i])
			audio_manager.sound_effects[i] = sound_effects[i] # add the element to the dict in either case
		elif sound_effects[i] is AudioStream:
			audio_manager.oneshot_sound_effects[i] = sound_effects[i]
	
	# audio signal
	self.sound_effect_signal_start.connect(audio_manager.play_sfx)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	tick += 1
	
	# Over time, XP degrades
	if max_level_timer <= 0.0: # this var is set to max_level_decay_timer when the weapon reaches max level
		# only decrease xp if this timer isn't counting down (meaning we haven't reached max level in the last max_level_decay_timer seconds)
		decrease_xp(delta)
		
		if tick % 100 == 0 and weapon_usage - expected_usage_rate > 0:
			weapon_usage -= expected_usage_rate
		if current_ability_cooldown > 0.0:
			current_ability_cooldown -= delta
	else:
		max_level_timer = clampf(max_level_timer - delta, 0.0, max_level_decay_timer) # countdown timer. doing this with a scenetreetimer would be more efficient

func use_ability() -> bool:
	if current_ability_cooldown > 0.0:
		return false
	
	if self is WeaponThumb:
		sound_effect_signal_start.emit(SE_ability_thumb)
	if self is WeaponIndex:
		sound_effect_signal_start.emit(SE_ability_index)
	if self is WeaponMiddle:
		sound_effect_signal_start.emit(SE_ability_middle)
	if self is WeaponPinky:
		sound_effect_signal_start.emit(SE_ability_pinky)
	if self is WeaponRing:
		sound_effect_signal_start.emit(SE_ability_ring)
	
	current_ability_cooldown = ability_cooldown
	#if depleted_material:
		#$MeshInstance3D.mesh.material = depleted_material.duplicate()
		#var depleted_tween = get_tree().create_tween()
		#depleted_tween.set_ease(Tween.EASE_IN_OUT)
		##depleted_tween.set_trans(Tween.TRANS_CUBIC)
		##depleted_tween.tween_property($MeshInstance3D.mesh.material, "albedo_color", normal_material.albedo_color, ability_cooldown)
		#depleted_tween.finished.connect(_on_depleted_tween_finish)
	#else:
		#print("%s set my depleted material for visual indication of ability cooldown :)" % self)
	
	# send signal
	#print("sending signal: " + str(ability_cooldown))
	emit_signal("send_ui_ability_time", ability_cooldown)

	var recharge_color = $MeshInstance3D.mesh.material.albedo_color
	$MeshInstance3D.mesh.material.albedo_color = depleted_color # set my color to the color of the depleted material
	var depleted_tween = get_tree().create_tween()
	depleted_tween.set_ease(Tween.EASE_IN_OUT)
	depleted_tween.tween_property($MeshInstance3D.mesh.material, "albedo_color", recharge_color, ability_cooldown)
	depleted_tween.finished.connect(_on_depleted_tween_finish)
	
	used_ability.emit()
	
	return true

# shoot a bullet from the weapon
func shoot(from_pos: Vector3, direction: Vector3, velocity: Vector3 = Vector3.ZERO) -> void:
	# Weapon firerate increases as level increases
	shoot_timer.wait_time = 1 / (fire_rate * (1 + level * fire_rate_scaling))
	shoot_timer.timeout.connect(func(): can_shoot = true)
	if not can_shoot or not weapon_manager.isCanUseWeapon():
		#print("cant shoot")
		return
	
	# sound effect
	if self is WeaponMiddle:
		if not sound_effects[SE_middle_hit].is_playing():
			#print("playing: ")
			sound_effect_signal_start.emit(SE_shoot)
	elif self is WeaponPinky:
		sound_effect_signal_start.emit(SE_pinky_shoot)
	else:
		sound_effect_signal_start.emit(SE_shoot)
	
	shoot_timer.start()
	if weapon_usage < expected_usage*1.5:
		weapon_usage += 1
	#print(name + ": " + str(weapon_usage))
	can_shoot = false
	#var look_direction = ($BulletEmergePoint.global_position - global_position).normalized()# there's zefinitely a better way to get the look direction
	if on_shoot != null: on_shoot.emit(from_pos, direction, velocity) 
	else: print("hello from weapon_base! you probably forgot to set the on_shoot signal on the inheritor of this script :3")
	if get_node_or_null("TraumaCauser"):
		$TraumaCauser.cause_trauma_conditional(trauma_amount)
		var weapon_manager = get_parent()
		if weapon_manager.is_in_group("WeaponManager"):
			weapon_manager.cause_recoil_clamped(recoil_amount, recoil_limit)

#for projectile ability
func ability_shoot(from_pos: Vector3, direction: Vector3, velocity: Vector3 = Vector3.ZERO) -> void:
	#if not can_shoot or not weapon_manager.isCanUseWeapon():
	if not weapon_manager.isCanUseWeapon():
		return
	
	shoot_timer.start()
	can_shoot = false
	
	if on_ability_shoot != null: on_ability_shoot.emit(from_pos, direction, velocity) 
	else: print("hello from weapon_base! you probably forgot to set the on_shoot signal on the inheritor of this script :3")

func cease_fire():
	if on_ceasefire != null: on_ceasefire.emit() 
	else: print("hello from weapon_base! you probably forgot to set the on_ceasefire signal on the inheritor of this script :3")

func add_xp(xp: float):
	var experience_rate: float
	experience_change.emit()
	
	if self is WeaponMiddle:
		if not sound_effects[SE_xp_earned].is_playing():
			sound_effect_signal_start.emit(SE_xp_earned)
	else:
		sound_effect_signal_start.emit(SE_xp_earned)
	
	# XP gets harder to increase as level increases (XP cap at level 10)
	experience_rate = xp* xp_gain_multiplier *(float(expected_usage)/(expected_usage_rate+weapon_usage))
	if level < max_level:
		experience += experience_rate
		level_experience += experience_rate
	
	# If XP is high enough, weapon gets upgraded
	if level_experience >= upgrade_quota and level < max_level:
		increase_level()
		sound_effect_signal_start.emit(SE_level_up)
	
	if level == max_level:
		# meowy
		# start a timer that locks level decreasing for a certain amount of time
		max_level_timer = max_level_decay_timer
		emit_signal("send_ui_xp_max_level")
	else:
		# send xp to ui
		emit_signal("send_ui_xp_updated", level_experience)

func set_level(new_level: int):
	experience = level*upgrade_quota
	level = new_level

func decrease_xp(delta: float):
	#if level_experience > 0.0:
	experience_change.emit()
	
	# evil
	if level_experience >= upgrade_quota and level < max_level:
		increase_level()
	
	level_experience -= degradation * delta
	#else:
		#experience_change.emit()
		#level_experience = 0.0
	
	# dont want to accumulate negative level xp
	if level_experience < 0 and level == 1:
		level_experience = 0.0

	# If XP degrades enough, weapon gets downgraded
	if level_experience < 0 and level > 1: # dont downgrade past level 1
		decrease_level()
	
	# send xp to ui
	emit_signal("send_ui_xp_updated", level_experience)

func increase_level():
	level += 1
	level_experience = (upgrade_quota - level_experience) + 0.05 * upgrade_quota # set the level xp to a little above the min level
	upgrade_quota *= 1.5
	emit_signal("send_ui_xp_level_updated", level)

func decrease_level():
	level -= 1
	upgrade_quota /= 1.5
	level_experience = upgrade_quota - 1
	emit_signal("send_ui_xp_level_updated", level)

func print_xp(name: String):
	return
	#print(name + " xp: " + str(experience))
	
func _on_depleted_tween_finish():
	if recharge_particles:
		recharge_particles.restart()
