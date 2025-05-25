extends Node3D

# stats class
class Stats:
	var time_elapsed:float = 0
	var enemy_kills: Array[int] = []
	var enemy_damage_dealt: Array[float] = []
	var enemy_damage_taken: Array[float] = []
	var enemy_xp_gain: Array[float] = []
	
	# set the length of each array
	func _init(total_enemies: int):
		for i in range(total_enemies):
			enemy_kills.push_back(0)
		for i in range(total_enemies):
			enemy_damage_dealt.push_back(0)
		for i in range(total_enemies):
			enemy_damage_taken.push_back(0)
		for i in range(total_enemies):
			enemy_xp_gain.push_back(0)
		
		#print_stats()
	
	# debug print
	func print_stats() -> void:
		print("enemy_kills: " + str(enemy_kills))
		
		print("enemy_damage_dealt: " + str(enemy_damage_dealt))
		
		print("enemy_damage_taken: " + str(enemy_damage_taken))
		
		print("enemy_xp_gain: " + str(enemy_xp_gain))
	
	# get total enemy kills
	func get_total_kills() -> int:
		var total = 0
		for i in enemy_kills:
			total += i
		return total
	
	# get total enemy kills
	func get_total_damage_dealt() -> float:
		var total = 0
		for i in enemy_damage_dealt:
			total += i
		return total
	
	# get total enemy kills
	func get_total_damage_taken() -> float:
		var total = 0
		for i in enemy_damage_taken:
			total += i
		return total
	
	# get total enemy kills
	func get_total_xp() -> float:
		var total = 0
		for i in enemy_xp_gain:
			total += i
		return total

var stats: Stats = null
var debug: bool = false

# enemy dictionary:
var enemy_dictionary: Array[String] = []

func initialize(enemy_total: int, dictionary: Array):
	stats = Stats.new(enemy_total)
	enemy_dictionary = dictionary
	#print(str(enemy_dictionary))

# update kill array
func on_recieve_enemy_kill(enemy: String):
	#print("stat enemy kill: " + str(enemy))
	#return
	
	# check if the recieved enemy is inside of the dictionary
	var count: int = 0
	for i in enemy_dictionary:
		if enemy == i:
			stats.enemy_kills[count] += 1
			if debug:
				print("kill check: " + str(enemy) + ", " + str(stats.enemy_kills))
			return
		count += 1
	
	print("enemy_stats.gd: recieved killed enemy not in dictionary! " + str(enemy))

# update enemy damage dealt array
func on_recieve_enemy_damage_dealt(enemy: String, damage: float):
	#print("stat enemy damage dealt: " + str(enemy) + ", " + str(damage))
	#return
	
	# check if the recieved enemy is inside of the dictionary
	var count: int = 0
	for i in enemy_dictionary:
		if enemy == i:
			stats.enemy_damage_dealt[count] += damage
			if debug:
				print("enemy damage dealt check: " + str(enemy) + ", " + str(stats.enemy_damage_dealt))
			return
		count += 1
	
	print("enemy_stats.gd: recieved damage dealt enemy not in dictionary! " + str(enemy))

# update enemy damage taken array
func on_recieve_enemy_damage_taken(enemy: String, damage: float):
	#print("stat enemy damage taken: " + str(enemy) + ", " + str(damage))
	#return
	
	# check if the recieved enemy is inside of the dictionary
	var count: int = 0
	for i in enemy_dictionary:
		if enemy == i:
			stats.enemy_damage_taken[count] += damage
			if debug:
				print("enemy recieved damage check: " + str(enemy) + ", " + str(stats.enemy_damage_taken))
			return
		count += 1
	
	print("enemy_stats.gd: recieved damage taken enemy not in dictionary! " + str(enemy))

# update enemy xp array
func on_recieve_enemy_xp(enemy: String, xp: float):
	#print("stat enemy xp earned: " + str(enemy) + ", " + str(xp))
	#return
	
	# check if the recieved enemy is inside of the dictionary
	var count: int = 0
	for i in enemy_dictionary:
		if enemy == i:
			stats.enemy_xp_gain[count] += xp
			if debug:
				print("enemy xp check: " + str(enemy) + ", " + str(stats.enemy_xp_gain))
			return
		count += 1
	
	print("enemy_stats.gd: recieved xp enemy not in dictionary! " + str(enemy))
