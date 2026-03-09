extends Area2D

<<<<<<< HEAD
func _on_body_entered(_body: Node2D) -> void:
	# Killzone disabled temporarily.
	return
=======

<<<<<<< HEAD
# Called when the node enters the scene tree for the first time.


func _on_body_entered(body): tangina mo
	body.respawn()
=======
func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method(&"respawn"):
		body.call(&"respawn")
>>>>>>> 0d47892ceece502f72b108f798841a323ba704f8
>>>>>>> 977f0e04645e63f0a3c1dd75ca35a66942ff8b3a
