extends CharacterBody2D

signal defeated(enemy: Node2D)
signal hit_player

@export var speed := 140.0
@export var max_health := 3

var health := 3
var target: Node2D
var _attack_timer := 0.0

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	velocity = global_position.direction_to(target.global_position) * speed
	move_and_slide()
	_attack_timer -= delta
	if _attack_timer <= 0.0 and global_position.distance_to(target.global_position) < 48.0:
		_attack_timer = 0.75
		if target.has_method("damage"):
			target.damage(1)
			hit_player.emit()

func damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		defeated.emit(self)
		queue_free()
