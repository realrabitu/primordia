class_name Crinoid
extends DevonianEnemyBase

@export_range(0.0, 1200.0, 1.0) var flee_radius := 180.0
@export_range(0.0, 500.0, 1.0) var flee_speed := 85.0
@export_range(0.0, 2000.0, 1.0) var flee_acceleration := 420.0
@export_range(0.0, 128.0, 1.0) var bottom_padding := 10.0
@export_range(0.0, 20.0, 0.1) var bottom_hold_strength := 2.2
@export_range(0.0, 64.0, 1.0) var flee_lift := 10.0
@export_range(0.0, 400.0, 1.0) var vertical_speed_limit := 120.0

var _is_fleeing := false


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	var nearby_player := _find_nearby_player()
	_is_fleeing = nearby_player != null
	_state = State.CHASING if _is_fleeing else State.WALKING

	var desired_x := 0.0
	if _is_fleeing and nearby_player != null:
		var flee_dir := signf(global_position.x - nearby_player.global_position.x)
		if is_zero_approx(flee_dir):
			flee_dir = -1.0 if sprite.flip_h else 1.0
		desired_x = flee_dir * flee_speed

	if _is_in_water and can_swim:
		velocity.x = move_toward(velocity.x, desired_x, flee_acceleration * delta)
		var desired_y := _get_bottom_hold_velocity()
		velocity.y = move_toward(velocity.y, desired_y, swim_vertical_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, flee_acceleration * delta)
		velocity.y += gravity * delta

	move_and_slide()

	if velocity.x > 0.1:
		sprite.flip_h = false
	elif velocity.x < -0.1:
		sprite.flip_h = true

	var animation := &"swim" if _is_fleeing else &"idle"
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
		if sprite.animation != animation or not sprite.is_playing():
			sprite.play(animation)


func _find_nearby_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	if flee_radius <= 0.0:
		return null

	var nearest: Node2D
	var max_distance_sq := flee_radius * flee_radius
	for node in tree.get_nodes_in_group(&"players"):
		if not (node is Node2D):
			continue
		var candidate := node as Node2D
		if not candidate.is_inside_tree():
			continue
		var distance_sq := global_position.distance_squared_to(candidate.global_position)
		if distance_sq > max_distance_sq:
			continue
		max_distance_sq = distance_sq
		nearest = candidate
	return nearest


func _get_bottom_hold_velocity() -> float:
	var active_water := _get_active_water()
	if active_water == null:
		return 0.0

	var local_surface_y := float(active_water.get("surface_pos_y"))
	var top_world := active_water.to_global(Vector2(0.0, local_surface_y)).y + swim_surface_padding

	var target_world := global_position.y
	var has_bottom := false
	var bottom_world := INF
	var water_size: Variant = active_water.get("water_size")
	if water_size is Vector2:
		has_bottom = true
		bottom_world = active_water.to_global(Vector2(0.0, local_surface_y + (water_size as Vector2).y)).y - swim_surface_padding
		target_world = bottom_world - bottom_padding
		if _is_fleeing:
			target_world -= flee_lift

	var desired_y := (target_world - global_position.y) * bottom_hold_strength
	if global_position.y <= top_world and desired_y < 0.0:
		desired_y = 0.0
	if has_bottom and global_position.y >= bottom_world and desired_y > 0.0:
		desired_y = 0.0

	return clampf(desired_y, -vertical_speed_limit, vertical_speed_limit)
