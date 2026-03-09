extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal hunger_changed(current: int, max_hunger: int)
signal stamina_changed(current: int, max_stamina: int)
signal oxygen_changed(current: int, max_oxygen: int)
signal dinosaur_first_encountered(dinosaur_name: String, dinosaur_description: String)


@export var speed := 150.0
@export_range(1.0, 3.0, 0.05) var sprint_speed_multiplier := 1.45
@export_range(1, 20, 1) var max_health := 6
@export_range(1, 30, 1) var max_hunger := 10
@export_range(1.0, 300.0, 1.0) var max_stamina := 100.0
@export_range(0.1, 30.0, 0.1) var hunger_tick_interval := 1.0
@export_range(0, 10, 1) var hunger_drain_per_tick := 0
@export_range(0.1, 60.0, 0.1) var starvation_damage_interval := 10.0
@export_range(1, 10, 1) var starvation_damage := 1
@export_range(0.0, 1.0, 0.05) var hunger_min_stamina_factor := 0.15
@export_range(0.0, 2.0, 0.05) var hunger_loss_per_stamina_ratio := 0.25
@export_range(0.0, 100.0, 0.1) var stamina_regen_per_second := 12.0
@export_range(0.0, 100.0, 0.1) var sprint_stamina_drain_per_second := 16.0
@export_range(1.0, 300.0, 1.0) var max_oxygen := 100.0
@export_range(0.0, 100.0, 0.1) var oxygen_deplete_per_second := 6.0
@export_range(0.0, 100.0, 0.1) var oxygen_regen_per_second := 12.0
@export var sprint_in_air := false
@export var jump_velocity := -400.0
@export var swim_speed := 220.0
@export var swim_acceleration := 1200.0
@export var swim_descend_multiplier := 1.6
@export var swim_descend_acceleration := 2600.0
@export var swim_descend_min_instant_speed := 320.0
@export_range(0.0, 1.0, 0.05) var water_exit_boost_damping := 0.35
@export var swim_passive_sink_speed := 35.0
@export_range(0.0, 500.0, 1.0) var consume_range := 120.0
@export_range(0.0, 500.0, 1.0) var consume_vertical_tolerance := 120.0
@export_range(1, 50, 1) var attack_damage := 1
@export_range(0, 20, 1) var consume_hunger_restore := 3
@export var edible_prey_ids := PackedStringArray(["crinoids", "cephalapsis", "cephalaspis"])
@export_range(0.0, 3000.0, 1.0) var dinosaur_encounter_radius := 260.0
@export_range(0.02, 1.0, 0.01) var dinosaur_encounter_scan_interval := 0.15

 

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape := $CollisionShape2D as CollisionShape2D
var _is_in_water := false
var _water_overlaps: Array[Node2D] = []
var _is_attacking := false
var _attack_damage_pending := false
var _is_sprinting := false
var _health := 0
var _hunger := 0
var _stamina := 0.0
var _oxygen := 0.0
var _effective_max_stamina := 1.0
var _hunger_loss_accumulator := 0.0
var _hunger_tick_left := 0.0
var _starvation_damage_left := 0.0
var _encountered_dinosaur_ids: Dictionary = {}
var _dinosaur_scan_left := 0.0


func _ready() -> void:
	add_to_group("players")
	add_to_group("can_interact_with_water")
	_health = max_health
	_hunger = max_hunger
	_stamina = max_stamina
	_oxygen = max_oxygen
	_hunger_loss_accumulator = 0.0
	_hunger_tick_left = hunger_tick_interval
	_starvation_damage_left = starvation_damage_interval
	_encountered_dinosaur_ids.clear()
	_dinosaur_scan_left = 0.0
	_update_stamina_from_hunger(false)
	health_changed.emit(_health, max_health)
	hunger_changed.emit(_hunger, max_hunger)
	_emit_stamina_changed()
	oxygen_changed.emit(int(round(_oxygen)), int(round(max_oxygen)))
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("Attack"):
		animated_sprite.sprite_frames.set_animation_loop("Attack", false)
	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)


func _is_attack_just_pressed() -> bool:
	if InputMap.has_action("attack"):
		return Input.is_action_just_pressed("attack")
	return Input.is_action_just_pressed("shoot")


func _is_sprint_pressed() -> bool:
	if InputMap.has_action("sprint"):
		return Input.is_action_pressed("sprint")
	return false


func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite.animation == "Attack":
		if _attack_damage_pending:
			_try_attack_enemy()
		_attack_damage_pending = false
		_is_attacking = false


func is_in_water() -> bool:
	return _is_in_water


func is_attacking() -> bool:
	return _is_attacking


func is_sprinting() -> bool:
	return _is_sprinting


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return max_health


func get_hunger() -> int:
	return _hunger


func get_max_hunger() -> int:
	return max_hunger


func get_stamina() -> int:
	return int(round(_stamina))


func get_max_stamina() -> int:
	return int(round(_get_hunger_limited_stamina_cap()))


func get_oxygen() -> int:
	return int(round(_oxygen))


func get_max_oxygen() -> int:
	return int(round(max_oxygen))


func _is_jump_just_pressed() -> bool:
	if InputMap.has_action("jump"):
		return Input.is_action_just_pressed("jump")
	return Input.is_action_just_pressed("ui_accept")


func _is_jump_pressed() -> bool:
	if InputMap.has_action("jump"):
		return Input.is_action_pressed("jump")
	return Input.is_action_pressed("ui_accept")


func _get_move_axis() -> float:
	if InputMap.has_action("move_left") and InputMap.has_action("move_right"):
		return Input.get_axis("move_left", "move_right")
	return Input.get_axis("ui_left", "ui_right")


func _get_vertical_axis() -> float:
	var up_strength := 0.0
	var down_strength := 0.0

	# Read custom gameplay actions independently so move_down works even
	# if move_up is not defined in the input map.
	if InputMap.has_action("move_up"):
		up_strength = Input.get_action_strength("move_up")
	elif InputMap.has_action("ui_up"):
		up_strength = Input.get_action_strength("ui_up")

	if InputMap.has_action("move_down"):
		down_strength = Input.get_action_strength("move_down")
	elif InputMap.has_action("ui_down"):
		down_strength = Input.get_action_strength("ui_down")

	var axis := down_strength - up_strength

	# Let jump act as swim-up so existing input maps work.
	if _is_jump_pressed():
		axis = minf(axis, -1.0)

	return clampf(axis, -1.0, 1.0)


func _on_enter_water(_water: Node2D) -> void:
	if _water != null and not _water_overlaps.has(_water):
		_water_overlaps.append(_water)
	if _is_in_water:
		return
	_is_in_water = true
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	velocity.y *= water_exit_boost_damping
	get_tree().call_group("water_state_listener", "set_underwater_visuals", true)


func _on_exit_water(_water: Node2D) -> void:
	if _water != null:
		_water_overlaps.erase(_water)
	for i in range(_water_overlaps.size() - 1, -1, -1):
		if not is_instance_valid(_water_overlaps[i]):
			_water_overlaps.remove_at(i)
	if not _water_overlaps.is_empty():
		return
	if not _is_in_water:
		return
	_is_in_water = false
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	get_tree().call_group("water_state_listener", "set_underwater_visuals", false)


func take_damage(amount: int, impulse := Vector2.ZERO) -> void:
	if amount <= 0:
		return
	_set_health(_health - amount)
	if not impulse.is_zero_approx():
		velocity = impulse
	if _health <= 0:
		respawn()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	_set_health(_health + amount)


func restore_hunger(amount: int) -> void:
	if amount <= 0:
		return
	_set_hunger(_hunger + amount)


func restore_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_stamina(_stamina + amount)

 
func respawn():
	self.global_position = Vector2(160, 497)
	velocity = Vector2.ZERO
	_water_overlaps.clear()
	_is_in_water = false
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	get_tree().call_group("water_state_listener", "set_underwater_visuals", false)
	_set_health(max_health)
	_set_hunger(max_hunger)
	_set_stamina(max_stamina)
	_set_oxygen(max_oxygen)
	_hunger_loss_accumulator = 0.0
	_hunger_tick_left = hunger_tick_interval
	_starvation_damage_left = starvation_damage_interval
	_update_stamina_from_hunger(false)
	_dinosaur_scan_left = 0.0


func _set_health(value: int) -> void:
	var next_value := clampi(value, 0, max_health)
	if next_value == _health:
		return
	_health = next_value
	health_changed.emit(_health, max_health)


func _set_hunger(value: int) -> void:
	var previous_cap := _get_hunger_limited_stamina_cap()
	var previous_stamina := _stamina
	var next_value := clampi(value, 0, max_hunger)
	if next_value == _hunger:
		return
	_hunger = next_value
	hunger_changed.emit(_hunger, max_hunger)
	_set_stamina(minf(_stamina, _get_hunger_limited_stamina_cap()))
	var current_cap := _get_hunger_limited_stamina_cap()
	if not is_equal_approx(previous_cap, current_cap) and is_equal_approx(previous_stamina, _stamina):
		_emit_stamina_changed()


func _set_stamina(value: float) -> void:
	var next_value := clampf(value, 0.0, _effective_max_stamina)
	if is_equal_approx(next_value, _stamina):
		return
	var previous := _stamina
	_stamina = next_value
	if _stamina < previous:
		_apply_hunger_loss_from_stamina_spent(previous - _stamina)
	_emit_stamina_changed()


func _set_oxygen(value: float) -> void:
	var next_value := clampf(value, 0.0, max_oxygen)
	if is_equal_approx(next_value, _oxygen):
		return
	_oxygen = next_value
	oxygen_changed.emit(int(round(_oxygen)), int(round(max_oxygen)))


func _update_hunger(delta: float) -> void:
	if delta <= 0.0 or hunger_tick_interval <= 0.0 or hunger_drain_per_tick <= 0:
		return
	_hunger_tick_left -= delta
	while _hunger_tick_left <= 0.0:
		_set_hunger(_hunger - hunger_drain_per_tick)
		_hunger_tick_left += hunger_tick_interval


func _update_starvation(delta: float) -> void:
	if delta <= 0.0 or starvation_damage_interval <= 0.0 or starvation_damage <= 0:
		return
	if _hunger > 0:
		_starvation_damage_left = starvation_damage_interval
		return
	if _health <= 0:
		return
	_starvation_damage_left -= delta
	while _starvation_damage_left <= 0.0 and _hunger <= 0 and _health > 0:
		take_damage(starvation_damage)
		_starvation_damage_left += starvation_damage_interval


func _update_oxygen(delta: float) -> void:
	if delta <= 0.0:
		return
	if _is_in_water:
		if oxygen_regen_per_second > 0.0:
			_set_oxygen(_oxygen + oxygen_regen_per_second * delta)
		return
	if oxygen_deplete_per_second > 0.0:
		_set_oxygen(_oxygen - oxygen_deplete_per_second * delta)


func _update_sprint_state(direction: float) -> void:
	if not sprint_in_air and not is_on_floor() and not _is_in_water:
		_is_sprinting = false
		return
	if _stamina <= 0.0:
		_is_sprinting = false
		return
	if absf(direction) <= 0.1:
		_is_sprinting = false
		return
	_is_sprinting = _is_sprint_pressed()


func _update_stamina(delta: float) -> void:
	if _is_sprinting and sprint_stamina_drain_per_second > 0.0:
		if not _consume_stamina(sprint_stamina_drain_per_second * delta):
			_is_sprinting = false
		return
	if stamina_regen_per_second <= 0.0:
		return
	var regen := stamina_regen_per_second * _get_stamina_regen_factor() * delta
	if regen <= 0.0:
		return
	var hunger_regen_cap := _get_hunger_limited_stamina_cap()
	_set_stamina(minf(_stamina + regen, hunger_regen_cap))


func _consume_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if _stamina < amount:
		return false
	_set_stamina(_stamina - amount)
	return true


func _update_stamina_from_hunger(emit_if_unchanged := true) -> void:
	_effective_max_stamina = maxf(1.0, max_stamina)
	var hunger_cap := _get_hunger_limited_stamina_cap()
	var previous := _stamina
	_stamina = clampf(_stamina, 0.0, hunger_cap)
	if emit_if_unchanged or not is_equal_approx(previous, _stamina):
		_emit_stamina_changed()


func _get_hunger_ratio() -> float:
	if max_hunger <= 0:
		return 0.0
	return clampf(float(_hunger) / float(max_hunger), 0.0, 1.0)


func _get_hunger_limited_stamina_cap() -> float:
	# Keep a minimum stamina floor so low hunger doesn't hard-lock movement.
	return lerpf(_effective_max_stamina * hunger_min_stamina_factor, _effective_max_stamina, _get_hunger_ratio())


func _get_stamina_regen_factor() -> float:
	return 1.0


func _emit_stamina_changed() -> void:
	stamina_changed.emit(int(round(_stamina)), int(round(_get_hunger_limited_stamina_cap())))


func _apply_hunger_loss_from_stamina_spent(stamina_spent: float) -> void:
	if stamina_spent <= 0.0 or max_hunger <= 0 or _effective_max_stamina <= 0.0:
		return
	var hunger_loss := (stamina_spent / _effective_max_stamina) * float(max_hunger) * hunger_loss_per_stamina_ratio
	if hunger_loss <= 0.0:
		return
	_hunger_loss_accumulator += hunger_loss
	var whole_loss := int(floor(_hunger_loss_accumulator))
	if whole_loss <= 0:
		return
	_hunger_loss_accumulator -= float(whole_loss)
	_set_hunger(_hunger - whole_loss)


func _is_enemy_damageable_target(enemy: Node2D) -> bool:
	if enemy == null or not enemy.is_inside_tree() or enemy == self:
		return false
	if not enemy.has_method("take_damage"):
		return false
	if enemy.has_method("is_alive") and not bool(enemy.call("is_alive")):
		return false
	return true


func _is_enemy_edible_prey(enemy: Node2D) -> bool:
	if not _is_enemy_damageable_target(enemy):
		return false

	var prey_id := ""
	if enemy.has_method("get_dinosaur_id"):
		prey_id = String(enemy.call("get_dinosaur_id")).to_lower()
	if prey_id.is_empty():
		prey_id = enemy.name.to_lower()

	for configured_id in edible_prey_ids:
		if prey_id == String(configured_id).to_lower():
			return true
	return false


func _try_attack_enemy() -> bool:
	if consume_range <= 0.0 and consume_vertical_tolerance <= 0.0:
		return false
	var tree := get_tree()
	if tree == null:
		return false

	var nearest_enemy: Node2D
	var nearest_gap_distance_sq := INF
	for node in tree.get_nodes_in_group("enemies"):
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not _is_enemy_damageable_target(enemy):
			continue
		var gap_distance_sq := _get_prey_gap_distance_sq(enemy)
		if is_inf(gap_distance_sq):
			continue
		if gap_distance_sq > nearest_gap_distance_sq:
			continue
		nearest_gap_distance_sq = gap_distance_sq
		nearest_enemy = enemy

	if nearest_enemy == null:
		return false

	var is_edible := _is_enemy_edible_prey(nearest_enemy)
	var damage_amount := 9999 if is_edible else attack_damage
	if damage_amount <= 0:
		return false

	nearest_enemy.call("take_damage", damage_amount, self)
	if is_edible and consume_hunger_restore > 0:
		restore_hunger(consume_hunger_restore)
	return true


func _get_prey_gap_distance_sq(prey: Node2D) -> float:
	if prey == null or not prey.is_inside_tree():
		return INF

	var prey_shape := prey.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	var self_body_position := collision_shape.global_position if collision_shape != null else global_position
	var prey_body_position := prey_shape.global_position if prey_shape != null else prey.global_position
	var delta := prey_body_position - self_body_position

	var self_extents := _get_collision_half_extents(collision_shape)
	var prey_extents := _get_collision_half_extents(prey_shape)
	var horizontal_gap := absf(delta.x) - (self_extents.x + prey_extents.x)
	var vertical_gap := absf(delta.y) - (self_extents.y + prey_extents.y)

	if horizontal_gap > consume_range or vertical_gap > consume_vertical_tolerance:
		return INF

	var clamped_horizontal_gap := maxf(horizontal_gap, 0.0)
	var clamped_vertical_gap := maxf(vertical_gap, 0.0)
	return clamped_horizontal_gap * clamped_horizontal_gap + clamped_vertical_gap * clamped_vertical_gap


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


func _handle_enemy_proximity_encounters(delta: float) -> void:
	if dinosaur_encounter_radius <= 0.0:
		return
	_dinosaur_scan_left = maxf(0.0, _dinosaur_scan_left - delta)
	if _dinosaur_scan_left > 0.0:
		return
	_dinosaur_scan_left = dinosaur_encounter_scan_interval
	var radius_squared := dinosaur_encounter_radius * dinosaur_encounter_radius
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if enemy.has_method(&"is_alive") and not bool(enemy.call(&"is_alive")):
			continue
		if enemy.global_position.distance_squared_to(global_position) <= radius_squared:
			register_dinosaur_encounter(enemy)


func register_dinosaur_encounter(enemy: Node) -> void:
	if enemy == null:
		return
	if not enemy.has_method(&"get_dinosaur_id"):
		return
	var dinosaur_id := String(enemy.call(&"get_dinosaur_id")).strip_edges().to_lower()
	if dinosaur_id.is_empty() or _encountered_dinosaur_ids.has(dinosaur_id):
		return
	_encountered_dinosaur_ids[dinosaur_id] = true
	var dinosaur_name := String(enemy.call(&"get_dinosaur_name")) if enemy.has_method(&"get_dinosaur_name") else "Unknown Creature"
	var dinosaur_description := String(enemy.call(&"get_dinosaur_description")) if enemy.has_method(&"get_dinosaur_description") else "%s encountered." % dinosaur_name
	dinosaur_first_encountered.emit(dinosaur_name, dinosaur_description)

func _physics_process(delta):
	var direction = _get_move_axis()
	_update_hunger(delta)
	_update_starvation(delta)
	_update_oxygen(delta)
	_update_sprint_state(direction)
	_update_stamina(delta)
	var speed_multiplier := sprint_speed_multiplier if _is_sprinting else 1.0
	if _is_attack_just_pressed():
		if not _is_attacking and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("Attack"):
			_attack_damage_pending = true
			_is_attacking = true
			animated_sprite.play("Attack")

	if _is_in_water:
		var current_swim_speed := swim_speed * speed_multiplier
		velocity.x = move_toward(velocity.x, direction * current_swim_speed, swim_acceleration * delta)
		var vertical_axis := _get_vertical_axis()
		if vertical_axis > 0.01:
			var descend_target_speed := vertical_axis * current_swim_speed * swim_descend_multiplier
			velocity.y = move_toward(velocity.y, descend_target_speed, swim_descend_acceleration * delta)
			# Give dive input immediate bite so descending doesn't feel sluggish.
			if velocity.y < swim_descend_min_instant_speed:
				velocity.y = swim_descend_min_instant_speed
		elif vertical_axis < -0.01:
			var ascend_target_speed := vertical_axis * current_swim_speed
			velocity.y = move_toward(velocity.y, ascend_target_speed, swim_acceleration * delta)
		else:
			# Small downward drift keeps the character from hovering at the surface.
			velocity.y = move_toward(velocity.y, swim_passive_sink_speed, swim_acceleration * delta)
	else:
		# Add gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if _is_jump_just_pressed() and is_on_floor():
			velocity.y = jump_velocity

		# Handle ground movement/deceleration.
		if direction:
			velocity.x = direction * speed * speed_multiplier
		else:
			velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	if _is_attacking:
		if absf(direction) > 0.01:
			animated_sprite.flip_h = direction < 0
	elif _is_in_water and (absf(direction) > 0.01 or absf(velocity.y) > 10.0):
		animated_sprite.play("Swim")
		if absf(direction) > 0.01:
			animated_sprite.flip_h = direction < 0
	elif direction:
		animated_sprite.play("Walk")
		animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.play("Idle")

	move_and_slide()
	_handle_enemy_proximity_encounters(delta)
