extends Area2D

@export var speed := 820.0
@export var lifetime := 1.2

var direction := Vector2.RIGHT

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func setup(start_position: Vector2, shot_direction: Vector2) -> void:
	global_position = start_position
	direction = shot_direction.normalized()
