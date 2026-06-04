extends CharacterBody2D

signal defeated(enemy: Node2D)
signal hit_player
signal shot_requested(origin: Vector2, direction: Vector2, damage: int, color: Color, size: float, speed: float, lifetime: float, symbol: String)

@export var speed := 140.0
@export var max_health := 3

var enemy_type := "A"
var health := 3
var target: Node2D
var _attack_timer := 0.0

# Special timers and states for unique types
var _special_timer := 0.0
var _is_charging := false
var _charge_dir := Vector2.ZERO
var _stealth_active := false
var knockback := Vector2.ZERO

func _ready() -> void:
	health = max_health
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func setup(type: String) -> void:
	enemy_type = type
	_is_charging = false
	_stealth_active = false
	modulate.a = 1.0 # Reset transparency
	
	match enemy_type:
		"A":
			max_health = 3
			speed = 140.0
		"B":
			max_health = 2
			speed = 220.0
		"C":
			max_health = 8
			speed = 90.0
			_special_timer = randf_range(0.5, 1.5) # Medium-range ice nova timer
		"E":
			max_health = 5
			speed = 130.0
		"F":
			max_health = 3
			speed = 150.0
			_special_timer = randf_range(0.5, 1.0) # Medium-range wind gust timer
		"G":
			max_health = 16
			speed = 60.0
		"H":
			max_health = 4
			speed = 100.0
			_special_timer = randf_range(1.0, 2.0)
		"I":
			max_health = 3
			speed = 130.0
			_special_timer = randf_range(1.0, 1.5)
		"J":
			max_health = 10
			speed = 140.0
			_special_timer = randf_range(0.8, 1.2)
		"D":
			max_health = 4
			speed = 110.0
			_special_timer = randf_range(0.5, 1.5)
		
		# --- BOSS TYPES ---
		"BOSS_FIELD":
			max_health = 80
			speed = 130.0
			_special_timer = 1.0
		"BOSS_CAVE":
			max_health = 150
			speed = 100.0
			_special_timer = 1.5
		"BOSS_FOREST":
			max_health = 200
			speed = 120.0
			_special_timer = 1.0
		"BOSS_DESERT":
			max_health = 300
			speed = 110.0
			_special_timer = 1.0
		"BOSS_HEAVEN":
			max_health = 300
			speed = 120.0
			_special_timer = 1.0
		"BOSS_OCEAN":
			max_health = 450
			speed = 100.0
			_special_timer = 1.0
		"BOSS_HELL":
			max_health = 550
			speed = 110.0
			_special_timer = 1.0
		"BOSS_SPACE":
			max_health = 800
			speed = 130.0
			_special_timer = 1.0
			
	health = max_health

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
		
	var to_target = target.global_position - global_position
	var dist = to_target.length()
	var dir = to_target.normalized()
	
	# Movement behaviors based on enemy type
	if enemy_type == "H" or enemy_type == "BOSS_CAVE": # Charger / Cave Boss
		_special_timer -= delta
		var base_spd = 100.0 if enemy_type == "BOSS_CAVE" else 100.0
		var charge_spd = 380.0 if enemy_type == "BOSS_CAVE" else 350.0
		var charge_dur = 0.8 if enemy_type == "BOSS_CAVE" else 0.8
		var cooldown_dur = 1.2 if enemy_type == "BOSS_CAVE" else 2.0
		
		if _is_charging:
			if _special_timer <= 0.0:
				_is_charging = false
				_special_timer = randf_range(cooldown_dur, cooldown_dur + 1.0)
				speed = base_spd
			else:
				velocity = _charge_dir * charge_spd
		else:
			if _special_timer <= 0.0:
				_is_charging = true
				_special_timer = charge_dur
				_charge_dir = dir
				velocity = Vector2.ZERO # Stop momentarily to telegraph charge
			else:
				velocity = dir * speed
				
	elif enemy_type == "BOSS_SPACE": # Space Boss (Charge + Gravity Pull)
		# Gravity pull mechanic
		if dist < 320.0:
			var pull_force = (320.0 - dist) * 1.5
			if "gravity_pull" in target:
				target.gravity_pull -= dir * pull_force
				
		_special_timer -= delta
		if _is_charging:
			if _special_timer <= 0.0:
				_is_charging = false
				_special_timer = 1.8
				speed = 130.0
			else:
				velocity = _charge_dir * 380.0
		else:
			if _special_timer <= 0.0:
				_is_charging = true
				_special_timer = 0.8
				_charge_dir = dir
				velocity = Vector2.ZERO
			else:
				velocity = dir * speed
				
	elif enemy_type == "F": # Sinusoidal wavy movement when close
		if dist < 220.0:
			var perpendicular := Vector2(-dir.y, dir.x)
			var wave = sin(Time.get_ticks_msec() * 0.01) * 0.85
			velocity = (dir + perpendicular * wave).normalized() * speed
		else:
			velocity = dir * speed
	elif enemy_type == "I": # Stealth toggling
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 1.5
			_stealth_active = not _stealth_active
			modulate.a = 0.15 if _stealth_active else 1.0
		velocity = dir * speed
	else:
		velocity = dir * speed
		
	# Ranged / Medium-range attacks based on enemy type
	if enemy_type == "D": # Ranged single shot
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 2.0
			shot_requested.emit(global_position, dir, 1, Color(1.0, 0.3, 0.3), 12.0, 350.0, 2.0, "o")
	elif enemy_type == "J": # Ranged 3-way spread shot
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 1.8
			var angle_offset := 0.26 # Approx 15 degrees
			shot_requested.emit(global_position, dir, 1, Color(1.0, 0.3, 0.3), 12.0, 350.0, 2.0, "o")
			shot_requested.emit(global_position, dir.rotated(angle_offset), 1, Color(1.0, 0.3, 0.3), 12.0, 350.0, 2.0, "o")
			shot_requested.emit(global_position, dir.rotated(-angle_offset), 1, Color(1.0, 0.3, 0.3), 12.0, 350.0, 2.0, "o")
	elif enemy_type == "C": # Medium-range ice nova
		_special_timer -= delta
		if dist < 250.0 and _special_timer <= 0.0:
			_special_timer = 2.5
			# 8-way burst of short range ice stars
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				shot_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 1, Color(0.4, 0.6, 1.0), 10.0, 220.0, 0.7, "*")
	elif enemy_type == "F": # Medium-range wind gust when close
		_special_timer -= delta
		if dist < 220.0 and _special_timer <= 0.0:
			_special_timer = 1.5
			shot_requested.emit(global_position, dir, 1, Color(0.4, 0.9, 0.9), 8.0, 550.0, 0.4, ">")
			
	# --- BOSS SPECIAL ATTACKS ---
	elif enemy_type == "BOSS_FIELD": # 8-way nova burst
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 1.5
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				shot_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 1, Color(1.0, 0.2, 0.2), 14.0, 300.0, 2.5, "x")
	elif enemy_type == "BOSS_FOREST": # Slow root shoot
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 2.0
			var angle_offset := 0.2
			shot_requested.emit(global_position, dir, 1, Color(0.2, 0.8, 0.2), 13.0, 320.0, 2.5, "v")
			shot_requested.emit(global_position, dir.rotated(angle_offset), 1, Color(0.2, 0.8, 0.2), 13.0, 320.0, 2.5, "v")
			shot_requested.emit(global_position, dir.rotated(-angle_offset), 1, Color(0.2, 0.8, 0.2), 13.0, 320.0, 2.5, "v")
	elif enemy_type == "BOSS_DESERT": # Sand vortexes (homing slow bullets)
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 2.4
			shot_requested.emit(global_position, dir, 1, Color(0.85, 0.75, 0.45), 18.0, 160.0, 4.0, "*")
			shot_requested.emit(global_position, dir.rotated(0.5), 1, Color(0.85, 0.75, 0.45), 18.0, 160.0, 4.0, "*")
	elif enemy_type == "BOSS_HEAVEN": # Archangel Strike (Lightning warning indicator)
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 1.8
			shot_requested.emit(target.global_position, Vector2.ZERO, 1, Color(1.0, 1.0, 0.2), 24.0, 0.0, 0.9, "X")
	elif enemy_type == "BOSS_OCEAN": # Giant laser beams (Warning indicators + Beams)
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 2.2
			shot_requested.emit(global_position, dir, 1, Color(0.2, 0.5, 1.0), 10.0, 0.0, 0.8, "-")
			shot_requested.emit(global_position, dir.rotated(0.3), 1, Color(0.2, 0.5, 1.0), 10.0, 0.0, 0.8, "-")
			shot_requested.emit(global_position, dir.rotated(-0.3), 1, Color(0.2, 0.5, 1.0), 10.0, 0.0, 0.8, "-")
	elif enemy_type == "BOSS_HELL": # Bullet hell rings (12-way)
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = 1.4
			for i in range(12):
				var angle := TAU * float(i) / 12.0
				shot_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 1, Color(0.9, 0.1, 0.1), 12.0, 280.0, 2.5, "o")
	elif enemy_type == "BOSS_SPACE": # Circular space waves
		_special_timer -= delta
		if _special_timer <= 0.0 and not _is_charging:
			_special_timer = 2.0
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				shot_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 1, Color(0.7, 0.1, 0.9), 14.0, 260.0, 3.0, "O")

	velocity += knockback
	move_and_slide()
	knockback = knockback.move_toward(Vector2.ZERO, 800.0 * delta)
	
	# Melee attack
	_attack_timer -= delta
	var melee_dist := 76.0 if (enemy_type == "G" or enemy_type.begins_with("BOSS_")) else 64.0
	if _attack_timer <= 0.0 and dist < melee_dist:
		_attack_timer = 0.75
		if target.has_method("damage"):
			var is_boss := enemy_type.begins_with("BOSS_")
			var dmg := 2 if (enemy_type == "G" or is_boss) else 1
			target.damage(dmg, global_position)
			hit_player.emit()

func damage(amount: int) -> void:
	health -= amount
	
	if health > 0:
		var tween = create_tween()
		modulate = Color(8.0, 1.5, 1.5, 1.0)
		var original_modulate = Color(1.0, 1.0, 1.0, modulate.a)
		tween.tween_property(self, "modulate", original_modulate, 0.12)
		
	if health <= 0:
		defeated.emit(self)
		queue_free()

func apply_knockback(force: Vector2) -> void:
	knockback += force
