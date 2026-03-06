extends Area2D


<<<<<<< HEAD
# Called when the node enters the scene tree for the first time.


func _on_body_entered(body): tangina mo
	body.respawn()
=======
func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method(&"respawn"):
		body.call(&"respawn")
>>>>>>> 0d47892ceece502f72b108f798841a323ba704f8
