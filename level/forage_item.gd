class_name ForageItem extends Area2D
## Pick-up that restores player health when collected.


@export_range(1, 10, 1) var heal_amount := 1


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).forage(heal_amount)
		queue_free()
