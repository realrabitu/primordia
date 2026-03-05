class_name Bullet extends RigidBody2D

@export_range(1, 50, 1) var damage := 1
var source_player: Player

@onready var animation_player := $AnimationPlayer as AnimationPlayer


func destroy() -> void:
	animation_player.play(&"destroy")


func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		(body as Enemy).take_damage(damage, source_player)
		destroy()
