extends AnimatableBody2D
## Script-based moving platform that can move vertically or horizontally.

@export var from_offset := 100.0
@export var to_offset := -100.0
@export var move_duration := 4.0
@export var horizontal_movement := false

var _start_y: float
var _start_x: float
var _elapsed_time := 0.0


func _ready() -> void:
	_start_x = global_position.x
	_start_y = global_position.y


func _physics_process(delta: float) -> void:
	_elapsed_time = fmod(_elapsed_time + delta, move_duration)
	
	# Calculate position in cycle (0 to 1)
	var cycle_progress := _elapsed_time / move_duration
	
	# Linear movement: first half goes up, second half goes down
	if cycle_progress < 0.5:
		# Going up
		var progress = cycle_progress * 2.0
		if horizontal_movement:
			global_position.x = lerp(_start_x + from_offset, _start_x + to_offset, progress)
		else:
			global_position.y = lerp(_start_y + from_offset, _start_y + to_offset, progress)
	else:
		# Going down
		var progress = (cycle_progress - 0.5) * 2.0
		if horizontal_movement:
			global_position.x = lerp(_start_x + to_offset, _start_x + from_offset, progress)
		else:
			global_position.y = lerp(_start_y + to_offset, _start_y + from_offset, progress)
