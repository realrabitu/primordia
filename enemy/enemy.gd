class_name Enemy extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal slain(killer: Node, xp_reward: int)


enum State {
	WALKING,
	CHASING,
	ATTACKING,
	DEAD,
}

@export_range(1.0, 500.0, 1.0) var walk_speed := 22.0
@export_range(1.0, 800.0, 1.0) var chase_speed := 36.0
@export_range(-2000.0, -50.0, 1.0) var jump_velocity := -360.0
@export_range(0.0, 3.0, 0.05) var jump_cooldown := 0.8
@export_range(0.0, 1.0, 0.01) var turn_cooldown := 0.2
@export_range(0.0, 1200.0, 1.0) var detection_radius := 240.0
@export_range(0.0, 1600.0, 1.0) var disengage_radius := 320.0
@export_range(0.0, 10.0, 0.05) var forget_delay := 1.2
@export_range(0.02, 1.0, 0.01) var target_update_interval := 0.08
@export_range(1, 50, 1) var max_health := 1
@export_range(1, 10, 1) var contact_damage := 1
@export_range(0.0, 500.0, 1.0) var attack_radius := 10.0
@export_range(0.0, 800.0, 1.0) var attack_vertical_tolerance := 24.0
@export_range(0.0, 5.0, 0.05) var attack_cooldown := 0.8
@export_range(0.0, 1500.0, 1.0) var attack_knockback_x := 320.0
@export_range(-1500.0, 0.0, 1.0) var attack_knockback_y := -260.0
@export_range(0, 1000, 1) var xp_reward := 10
@export var is_aggressive := true
@export var is_passive := false
<<<<<<< HEAD
=======
@export var dinosaur_id := ""
@export var dinosaur_name := ""
@export_multiline var dinosaur_description := ""
>>>>>>> 0d47892ceece502f72b108f798841a323ba704f8

const PLAYER_GROUP: StringName = &"players"

var _state := State.WALKING
var _health := 1
var _target: Node2D
var _last_damage_source: Node
var _forget_time_left := 0.0
var _attack_cooldown_left := 0.0
var _jump_cooldown_left := 0.0
var _turn_cooldown_left := 0.0
var _patrol_direction := 1.0
var _target_update_left := 0.0

@onready var gravity: int = ProjectSettings.get("physics/2d/default_gravity")
@onready var platform_detector := $PlatformDetector as RayCast2D
@onready var floor_detector_left := $FloorDetectorLeft as RayCast2D
@onready var floor_detector_right := $FloorDetectorRight as RayCast2D
@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var collision_shape := $CollisionShape2D as CollisionShape2D
@onready var explosion := $Explosion as CPUParticles2D
@onready var hit_sound := $Hit as AudioStreamPlayer2D
@onready var explode_sound := $Explode as AudioStreamPlayer2D


func _ready() -> void:
	add_to_group(&"enemies")
	_health = max_health
	_patrol_direction = -1.0 if walk_speed < 0.0 else 1.0
	_target_update_left = (float(get_instance_id() % 17) / 17.0) * target_update_interval
	_refresh_passive_collision_exceptions()
	health_changed.emit(_health, max_health)


func _physics_process(delta: float) -> void:
	var move_direction := 0.0

	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	if _jump_cooldown_left > 0.0:
		_jump_cooldown_left = maxf(0.0, _jump_cooldown_left - delta)
	if _turn_cooldown_left > 0.0:
		_turn_cooldown_left = maxf(0.0, _turn_cooldown_left - delta)

	if _state != State.DEAD:
		_target_update_left = maxf(0.0, _target_update_left - delta)
		if _target_update_left <= 0.0:
			_target_update_left = target_update_interval
			_update_target(delta)
		if _state == State.CHASING and _target != null:
			var direction := signf((_target as Node2D).global_position.x - global_position.x)
			if is_zero_approx(direction):
				direction = signf(velocity.x)
				if is_zero_approx(direction):
					direction = 1.0
			move_direction = direction
			if is_on_floor() and _is_edge_ahead(move_direction):
				velocity.x = 0.0
				move_direction = 0.0
			else:
				velocity.x = direction * chase_speed
		elif _state == State.WALKING:
			move_direction = _patrol_direction
			if is_on_floor() and _can_turn() and _is_edge_ahead(move_direction):
				_flip_patrol_direction()
				move_direction = _patrol_direction

			velocity.x = move_direction * absf(walk_speed)
		elif _state == State.ATTACKING:
			velocity.x = 0.0
			_try_attack_target()
	else:
		velocity.x = 0.0

	velocity.y += gravity * delta

	move_and_slide()

	if (_state == State.CHASING or _state == State.WALKING) and _is_blocked_by_wall(move_direction):
		if not _try_jump(move_direction) and _state == State.WALKING:
			if _can_turn():
				_flip_patrol_direction()
				velocity.x = _patrol_direction * absf(walk_speed)

	if velocity.x > 0.0:
		sprite.flip_h = false
	elif velocity.x < 0.0:
		sprite.flip_h = true

	var animation := get_new_animation()
	if not animation.is_empty() and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
		if sprite.animation != animation or not sprite.is_playing():
			sprite.play(animation)


func destroy() -> void:
	take_damage(_health)


func take_damage(amount := 1, source: Node = null) -> void:
	if _state == State.DEAD:
		return
	if source != null:
		_last_damage_source = source
	_health -= amount
	health_changed.emit(maxi(_health, 0), max_health)
	if _health > 0:
		hit_sound.play()
		return
	_state = State.DEAD
	velocity = Vector2.ZERO
	slain.emit(_last_damage_source, xp_reward)
	_start_death_sequence()


func is_alive() -> bool:
	return _state != State.DEAD


func get_contact_damage() -> int:
	if is_passive:
		return 0
	return contact_damage


func can_attack() -> bool:
	return _state != State.DEAD and _attack_cooldown_left <= 0.0 and is_aggressive and not is_passive and contact_damage > 0


func get_dinosaur_id() -> String:
	if not dinosaur_id.is_empty():
		return dinosaur_id
	if not scene_file_path.is_empty():
		return scene_file_path.get_file().get_basename().to_lower()
	var inferred_id := _infer_dinosaur_id_from_sprite()
	if not inferred_id.is_empty():
		return inferred_id
	return name.to_lower().strip_edges()


func get_dinosaur_name() -> String:
	if not dinosaur_name.is_empty():
		return dinosaur_name
	var fallback_id := get_dinosaur_id()
	if fallback_id.is_empty():
		return "Unknown Dinosaur"
	var words := fallback_id.replace("_", " ").replace("-", " ").split(" ", false)
	for index in words.size():
		words[index] = words[index].capitalize()
	return " ".join(words)


func get_dinosaur_description() -> String:
	if not dinosaur_description.is_empty():
		return dinosaur_description
	return "%s encountered." % get_dinosaur_name()


func _infer_dinosaur_id_from_sprite() -> String:
	if sprite == null or sprite.sprite_frames == null:
		return ""
	var animation_names := sprite.sprite_frames.get_animation_names()
	for animation_name in animation_names:
		var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
		if frame_count <= 0:
			continue
		var texture := sprite.sprite_frames.get_frame_texture(animation_name, 0)
		if texture == null:
			continue
		var texture_path := texture.resource_path
		if texture_path.is_empty():
			continue
		var folder_name := texture_path.get_base_dir().get_file().to_lower()
		if folder_name.is_empty():
			continue
		if folder_name.contains("_"):
			folder_name = folder_name.split("_", false)[0]
		return folder_name
	return ""


func try_attack_player(player: Node, impulse := Vector2.ZERO) -> bool:
	if player == null or not player.is_inside_tree():
		return false
	if not player.is_in_group(PLAYER_GROUP):
		return false
	if not player.has_method(&"take_damage"):
		return false
	if not can_attack():
		return false
	player.call(&"take_damage", contact_damage, impulse, true)
	_attack_cooldown_left = attack_cooldown
	return true


func get_new_animation() -> StringName:
	var animation_new: StringName
	if _state == State.ATTACKING:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"attack"):
			animation_new = &"attack"
		else:
			animation_new = &"idle"
	elif _state == State.WALKING or _state == State.CHASING:
		if velocity.x == 0:
			animation_new = &"idle"
		else:
			animation_new = &"walk"
	else:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"death"):
			animation_new = &"death"
		elif sprite.sprite_frames and sprite.sprite_frames.has_animation(&"destroy"):
			animation_new = &"destroy"
		else:
			animation_new = StringName()
	return animation_new


func _start_death_sequence() -> void:
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	collision_shape.set_deferred("disabled", true)
	platform_detector.enabled = false
	floor_detector_left.enabled = false
	floor_detector_right.enabled = false

	explode_sound.play()
	explosion.restart()
	explosion.emitting = true

	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"death"):
		sprite.play(&"death")
		if not sprite.animation_finished.is_connected(_on_destroy_animation_finished):
			sprite.animation_finished.connect(_on_destroy_animation_finished, CONNECT_ONE_SHOT)
		return

	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"destroy"):
		sprite.play(&"destroy")
		if not sprite.animation_finished.is_connected(_on_destroy_animation_finished):
			sprite.animation_finished.connect(_on_destroy_animation_finished, CONNECT_ONE_SHOT)
		return

	sprite.visible = false
	var timer := get_tree().create_timer(explosion.lifetime)
	timer.timeout.connect(_on_death_timeout, CONNECT_ONE_SHOT)


func _on_destroy_animation_finished() -> void:
	queue_free()


func _on_death_timeout() -> void:
	queue_free()


func _update_target(delta: float) -> void:
	if is_passive or not is_aggressive:
<<<<<<< HEAD
=======
		_refresh_passive_collision_exceptions()
>>>>>>> 0d47892ceece502f72b108f798841a323ba704f8
		_target = null
		_forget_time_left = 0.0
		_state = State.WALKING
		return

	var contact_target := _find_contact_player()
	if contact_target != null:
		_target = contact_target
		_state = State.ATTACKING
		_forget_time_left = forget_delay
		return

	if _target != null and _target.is_inside_tree():
		if _is_target_in_attack_range(_target):
			_state = State.ATTACKING
			_forget_time_left = forget_delay
			return
		var delta_to_target := (_target as Node2D).global_position - global_position
		if delta_to_target.length_squared() <= disengage_radius * disengage_radius:
			_state = State.CHASING
			_forget_time_left = forget_delay
			return
		_forget_time_left = maxf(0.0, _forget_time_left - delta)
		if _forget_time_left > 0.0:
			_state = State.CHASING
			return

	_target = _find_nearest_player(detection_radius)
	if _target != null:
		if _is_target_in_attack_range(_target):
			_state = State.ATTACKING
		else:
			_state = State.CHASING
		_forget_time_left = forget_delay
	else:
		_state = State.WALKING


func _try_attack_target() -> void:
	if _target == null or not _target.is_inside_tree():
		return
	if not _is_target_in_attack_range(_target):
		return

	var push_direction := signf((_target as Node2D).global_position.x - global_position.x)
	if is_zero_approx(push_direction):
		push_direction = -1.0 if sprite.flip_h else 1.0
	try_attack_player(_target, Vector2(push_direction * attack_knockback_x, attack_knockback_y))


func _is_target_in_attack_range(target: Node2D) -> bool:
	if target == null or not target.is_inside_tree():
		return false
	if attack_radius <= 0.0:
		return false
	var enemy_body_position := collision_shape.global_position if collision_shape != null else global_position
	var target_shape := target.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	var target_body_position := target_shape.global_position if target_shape != null else target.global_position
	var delta := target_body_position - enemy_body_position
	var enemy_extents := _get_collision_half_extents(collision_shape)
	var target_extents := _get_collision_half_extents(target_shape)
	var combined_half_width := enemy_extents.x + target_extents.x
	var combined_half_height := enemy_extents.y + target_extents.y
	var horizontal_gap := absf(delta.x) - combined_half_width
	var vertical_gap := absf(delta.y) - combined_half_height
	return horizontal_gap <= attack_radius and vertical_gap <= attack_vertical_tolerance


func _get_collision_half_extents(shape_node: CollisionShape2D) -> Vector2:
	if shape_node == null or shape_node.shape == null:
		return Vector2.ZERO
	var shape := shape_node.shape
	var local_half_extents := Vector2.ZERO
	if shape is CircleShape2D:
		var radius := (shape as CircleShape2D).radius
		local_half_extents = Vector2(radius, radius)
	elif shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		local_half_extents = Vector2(capsule.radius, maxf(capsule.radius, capsule.height * 0.5))
	elif shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		local_half_extents = rectangle.size * 0.5
	else:
		return Vector2.ZERO

	var scale_value := shape_node.global_scale
	local_half_extents.x *= absf(scale_value.x)
	local_half_extents.y *= absf(scale_value.y)

	var angle := shape_node.global_rotation
	var cos_theta := absf(cos(angle))
	var sin_theta := absf(sin(angle))
	return Vector2(
		cos_theta * local_half_extents.x + sin_theta * local_half_extents.y,
		sin_theta * local_half_extents.x + cos_theta * local_half_extents.y
	)


func _find_nearest_player(max_distance: float) -> Node2D:
	if max_distance <= 0.0:
		return null
	var tree := get_tree()
	if tree == null:
		return null

	var nearest_player: Node2D
	var max_distance_squared := max_distance * max_distance
	for node in tree.get_nodes_in_group(PLAYER_GROUP):
		if not (node is Node2D):
			continue
		var player := node as Node2D
		if not player.is_inside_tree():
			continue
		var distance_squared := global_position.distance_squared_to(player.global_position)
		if distance_squared <= max_distance_squared:
			max_distance_squared = distance_squared
			nearest_player = player

	return nearest_player


func _find_contact_player() -> Node2D:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node2D and (collider as Node2D).is_in_group(PLAYER_GROUP):
			var player := collider as Node2D
			if player.is_inside_tree():
				return player
	return null


func _try_jump(move_direction: float) -> bool:
	if jump_velocity >= 0.0:
		return false
	if _jump_cooldown_left > 0.0:
		return false
	if not is_on_floor():
		return false
	if is_zero_approx(signf(move_direction)):
		return false

	velocity.y = jump_velocity
	_jump_cooldown_left = jump_cooldown
	return true


func _is_blocked_by_wall(move_direction: float) -> bool:
	var direction := signf(move_direction)
	if is_zero_approx(direction):
		return false
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var normal := collision.get_normal()
		if signf(normal.x) == -direction and absf(normal.x) > 0.3:
			return true
	return false


func _is_edge_ahead(move_direction: float) -> bool:
	if not is_on_floor():
		return false
	var direction := signf(move_direction)
	if is_zero_approx(direction):
		return false
	var floor_detector: RayCast2D = floor_detector_right if direction > 0.0 else floor_detector_left
	if floor_detector != null:
		floor_detector.force_raycast_update()
		if floor_detector.is_colliding():
			return false

	# Fallback probe based on body bounds keeps patrol stable even if detector nodes are misaligned.
	return not _has_ground_ahead(direction)


func _has_ground_ahead(direction: float) -> bool:
	var body_extents := _get_collision_half_extents(collision_shape)
	if body_extents == Vector2.ZERO:
		return true

	var body_center := collision_shape.global_position if collision_shape != null else global_position
	var forward_distance := body_extents.x + 6.0
	var ray_start := body_center + Vector2(direction * forward_distance, body_extents.y - 2.0)
	var ray_end := ray_start + Vector2(0.0, 20.0)

	var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = collision_mask
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty()


func _can_turn() -> bool:
	return _turn_cooldown_left <= 0.0


func _flip_patrol_direction() -> void:
	_patrol_direction = -_patrol_direction
	_turn_cooldown_left = turn_cooldown


func _refresh_passive_collision_exceptions() -> void:
	if not is_passive:
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(PLAYER_GROUP):
		if not (node is PhysicsBody2D):
			continue
		var player_body := node as PhysicsBody2D
		if player_body == null:
			continue
		add_collision_exception_with(player_body)
		player_body.add_collision_exception_with(self)
