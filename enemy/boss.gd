class_name Boss extends Enemy


signal defeated()

@export_range(0.2, 6.0, 0.1) var jump_interval := 2.0
@export_range(-1200.0, -50.0, 1.0) var jump_impulse := -420.0

var _jump_time_left := 0.0


func _physics_process(delta: float) -> void:
	if is_alive():
		_jump_time_left -= delta
		if is_on_floor() and _jump_time_left <= 0.0:
			velocity.y = jump_impulse
			_jump_time_left = jump_interval
	super._physics_process(delta)


func take_damage(amount := 1, source: Node = null) -> void:
	var was_alive := is_alive()
	super.take_damage(amount, source)
	if was_alive and not is_alive():
		defeated.emit()
