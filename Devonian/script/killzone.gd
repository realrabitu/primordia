extends Area2D


func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method(&"respawn"):
		body.call(&"respawn")
