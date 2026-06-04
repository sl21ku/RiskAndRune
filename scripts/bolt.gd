extends Area2D

@export var speed := 820.0
@export var lifetime := 1.2

var direction := Vector2.RIGHT

# Custom weapon behavior properties
var custom_behavior := ""
var orbit_target: Node2D = null
var orbit_angle := 0.0
var orbit_radius := 100.0
var orbit_speed := 5.0
var piercing := false
var damaged_bodies: Array = []

var rotation_speed := 0.0

func _physics_process(delta: float) -> void:
	if custom_behavior == "orbit" and is_instance_valid(orbit_target):
		orbit_angle += orbit_speed * delta
		global_position = orbit_target.global_position + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
		rotation = orbit_angle + PI/2 # Align to tangent of orbit
	elif custom_behavior == "follow" and is_instance_valid(orbit_target):
		global_position = orbit_target.global_position
		rotation += rotation_speed * delta
	elif custom_behavior == "katana_slash" and is_instance_valid(orbit_target):
		var total_lt: float = get_meta("total_lifetime") if has_meta("total_lifetime") else 0.25
		var t = 1.0 - (lifetime / total_lt) # 0.0 to 1.0
		var current_angle = orbit_angle + lerp(-1.2, 1.2, t)
		global_position = orbit_target.global_position + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
		rotation = current_angle
	elif custom_behavior == "boomerang":
		var total_lt: float = get_meta("total_lifetime") if has_meta("total_lifetime") else 1.6
		var is_returning: bool = get_meta("returning") if has_meta("returning") else false
		
		if not is_returning and lifetime < total_lt * 0.5:
			set_meta("returning", true)
			is_returning = true
			damaged_bodies.clear()
			
		if is_returning and is_instance_valid(orbit_target):
			var to_target = orbit_target.global_position - global_position
			direction = to_target.normalized()
			global_position += direction * (speed * 1.25) * delta
			if to_target.length() < 20.0:
				queue_free()
		else:
			global_position += direction * speed * delta
		
		rotation += rotation_speed * delta
	elif custom_behavior == "hyper_beam" and is_instance_valid(orbit_target):
		global_position = orbit_target.global_position
		rotation = direction.angle()
		scale.y = 0.9 + randf() * 0.2
	elif custom_behavior == "bombardment_strike":
		if not has_meta("exploded") and lifetime <= 0.2:
			set_meta("exploded", true)
			for child in get_children():
				if child is CollisionShape2D:
					child.disabled = false
			if has_node("IndicatorVisuals"):
				get_node("IndicatorVisuals").visible = false
			if has_node("ExplosionVisuals"):
				get_node("ExplosionVisuals").visible = true
	elif custom_behavior == "shockwave" and is_instance_valid(orbit_target):
		global_position = orbit_target.global_position
		var max_r: float = get_meta("max_radius") if has_meta("max_radius") else 200.0
		var total_lt: float = 0.45
		var t = 1.0 - (lifetime / total_lt)
		var current_r = lerp(10.0, max_r, t)
		
		if has_node("Ring"):
			var ring = get_node("Ring") as Line2D
			ring.scale = Vector2(current_r, current_r)
			ring.default_color.a = lerp(0.7, 0.0, t)
			
		for child in get_children():
			if child is CollisionShape2D:
				var shape = child.shape
				if shape is CircleShape2D:
					shape.radius = current_r
	else:
		global_position += direction * speed * delta
		if rotation_speed != 0.0:
			rotation += rotation_speed * delta
		else:
			rotation = direction.angle()
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func setup(start_position: Vector2, shot_direction: Vector2) -> void:
	global_position = start_position
	direction = shot_direction.normalized()
