extends Node3D
class_name WeaponBase

# misc
var bullet_emerge_point: Node3D # should be set in the parent WeaponManager

# Experience Points
@export_group("Experience & Levels")
@export var experience: float = 0
@export var level: int = 1
signal experience_change

# Quota and degradation rate is different for every weapon
@export var upgrade_quota: float = 100.0
@export var degradation: float = 1.0
var tick: int = 0

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
@export var ability_cooldown := 5.0 # default 5 seconds
var current_ability_cooldown := 0.0 # <= 0 if the ability is off cooldown
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

func _ready() -> void:
	shoot_timer.wait_time = 1/(fire_rate*level)
	shoot_timer.timeout.connect(func(): can_shoot = true)
	if ability_recharge_particles:
		recharge_particles = ability_recharge_particles.instantiate()
		add_child(recharge_particles)
		recharge_particles.draw_pass_1.surface_get_material(0).albedo_color = ability_recharge_particle_color

func _process(delta: float) -> void:
	tick += 1
	# Over time, XP degrades
	if tick % 150 == 0:
		decrease_xp()
	pass

func _physics_process(delta: float) -> void:
	if current_ability_cooldown > 0.0:
		current_ability_cooldown -= delta

func use_ability() -> bool:
	if current_ability_cooldown > 0.0:
		return false
	else:
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
	shoot_timer.wait_time = 1/(fire_rate*(1+level*0.2))
	shoot_timer.timeout.connect(func(): can_shoot = true)
	if not can_shoot or not weapon_manager.isCanUseWeapon():
		#print("cant shoot")
		return
	
	shoot_timer.start()
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
	if not can_shoot or not weapon_manager.isCanUseWeapon():
		return
	
	shoot_timer.start()
	can_shoot = false
	
	if on_ability_shoot != null: on_ability_shoot.emit(from_pos, direction, velocity) 
	else: print("hello from weapon_base! you probably forgot to set the on_shoot signal on the inheritor of this script :3")

func cease_fire():
	if on_ceasefire != null: on_ceasefire.emit() 
	else: print("hello from weapon_base! you probably forgot to set the on_ceasefire signal on the inheritor of this script :3")

func add_xp(xp: float):
	experience_change.emit()
	# XP gets harder to increase as level increases (XP cap at level 4)
	experience += xp*(4-level)
	# If XP is high enough, weapon gets upgraded
	if experience > level*upgrade_quota:
		level += 1
		#print("LEVEL UP to " + str(level))
		emit_signal("send_ui_xp_level_updated", level)
		
	
	# send xp to ui
	emit_signal("send_ui_xp_updated", experience)

func decrease_xp():
	if experience > 0.0:
		experience_change.emit()
		experience -= degradation
	else:
		experience_change.emit()
		experience = 0.0

	# If XP degrades enough, weapon gets downgraded
	if experience < (level-1)*upgrade_quota:
		level -= 1
		#print("LEVEL DOWN to " + str(level))
		emit_signal("send_ui_xp_level_updated", level)
	
	# send xp to ui
	emit_signal("send_ui_xp_updated", experience)
	
func print_xp(name: String):
	return
	#print(name + " xp: " + str(experience))
	
func _on_depleted_tween_finish():
	if recharge_particles:
		recharge_particles.restart()
