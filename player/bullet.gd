class_name Bullet extends RigidBody2D

@export_range(1, 50, 1) var damage := 1
var source_player: Node

@onready var animation_player := $AnimationPlayer as AnimationPlayer


func destroy() -> void:
	animation_player.play(&"destroy")


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group(&"enemies"):
		return
	if not body.has_method(&"take_damage"):
		return
	body.call(&"take_damage", damage, source_player)
	destroy()
