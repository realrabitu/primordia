class_name DevonianEnemyBase
extends Enemy

@export var movement_animation: StringName = &"swim"
@export var idle_animation: StringName = &"idle"
@export var attack_animation: StringName = &"attack"
@export var death_animation: StringName = &"death"


func get_new_animation() -> StringName:
	if _state == State.ATTACKING:
		return _first_available_animation([
			attack_animation,
			&"attack",
			movement_animation,
			idle_animation,
		])

	if _state == State.WALKING or _state == State.CHASING:
		if is_zero_approx(velocity.x):
			return _first_available_animation([
				idle_animation,
				&"idle",
				movement_animation,
				&"swim",
				&"walk",
				attack_animation,
			])
		return _first_available_animation([
			movement_animation,
			&"swim",
			&"walk",
			idle_animation,
			&"idle",
			attack_animation,
		])

	return _first_available_animation([
		death_animation,
		&"death",
		&"destroy",
	])


func _first_available_animation(candidates: Array[StringName]) -> StringName:
	if sprite == null or sprite.sprite_frames == null:
		return StringName()
	for animation_name in candidates:
		if animation_name.is_empty():
			continue
		if sprite.sprite_frames.has_animation(animation_name):
			return animation_name
	return StringName()
