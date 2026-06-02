extends Area2D

signal entered
signal focus_changed(active: bool)

var active := false

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	active = true
	focus_changed.emit(true)
	entered.emit()

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	active = false
	focus_changed.emit(false)
