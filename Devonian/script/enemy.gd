extends CharacterBody2D


var is_following_player =false
var player : CharacterBody2D = null
const SPEED = 150

func _physics_process(_delta):
	if is_following_player:
		var direction = (player.position - position).normalized()
		velocity = direction * SPEED
		move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	is_following_player = true
	player = body


func _on_area_2d_body_shape_exited(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	is_following_player = false
