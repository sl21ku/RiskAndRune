extends CharacterBody2D

signal shot_requested(origin: Vector2, direction: Vector2)
signal forward_shot_requested(origin: Vector2, direction: Vector2)

@export var speed := 360.0
@export var fire_interval := 0.55
@export var forward_fire_interval := 0.38

@export var limit_x := 1470.0
@export var limit_y := 1470.0

var aim_direction := Vector2.RIGHT
var health := 5
var control_enabled := true
var _fire_timer := 0.0
var _forward_fire_timer := 0.0
var _touch_active := false
var _touch_origin := Vector2.ZERO
var _touch_position := Vector2.ZERO
var _nearest_enemy: Node2D
var knockback := Vector2.ZERO
var gravity_pull := Vector2.ZERO

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
	if not control_enabled:
		velocity = Vector2.ZERO
		return
	var direction := _get_move_direction()
	if direction.length() > 0.0:
		aim_direction = direction.normalized()
	velocity = direction * speed + knockback + gravity_pull
	move_and_slide()
	global_position.x = clamp(global_position.x, -limit_x, limit_x)
	global_position.y = clamp(global_position.y, -limit_y, limit_y)
	knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	gravity_pull = Vector2.ZERO

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		var shot_direction := aim_direction
		if is_instance_valid(_nearest_enemy):
			shot_direction = global_position.direction_to(_nearest_enemy.global_position)
		shot_requested.emit(global_position, shot_direction)

	_forward_fire_timer -= delta
	if _forward_fire_timer <= 0.0:
		_forward_fire_timer = forward_fire_interval
		forward_shot_requested.emit(global_position, aim_direction)

func set_nearest_enemy(enemy: Node2D) -> void:
	_nearest_enemy = enemy

signal damaged(amount: int)

func damage(amount: int, source_position := Vector2.ZERO) -> void:
	health -= amount
	damaged.emit(amount)
	
	if source_position != Vector2.ZERO:
		var push_dir := source_position.direction_to(global_position).normalized()
		knockback = push_dir * 500.0
	
	var tween = create_tween()
	modulate = Color(8.0, 1.5, 1.5, 1.0)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		_touch_active = false
		velocity = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not control_enabled:
		return
	if event is InputEventScreenTouch:
		_touch_active = event.pressed
		_touch_origin = event.position
		_touch_position = event.position
	elif event is InputEventScreenDrag:
		_touch_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_touch_active = event.pressed
		_touch_origin = event.position
		_touch_position = event.position
	elif event is InputEventMouseMotion and _touch_active:
		_touch_position = event.position

func _get_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if _touch_active:
		direction = (_touch_position - _touch_origin) / 60.0
	return direction.limit_length(1.0)
