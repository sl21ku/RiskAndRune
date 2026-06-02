extends Area2D

signal entered(destination: int)

var destination_stage := 0

func setup(destination: int) -> void:
	destination_stage = destination

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	entered.emit(destination_stage)
