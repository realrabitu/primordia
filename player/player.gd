class_name Player
extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal hunger_changed(current: int, max_hunger: int)
signal stamina_changed(current: int, max_stamina: int)
signal xp_changed(current: int, required: int)
signal level_changed(level: int)
signal dinosaur_first_encountered(dinosaur_name: String, dinosaur_description: String)

@export var walk_speed: float = 350.0
var ACCELERATION_SPEED = walk_speed * 6.0
const JUMP_VELOCITY = -725.0
## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY = 700

## The player listens for input actions appended with this suffix.[br]
## Keep empty for the default single-player input map.
@export var action_suffix := ""
@export_range(1, 20, 1) var max_health := 6
@export_range(1, 20, 1) var max_hunger := 8
@export_range(0.1, 30.0, 0.1) var hunger_tick_interval := 1.0
@export_range(1, 10, 1) var hunger_drain_per_tick := 1
@export_range(0.1, 30.0, 0.1) var starvation_damage_interval := 2.0
@export_range(1, 10, 1) var starvation_damage := 1
@export_range(0.1, 30.0, 0.1) var full_hunger_regen_interval := 4.0
@export_range(1, 10, 1) var full_hunger_regen_amount := 1
@export_range(0, 10, 1) var full_hunger_regen_hunger_cost := 1
@export_range(0.0, 2000.0, 1.0) var fall_damage_start_speed := 560.0
@export_range(1.0, 1000.0, 1.0) var fall_damage_step := 90.0
@export_range(1, 20, 1) var max_fall_damage := 4
@export_range(0.0, 5000.0, 1.0) var fall_damage_min_distance := 340.0
@export_range(0.0, 3.0, 0.05) var contact_damage_cooldown := 0.7
@export var hazard_tile_custom_data_key: StringName = &"instant_kill"
@export var hazard_layer_group: StringName = &"instant_kill_tiles"
@export var debug_god_mode := false
@export_range(1.0, 10.0, 0.1) var god_mode_speed_multiplier := 3.0
@export_range(1, 20, 1) var attack_damage := 1
@export_range(0.0, 400.0, 1.0) var attack_range := 90.0
@export_range(0.0, 250.0, 1.0) var attack_vertical_tolerance := 56.0
@export var attack_hit_offset := Vector2(-70.0, -13.0)
@export_range(0.0, 1.0, 0.01) var attack_hit_timing := 0.55
@export_range(0.0, 3000.0, 1.0) var dinosaur_encounter_radius := 260.0
@export_range(0.02, 1.0, 0.01) var dinosaur_encounter_scan_interval := 0.15
@export_range(0.0, 1.0, 0.05) var defend_damage_multiplier := 0.35
@export_range(0.0, 1.0, 0.05) var defend_knockback_multiplier := 0.35
@export_range(1.0, 200.0, 1.0) var defend_heat_max := 100.0
@export_range(1.0, 200.0, 1.0) var defend_heat_gain_per_second := 45.0
@export_range(1.0, 200.0, 1.0) var defend_heat_cool_per_second := 55.0
@export_range(0.0, 3.0, 0.05) var defend_heat_cool_delay := 0.45
@export_range(0.0, 5.0, 0.05) var defend_break_duration := 1.2
@export_range(0.0, 1.0, 0.01) var defend_min_hold_seconds := 0.15
@export_range(0.0, 5.0, 0.05) var defend_cooldown_duration := 0.8
@export_range(1.0, 300.0, 1.0) var max_stamina := 100.0
@export_range(0.0, 1.0, 0.05) var hunger_min_stamina_factor := 0.35
@export_range(0.0, 200.0, 1.0) var stamina_regen_per_second := 24.0
@export_range(0.0, 200.0, 1.0) var defend_stamina_drain_per_second := 28.0
@export_range(0.0, 200.0, 1.0) var attack_stamina_cost := 20.0
@export_range(1.0, 3.0, 0.05) var sprint_speed_multiplier := 1.45
@export_range(0.0, 200.0, 1.0) var sprint_stamina_drain_per_second := 10.0
@export var sprint_in_air := false
@export_range(0.0, 300.0, 1.0) var fern_interaction_radius := 72.0
@export_range(0.02, 1.0, 0.01) var fern_scan_interval := 0.1
@export_range(1, 10, 1) var eat_hunger_restore := 1
@export_range(0.0, 1.0, 0.05) var hunger_min_regen_factor := 0.2
@export_range(0.0, 2.0, 0.05) var hunger_loss_per_stamina_ratio := 0.25
@export_range(1, 2000, 1) var base_xp_to_level := 25
@export_range(1.0, 3.0, 0.05) var xp_growth_factor := 1.3
@export_range(0, 20, 1) var level_up_health_bonus := 2
@export_range(0.0, 200.0, 1.0) var level_up_stamina_bonus := 8.0
@export_range(0, 10, 1) var level_up_attack_bonus := 1

const PLAYER_GROUP: StringName = &"players"

var gravity: int = ProjectSettings.get("physics/2d/default_gravity")
@onready var platform_detector := $PlatformDetector as RayCast2D
@onready var shoot_timer := $ShootAnimation as Timer
@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var jump_sound := $Jump as AudioStreamPlayer2D
@onready var camera := $Camera as Camera2D
var _double_jump_charged := false
var _facing_direction := 1.0
var _health := 0
var _hunger := 0
var _spawn_position := Vector2.ZERO
var _damage_cooldown_left := 0.0
var _hunger_tick_left := 0.0
var _starvation_damage_left := 0.0
var _full_hunger_regen_left := 0.0
var _airborne_start_y := 0.0
var _stamina := 0.0
var _effective_max_stamina := 1.0
var _hunger_loss_accumulator := 0.0
var _is_attacking := false
var _attack_fired := false
var _attack_facing_direction := 1.0
var _is_eating := false
var _is_defending := false
var _is_sprinting := false
var _defend_hold_left := 0.0
var _defend_cooldown_left := 0.0
var _defend_requires_release := false
var _defend_heat := 0.0
var _defend_break_left := 0.0
var _defend_recovery_delay_left := 0.0
var _level := 1
var _xp := 0
var _xp_to_next := 1
var _defend_damage_accumulator := 0.0
var _encountered_dinosaur_ids: Dictionary = {}
var _is_near_fern := false
var _nearby_food_source: Node2D
var _eating_food_source: Node2D
var _eat_time_left := 0.0
var _dinosaur_scan_left := 0.0
var _fern_scan_left := 0.0
var _fern_cache_built := false
var _fern_candidates_cache: Array[Node2D] = []


func is_god_mode_enabled() -> bool:
	return debug_god_mode


func get_level() -> int:
	return _level


func _ready() -> void:
	add_to_group(PLAYER_GROUP)
	add_to_group("can_interact_with_water")
	_spawn_position = global_position
	_airborne_start_y = global_position.y
	_health = max_health
	_hunger = max_hunger
	_hunger_tick_left = hunger_tick_interval
	_starvation_damage_left = starvation_damage_interval
	_full_hunger_regen_left = full_hunger_regen_interval
	_stamina = max_stamina
	_hunger_loss_accumulator = 0.0
	_defend_cooldown_left = 0.0
	_defend_requires_release = false
	_defend_damage_accumulator = 0.0
	_xp = 0
	_level = 1
	_xp_to_next = _calculate_xp_to_next(_level)
	_encountered_dinosaur_ids.clear()
	_dinosaur_scan_left = 0.0
	_fern_scan_left = 0.0
	_fern_cache_built = false
	_fern_candidates_cache.clear()
	_update_stamina_from_hunger(false)
	health_changed.emit(_health, max_health)
	hunger_changed.emit(_hunger, max_hunger)
	_emit_stamina_changed()
	xp_changed.emit(_xp, _xp_to_next)
	level_changed.emit(_level)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("eat"):
		sprite.sprite_frames.set_animation_loop("eat", false)
	sprite.animation_finished.connect(_on_sprite_animation_finished)


func _physics_process(delta: float) -> void:
	if _is_god_mode_toggle_pressed():
		debug_god_mode = not debug_god_mode
		if debug_god_mode:
			_health = max_health
			_hunger = max_hunger
			_hunger_tick_left = hunger_tick_interval
			_starvation_damage_left = starvation_damage_interval
			_full_hunger_regen_left = full_hunger_regen_interval
			_stamina = max_stamina
			_hunger_loss_accumulator = 0.0
			_defend_cooldown_left = 0.0
			_defend_requires_release = false
			_defend_damage_accumulator = 0.0
			_update_stamina_from_hunger(false)
			health_changed.emit(_health, max_health)
			hunger_changed.emit(_hunger, max_hunger)
			_emit_stamina_changed()
		print("God mode %s for player%s" % ["enabled" if debug_god_mode else "disabled", action_suffix])

	_update_hunger(delta)

	if _damage_cooldown_left > 0.0:
		_damage_cooldown_left = maxf(0.0, _damage_cooldown_left - delta)
	if _defend_break_left > 0.0:
		_defend_break_left = maxf(0.0, _defend_break_left - delta)
	if _defend_hold_left > 0.0:
		_defend_hold_left = maxf(0.0, _defend_hold_left - delta)
	if _defend_cooldown_left > 0.0:
		_defend_cooldown_left = maxf(0.0, _defend_cooldown_left - delta)
	if _defend_recovery_delay_left > 0.0:
		_defend_recovery_delay_left = maxf(0.0, _defend_recovery_delay_left - delta)

	var was_on_floor := is_on_floor()
	var vertical_speed_before_move := velocity.y
	if was_on_floor:
		_airborne_start_y = global_position.y

	if is_on_floor():
		_double_jump_charged = true
	_update_defend_state(delta)
	_update_sprint_state()
	_update_stamina(delta)
	if not (_is_attacking or _is_defending or _is_eating) and Input.is_action_just_pressed("jump" + action_suffix):
		try_jump()
	elif not (_is_attacking or _is_defending or _is_eating) and Input.is_action_just_released("jump" + action_suffix) and velocity.y < 0.0:
		# The player let go of jump early, reduce vertical momentum.
		velocity.y *= 0.6
	# Fall.
	velocity.y = minf(TERMINAL_VELOCITY, velocity.y + gravity * delta)

	var speed_multiplier := god_mode_speed_multiplier if debug_god_mode else 1.0
	if _is_sprinting:
		speed_multiplier *= sprint_speed_multiplier
	var current_walk_speed := walk_speed * speed_multiplier
	var current_acceleration_speed : float = ACCELERATION_SPEED * speed_multiplier
	if _is_attacking or _is_defending or _is_eating:
		velocity.x = 0.0
	else:
		var direction := Input.get_axis("move_left" + action_suffix, "move_right" + action_suffix) * current_walk_speed
		velocity.x = move_toward(velocity.x, direction, current_acceleration_speed * delta)

	if not _is_attacking and not is_zero_approx(velocity.x):
		if velocity.x > 0.0:
			_facing_direction = 1.0
		else:
			_facing_direction = -1.0

	floor_stop_on_slope = not platform_detector.is_colliding()
	move_and_slide()
	if was_on_floor and not is_on_floor():
		_airborne_start_y = global_position.y
	if _handle_hazard_tile_collisions():
		return
	_apply_fall_damage_on_landing(was_on_floor, vertical_speed_before_move)
	_handle_enemy_proximity_encounters(delta)
	_handle_enemy_collisions()
	_update_fern_proximity(delta)
	if _is_eating and _has_eating_target_disappeared():
		_is_eating = false
		_eating_food_source = null
		_eat_time_left = 0.0
	elif _is_eating:
		_eat_time_left = maxf(0.0, _eat_time_left - delta)
		if _eat_time_left <= 0.0:
			_finish_eat_sequence()
		_try_finish_eat_animation()
	_try_start_eat()

	if Input.is_action_just_pressed("shoot" + action_suffix):
		_try_start_attack()

	_process_attack_shot()

	var animation := get_new_animation()
	if animation == "attack":
		sprite.flip_h = _attack_facing_direction < 0.0
	else:
		sprite.flip_h = false
	var should_restart_animation := sprite.animation != animation or (not sprite.is_playing() and not ((_is_defending and animation == "defend") or (_is_eating and animation == "eat")))
	if not animation.is_empty() and should_restart_animation:
		sprite.play(animation)
	_update_defend_animation_loop()


func is_near_fern() -> bool:
	return _is_near_fern


func _update_fern_proximity(delta: float) -> void:
	if fern_interaction_radius <= 0.0:
		_nearby_food_source = null
		_is_near_fern = false
		return

	_fern_scan_left = maxf(0.0, _fern_scan_left - delta)
	if _fern_scan_left > 0.0 and _nearby_food_source != null and is_instance_valid(_nearby_food_source):
		var current_delta := _nearby_food_source.global_position - global_position
		var radius_squared := fern_interaction_radius * fern_interaction_radius
		if current_delta.length_squared() <= radius_squared:
			if not (_nearby_food_source is CanvasItem) or (_nearby_food_source as CanvasItem).visible:
				_is_near_fern = true
				return

	_fern_scan_left = fern_scan_interval
	_nearby_food_source = _find_nearest_food_source()
	_is_near_fern = _nearby_food_source != null


func _find_nearest_food_source() -> Node2D:
	var radius_squared := fern_interaction_radius * fern_interaction_radius
	var nearest_food: Node2D
	var best_distance_squared := radius_squared
	for node in _get_fern_candidates():
		var food_node := node
		if food_node is CanvasItem and not (food_node as CanvasItem).visible:
			continue
		var delta := food_node.global_position - global_position
		var distance_squared := delta.length_squared()
		if distance_squared <= best_distance_squared:
			best_distance_squared = distance_squared
			nearest_food = food_node
	return nearest_food


func _get_fern_candidates() -> Array[Node2D]:
	var grouped := get_tree().get_nodes_in_group(&"ferns")
	if not grouped.is_empty():
		var grouped_candidates: Array[Node2D] = []
		for node in grouped:
			if node is Node2D and (node as Node2D).is_inside_tree():
				grouped_candidates.append(node as Node2D)
		return grouped_candidates

	if not _fern_cache_built:
		_build_fern_candidates_cache()

	if _fern_candidates_cache.is_empty():
		return _fern_candidates_cache

	var alive_candidates: Array[Node2D] = []
	for candidate in _fern_candidates_cache:
		if is_instance_valid(candidate) and candidate.is_inside_tree():
			alive_candidates.append(candidate)
	_fern_candidates_cache = alive_candidates
	return _fern_candidates_cache


func _build_fern_candidates_cache() -> void:
	_fern_candidates_cache.clear()
	var scene_root := get_tree().current_scene
	if scene_root == null:
		_fern_cache_built = true
		return

	var stack: Array[Node] = [scene_root]
	while not stack.is_empty():
		var node := stack.pop_back() as Node
		if _node_looks_like_food_item(node):
			_fern_candidates_cache.append(node as Node2D)
		for child in node.get_children():
			stack.append(child)
	_fern_cache_built = true


func _node_looks_like_food_item(node: Node) -> bool:
	if not (node is Node2D):
		return false

	var node_name := node.name.to_lower()
	if node_name.begins_with("fern") or node_name.begins_with("forage"):
		return true

	if node is Sprite2D:
		var node_sprite := node as Sprite2D
		if node_sprite.texture != null:
			var texture_path := node_sprite.texture.resource_path.to_lower()
			if texture_path.contains("fern") or texture_path.contains("forage"):
				return true

	return false


func get_new_animation() -> String:
	if _is_attacking and sprite.sprite_frames.has_animation("attack"):
		return "attack"
	if _is_defending and sprite.sprite_frames.has_animation("defend"):
		return "defend"
	if _is_eating and sprite.sprite_frames.has_animation("eat"):
		return "eat"

	var animation_base: String
	if is_on_floor():
		if absf(velocity.x) > 0.1:
			animation_base = "walk"
		else:
			animation_base = "idle"
	else:
		if velocity.y > 0.0:
			animation_base = "falling"
		else:
			animation_base = "jumping"

	if sprite.sprite_frames.has_animation(animation_base):
		return animation_base
	if sprite.sprite_frames.has_animation("idle"):
		return "idle"
	return ""


func _try_start_attack() -> void:
	if _is_attacking or _is_defending or _is_eating or _defend_break_left > 0.0 or not shoot_timer.is_stopped() or not sprite.sprite_frames.has_animation("attack"):
		return
	if not _consume_stamina(attack_stamina_cost):
		return
	var attack_input_axis := Input.get_axis("move_left" + action_suffix, "move_right" + action_suffix)
	if is_zero_approx(attack_input_axis):
		attack_input_axis = _facing_direction
	_is_attacking = true
	_attack_fired = false
	_attack_facing_direction = -1.0 if attack_input_axis < 0.0 else 1.0
	_facing_direction = _attack_facing_direction
	sprite.play("attack")


func _try_start_eat() -> void:
	if not _is_eat_pressed():
		return
	if _is_attacking or _is_defending or _is_eating or _defend_break_left > 0.0:
		return
	if not _is_near_fern or _nearby_food_source == null or not is_instance_valid(_nearby_food_source):
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("eat"):
		return

	_eating_food_source = _nearby_food_source
	_is_eating = true
	_eat_time_left = _get_eat_animation_duration()
	velocity.x = 0.0
	sprite.play("eat")


func _get_eat_animation_duration() -> float:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("eat"):
		return 0.25
	var frame_count := sprite.sprite_frames.get_frame_count("eat")
	if frame_count <= 0:
		return 0.25
	var speed := absf(sprite.sprite_frames.get_animation_speed("eat"))
	if speed <= 0.0:
		speed = 1.0
	var total := 0.0
	for frame in range(frame_count):
		total += sprite.sprite_frames.get_frame_duration("eat", frame)
	return maxf(0.05, total / speed)


func _has_eating_target_disappeared() -> bool:
	if _eating_food_source == null:
		return true
	if not is_instance_valid(_eating_food_source):
		return true
	if _eating_food_source is CanvasItem and not (_eating_food_source as CanvasItem).visible:
		return true
	return false


func _try_finish_eat_animation() -> void:
	if sprite.animation != "eat":
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("eat"):
		return
	var last_frame := sprite.sprite_frames.get_frame_count("eat") - 1
	if last_frame < 0:
		return
	if sprite.frame < last_frame:
		return
	if sprite.frame_progress < 0.98:
		return
	_finish_eat_sequence()


func _finish_eat_sequence() -> void:
	if not _is_eating:
		return
	_is_eating = false
	_eat_time_left = 0.0
	if not _has_eating_target_disappeared():
		_consume_food_source(_eating_food_source)
	_eating_food_source = null


func _consume_food_source(food_source: Node2D) -> void:
	if food_source == null or not is_instance_valid(food_source):
		return

	if food_source is CanvasItem:
		(food_source as CanvasItem).visible = false

	# Area2D food pickups should be removed so they cannot be consumed twice.
	if food_source is Area2D or food_source.name.to_lower().begins_with("forage"):
		food_source.queue_free()

	_nearby_food_source = null
	_is_near_fern = false
	forage(eat_hunger_restore)


func _is_eat_pressed() -> bool:
	var action_name := "eat" + action_suffix
	if InputMap.has_action(action_name):
		return Input.is_action_just_pressed(action_name)
	if InputMap.has_action("eat"):
		return Input.is_action_just_pressed("eat")
	return false


func _update_defend_state(delta: float) -> void:
	var was_defending := _is_defending

	if _is_attacking or _is_eating:
		_is_defending = false
		_start_defend_cooldown_if_needed(was_defending)
		return

	if not sprite.sprite_frames.has_animation("defend"):
		_is_defending = false
		_defend_hold_left = 0.0
		_start_defend_cooldown_if_needed(was_defending)
		return

	var should_defend := _is_defend_pressed()
	if _defend_requires_release:
		if not should_defend:
			_defend_requires_release = false
		_is_defending = false
		_defend_hold_left = 0.0
		if _defend_recovery_delay_left <= 0.0:
			_defend_heat = maxf(0.0, _defend_heat - defend_heat_cool_per_second * delta)
		return
	if _stamina <= 0.0:
		_is_defending = false
		_defend_hold_left = 0.0
		if _defend_recovery_delay_left <= 0.0:
			_defend_heat = maxf(0.0, _defend_heat - defend_heat_cool_per_second * delta)
		_start_defend_cooldown_if_needed(was_defending)
		return
	if should_defend and not _is_defending and _defend_cooldown_left > 0.0:
		_is_defending = false
		_defend_hold_left = 0.0
		if _defend_recovery_delay_left <= 0.0:
			_defend_heat = maxf(0.0, _defend_heat - defend_heat_cool_per_second * delta)
		return
	if not should_defend and (_defend_hold_left <= 0.0 or not _is_defending):
		_is_defending = false
		_defend_hold_left = 0.0
		if _defend_recovery_delay_left <= 0.0:
			_defend_heat = maxf(0.0, _defend_heat - defend_heat_cool_per_second * delta)
		_start_defend_cooldown_if_needed(was_defending)
		return
	if should_defend and not _is_defending:
		_defend_hold_left = defend_min_hold_seconds

	_is_defending = true
	_defend_heat = minf(defend_heat_max, _defend_heat + defend_heat_gain_per_second * delta)
	_defend_recovery_delay_left = defend_heat_cool_delay


func _start_defend_cooldown_if_needed(was_defending: bool) -> void:
	if not was_defending or _is_defending:
		return
	if defend_cooldown_duration <= 0.0:
		return
	_defend_cooldown_left = defend_cooldown_duration
	_defend_requires_release = true


func _is_defend_pressed() -> bool:
	var action_name := "defend" + action_suffix
	if InputMap.has_action(action_name):
		return Input.is_action_pressed(action_name)
	if InputMap.has_action("defend"):
		return Input.is_action_pressed("defend")
	return false


func _is_sprint_pressed() -> bool:
	var action_name := "sprint" + action_suffix
	if InputMap.has_action(action_name):
		return Input.is_action_pressed(action_name)
	if InputMap.has_action("sprint"):
		return Input.is_action_pressed("sprint")
	return false


func _update_sprint_state() -> void:
	if _is_attacking or _is_defending or _is_eating:
		_is_sprinting = false
		return
	if not sprint_in_air and not is_on_floor():
		_is_sprinting = false
		return
	if _stamina <= 0.0:
		_is_sprinting = false
		return
	var move_axis := Input.get_axis("move_left" + action_suffix, "move_right" + action_suffix)
	if absf(move_axis) <= 0.1:
		_is_sprinting = false
		return
	_is_sprinting = _is_sprint_pressed()


func _process_attack_shot() -> void:
	if not _is_attacking or _attack_fired:
		return
	if sprite.animation != "attack":
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("attack"):
		return
	var frame_count := sprite.sprite_frames.get_frame_count("attack")
	if frame_count <= 0:
		return
	var hit_frame := int(floor(float(frame_count - 1) * clampf(attack_hit_timing, 0.0, 1.0)))
	if sprite.frame < hit_frame:
		return
	_attack_fired = true
	_apply_attack_hit()
	shoot_timer.start()


func _update_defend_animation_loop() -> void:
	if not _is_defending or sprite.animation != "defend" or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation("defend"):
		return
	var frame_count := sprite.sprite_frames.get_frame_count("defend")
	if frame_count <= 0:
		return
	var loop_start := mini(5, frame_count - 1)
	var loop_end := mini(14, frame_count - 1)
	if loop_end <= loop_start:
		return
	if sprite.frame > loop_end:
		sprite.set_frame_and_progress(loop_start, 0.0)


func _apply_attack_hit() -> void:
	if attack_damage <= 0 or attack_range <= 0.0:
		return
	var attack_origin := global_position + Vector2(attack_hit_offset.x * _attack_facing_direction, attack_hit_offset.y)
	var attack_range_squared := attack_range * attack_range
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if enemy.has_method(&"is_alive") and not bool(enemy.call(&"is_alive")):
			continue
		if enemy.has_method(&"is_passive_enemy") and bool(enemy.call(&"is_passive_enemy")):
			continue
		var delta := enemy.global_position - attack_origin
		if delta.length_squared() > attack_range_squared:
			continue
		if enemy.has_method(&"take_damage"):
			enemy.call(&"take_damage", attack_damage, self)


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "attack":
		if not _attack_fired:
			_attack_fired = true
			_apply_attack_hit()
			shoot_timer.start()
		_is_attacking = false
	elif sprite.animation == "eat":
		_finish_eat_sequence()


func _update_stamina(delta: float) -> void:
	if debug_god_mode:
		if not is_equal_approx(_stamina, _effective_max_stamina):
			_stamina = _effective_max_stamina
			_emit_stamina_changed()
		return

	if _is_defending and defend_stamina_drain_per_second > 0.0:
		if not _consume_stamina(defend_stamina_drain_per_second * delta):
			_is_defending = false
		return

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


func _set_stamina(new_stamina: float) -> void:
	var clamped := clampf(new_stamina, 0.0, _effective_max_stamina)
	if is_equal_approx(clamped, _stamina):
		return
	var previous := _stamina
	_stamina = clamped
	if _stamina < previous:
		_apply_hunger_loss_from_stamina_spent(previous - _stamina)
	_emit_stamina_changed()


func _consume_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if _stamina < amount:
		return false
	_set_stamina(_stamina - amount)
	return true


func _update_stamina_from_hunger(emit_if_unchanged := true) -> void:
	_effective_max_stamina = maxf(1.0, max_stamina)
	var previous := _stamina
	_stamina = clampf(_stamina, 0.0, _effective_max_stamina)
	if emit_if_unchanged or not is_equal_approx(previous, _stamina):
		_emit_stamina_changed()


func _get_hunger_ratio() -> float:
	if max_hunger <= 0:
		return 0.0
	return clampf(float(_hunger) / float(max_hunger), 0.0, 1.0)


func _get_hunger_limited_stamina_cap() -> float:
	return _get_hunger_ratio() * _effective_max_stamina


func _get_stamina_regen_factor() -> float:
	return 1.0


func _emit_stamina_changed() -> void:
	stamina_changed.emit(int(round(_stamina)), int(round(_effective_max_stamina)))


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
	var hunger_before := _hunger
	_hunger = maxi(0, _hunger - whole_loss)
	if _hunger != hunger_before:
		hunger_changed.emit(_hunger, max_hunger)


func try_jump() -> void:
	if is_on_floor():
		jump_sound.pitch_scale = 1.0
	elif _double_jump_charged:
		_double_jump_charged = false
		velocity.x *= 2.5
		jump_sound.pitch_scale = 1.5
	else:
		return
	velocity.y = JUMP_VELOCITY
	jump_sound.play()


func forage(heal_amount := 1) -> void:
	restore_hunger(heal_amount)


func restore_hunger(amount: int) -> void:
	if amount <= 0:
		return
	var hunger_before := _hunger
	_hunger = mini(max_hunger, _hunger + amount)
	if _hunger != hunger_before:
		hunger_changed.emit(_hunger, max_hunger)
		_hunger_loss_accumulator = 0.0
		var hunger_ratio := _get_hunger_ratio()
		var target_stamina := hunger_ratio * _effective_max_stamina
		if target_stamina > _stamina:
			_set_stamina(target_stamina)


func heal(amount: int) -> void:
	if amount <= 0:
		return
	var health_before := _health
	_health = mini(max_health, _health + amount)
	if _health != health_before:
		health_changed.emit(_health, max_health)


func take_damage(amount: int, impulse := Vector2.ZERO) -> void:
	if debug_god_mode:
		return
	if _is_defending:
		var reduced_with_carry := float(amount) * defend_damage_multiplier + _defend_damage_accumulator
		amount = maxi(0, int(floor(reduced_with_carry)))
		_defend_damage_accumulator = reduced_with_carry - float(amount)
		impulse *= defend_knockback_multiplier
	else:
		_defend_damage_accumulator = 0.0
	if amount <= 0 or _damage_cooldown_left > 0.0:
		return
	_health = maxi(0, _health - amount)
	health_changed.emit(_health, max_health)
	_damage_cooldown_left = contact_damage_cooldown
	if not impulse.is_zero_approx():
		velocity = impulse
	if _health <= 0:
		_respawn()


func _respawn() -> void:
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_airborne_start_y = global_position.y
	_health = max_health
	_hunger = max_hunger
	_damage_cooldown_left = 0.0
	_hunger_tick_left = hunger_tick_interval
	_starvation_damage_left = starvation_damage_interval
	_full_hunger_regen_left = full_hunger_regen_interval
	_stamina = max_stamina
	_hunger_loss_accumulator = 0.0
	_defend_cooldown_left = 0.0
	_defend_requires_release = false
	_defend_damage_accumulator = 0.0
	_update_stamina_from_hunger(false)
	health_changed.emit(_health, max_health)
	hunger_changed.emit(_hunger, max_hunger)
	_emit_stamina_changed()


func _update_hunger(delta: float) -> void:
	if delta <= 0.0:
		return
	if full_hunger_regen_interval <= 0.0 or full_hunger_regen_amount <= 0:
		return

	var can_regen := _health < max_health and max_hunger > 0 and _hunger >= max_hunger
	if not can_regen:
		_full_hunger_regen_left = full_hunger_regen_interval
		return

	_full_hunger_regen_left -= delta
	while _full_hunger_regen_left <= 0.0 and _health < max_health and _hunger >= max_hunger:
		heal(full_hunger_regen_amount)
		if full_hunger_regen_hunger_cost > 0:
			var hunger_before := _hunger
			_hunger = maxi(0, _hunger - full_hunger_regen_hunger_cost)
			if _hunger != hunger_before:
				hunger_changed.emit(_hunger, max_hunger)
				_set_stamina(minf(_stamina, _get_hunger_limited_stamina_cap()))
		_full_hunger_regen_left += full_hunger_regen_interval


func _consume_hunger(amount: int) -> void:
	if amount <= 0:
		return
	var stamina_cost := float(amount)
	if max_hunger > 0:
		stamina_cost = (float(amount) / float(max_hunger)) * _effective_max_stamina
	_set_stamina(_stamina - stamina_cost)


func _apply_fall_damage_on_landing(was_on_floor: bool, vertical_speed_before_move: float) -> void:
	if was_on_floor or not is_on_floor():
		return
	var fall_distance := global_position.y - _airborne_start_y
	if fall_distance < fall_damage_min_distance:
		return
	if vertical_speed_before_move < fall_damage_start_speed:
		return
	var damage := 1 + int(floor((vertical_speed_before_move - fall_damage_start_speed) / fall_damage_step))
	take_damage(mini(max_fall_damage, damage))


func _handle_enemy_collisions() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node2D and (collider as Node2D).is_in_group(&"enemies"):
			var enemy := collider as Node2D
			if enemy.has_method(&"is_alive") and not bool(enemy.call(&"is_alive")):
				continue
			var push_direction := signf(global_position.x - enemy.global_position.x)
			if is_zero_approx(push_direction):
				push_direction = -_facing_direction
			if enemy.has_method(&"try_attack_player") and bool(enemy.call(&"try_attack_player", self, Vector2(push_direction * 360.0, -280.0))):
				break


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
		var position_delta := enemy.global_position - global_position
		if position_delta.length_squared() <= radius_squared:
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
	var dinosaur_name := String(enemy.call(&"get_dinosaur_name")) if enemy.has_method(&"get_dinosaur_name") else "Unknown Dinosaur"
	var dinosaur_description := String(enemy.call(&"get_dinosaur_description")) if enemy.has_method(&"get_dinosaur_description") else "%s encountered." % dinosaur_name
	dinosaur_first_encountered.emit(dinosaur_name, dinosaur_description)


func _handle_hazard_tile_collisions() -> bool:
	if debug_god_mode:
		return false
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collision_position := collision.get_position()
		var collider := collision.get_collider()
		if collider is Node and (collider as Node).is_in_group(hazard_layer_group):
			_respawn()
			return true

		if collider is TileMapLayer:
			var layer := collider as TileMapLayer
			var local_position := layer.to_local(collision_position)
			var cell := layer.local_to_map(local_position)
			var tile_data := layer.get_cell_tile_data(cell)
			if _tile_data_is_hazard(tile_data):
				_respawn()
				return true
		elif collider is TileMap:
			var tile_map := collider as TileMap
			for layer_index in range(tile_map.get_layers_count()):
				var local_position := tile_map.to_local(collision_position)
				var cell := tile_map.local_to_map(local_position)
				var tile_data := tile_map.get_cell_tile_data(layer_index, cell)
				if _tile_data_is_hazard(tile_data):
					_respawn()
					return true

	return false


func _tile_data_is_hazard(tile_data: TileData) -> bool:
	if tile_data == null:
		return false
	var value: Variant = tile_data.get_custom_data(hazard_tile_custom_data_key)
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_INT:
		return value != 0
	if typeof(value) == TYPE_FLOAT:
		return not is_zero_approx(value)
	if typeof(value) == TYPE_STRING:
		var text := (value as String).to_lower()
		return text == "1" or text == "true" or text == "yes"
	return false


func _is_god_mode_toggle_pressed() -> bool:
	var action_name := "toggle_god_mode" + action_suffix
	if InputMap.has_action(action_name):
		return Input.is_action_just_pressed(action_name)
	if InputMap.has_action("toggle_god_mode"):
		return Input.is_action_just_pressed("toggle_god_mode")
	return false


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	_xp += amount
	var leveled_up := false
	while _xp >= _xp_to_next:
		_xp -= _xp_to_next
		_level += 1
		_xp_to_next = _calculate_xp_to_next(_level)
		_apply_level_up_rewards()
		leveled_up = true
	if leveled_up:
		level_changed.emit(_level)
	xp_changed.emit(_xp, _xp_to_next)


func _calculate_xp_to_next(level: int) -> int:
	var level_value := maxi(1, level)
	return maxi(1, int(round(float(base_xp_to_level) * pow(float(level_value), xp_growth_factor))))


func _apply_level_up_rewards() -> void:
	if level_up_health_bonus > 0:
		max_health += level_up_health_bonus
		_health = max_health
		health_changed.emit(_health, max_health)
	if level_up_stamina_bonus > 0.0:
		max_stamina += level_up_stamina_bonus
	_update_stamina_from_hunger(false)
	_stamina = _effective_max_stamina
	_emit_stamina_changed()
	if level_up_attack_bonus > 0:
		attack_damage += level_up_attack_bonus
