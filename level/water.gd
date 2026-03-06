@tool
extends Node2D
class_name water

@export var water_size: Vector2 = Vector2(8.0, 16.0)
@export var surface_pos_y: float = 0.5
@export_range(2, 512) var segment_count: int = 64

@export var player_splash_multiplier: float = 0.12
@export_range(0.0, 1000.0) var water_physics_speed: float = 72.0
@export var water_restoring_force: float = 0.02
@export var wave_energy_loss: float = 0.045
@export var wave_strength: float = 0.22
@export_range(1, 64) var wave_spread_updates: int = 8
@export_range(1, 8) var simulation_substeps: int = 2

@export var surface_line_thickness: float = 1.0
@export var surface_color: Color = Color("3ce1da")
@export var water_fill_color: Color = Color("37b0c5")

var segment_data: Array = []
var recently_splashed: bool = false
var _left_deltas: Array[float] = []
var _right_deltas: Array[float] = []
var _visuals_dirty := true

var surface_line: Line2D
var fill_polygon: Polygon2D

@export_tool_button("Update Water") var update_water_button: Callable = func():
	_ready()
	update_visuals()



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("can_interact_with_water"):
		splash(body.global_position, -body.velocity.y * player_splash_multiplier)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("can_interact_with_water"):
		splash(body.global_position, body.velocity.y * player_splash_multiplier)

func update_physics(delta: float) -> void:
	var step_count: int = max(simulation_substeps, 1)
	var dt: float = min(delta, 1.0 / 30.0) / float(step_count)
	var physics_step: float = water_physics_speed * dt
	_ensure_wave_buffers()

	for _step in range(step_count):
		for i in range(segment_count):
			var displacement = segment_data[i]["height"] - surface_pos_y
			var acceleration = -water_restoring_force * displacement - segment_data[i]["velocity"] * wave_energy_loss

			segment_data[i]["velocity"] += acceleration * physics_step
			segment_data[i]["height"] += segment_data[i]["velocity"] * physics_step

		for updates in range(wave_spread_updates):
			for i in range(segment_count):
				_left_deltas[i] = 0.0
				_right_deltas[i] = 0.0

			for i in range (segment_count):
				if i > 0:
					_left_deltas[i] = (segment_data[i]["height"] - segment_data[i-1]["height"]) * wave_strength
				
					segment_data[i-1]["velocity"] += _left_deltas[i] * physics_step

				if i < segment_count - 1:
					_right_deltas[i] = (segment_data[i]["height"] - segment_data[i+1]["height"]) * wave_strength

					segment_data[i+1]["velocity"] += _right_deltas[i] * physics_step
			
			for i in range(segment_count):
				if i > 0:
					segment_data[i-1]["height"] += _left_deltas[i] * physics_step
				if i < segment_count-1:
					segment_data[i+1]["height"] += _right_deltas[i] * physics_step

		segment_data[0]["height"] = surface_pos_y
		segment_data[1]["height"] = surface_pos_y
		segment_data[0]["velocity"] = 0.0
		segment_data[1]["velocity"] = 0.0

		segment_data[segment_count - 1]["height"] = surface_pos_y
		segment_data[segment_count - 2]["height"] = surface_pos_y
		segment_data[segment_count - 1]["velocity"] = 0.0
		segment_data[segment_count - 2]["velocity"] = 0.0

	_visuals_dirty = true
	
	if !recently_splashed:
		var is_still: bool = true
		for i in range(segment_count):
			if absf(segment_data[i]["height"] - surface_pos_y) > 0.001 or absf(segment_data[i]["velocity"]) > 0.001:
				is_still = false
				break
		set_physics_process(!is_still)
	else:
		recently_splashed = false

func update_visuals() -> void:
	var points: Array[Vector2] = []
	var segment_width: float = water_size.x / (segment_count - 1)
	for i in range(segment_count):
		points.append(Vector2(i * segment_width, segment_data[i]["height"]))
	
	var left_static_point: Vector2 = Vector2(points[0].x, surface_pos_y)
	var right_static_point: Vector2 = Vector2(points[points.size() - 1].x, surface_pos_y)

	var final_points: Array[Vector2] = []
	final_points.append(left_static_point)
	final_points += points
	final_points.append(right_static_point)

	surface_line.points = final_points

	var bottom_y: float = surface_pos_y + water_size.y
	final_points.append(Vector2(water_size.x, bottom_y))
	final_points.append(Vector2(0, bottom_y))
	fill_polygon.polygon = final_points
	_visuals_dirty = false

func splash(splash_pos: Vector2, splash_velocity: float) -> void:
	var local_x_pos: float = to_local(splash_pos).x
	var segment_width: float = water_size.x / (segment_count - 1)
	var index: int = int(clamp(local_x_pos / segment_width, 0, segment_count - 1))
	segment_data[index]["velocity"] = splash_velocity
	recently_splashed = true
	_visuals_dirty = true
	set_physics_process(true)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in get_children():
		i.queue_free()
	
	_initiate_water()
	_visuals_dirty = true
	update_visuals()
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	update_physics(delta)
	if _visuals_dirty:
		update_visuals()


func _ensure_wave_buffers() -> void:
	if _left_deltas.size() != segment_count:
		_left_deltas.resize(segment_count)
	if _right_deltas.size() != segment_count:
		_right_deltas.resize(segment_count)

func _initiate_water() -> void:
	segment_data.clear()
	for i in range(segment_count):
		segment_data.append({
			"height": surface_pos_y,
			"velocity": 0.0,
			"wave_to_left": 0.0,
			"wave_to_right": 0.0
		})
	_ensure_wave_buffers()
	
	var new_line: Line2D = Line2D.new()
	new_line.width = surface_line_thickness
	new_line.default_color = surface_color
	add_child(new_line)
	surface_line = new_line

	var new_polygon: Polygon2D = Polygon2D.new()
	new_polygon.color = water_fill_color
	new_polygon.show_behind_parent = true
	surface_line.add_child(new_polygon)
	fill_polygon = new_polygon

	var new_area: Area2D = Area2D.new()
	new_area.body_entered.connect(_on_body_entered)
	new_area.body_exited.connect(_on_body_exited)
	new_area.visible = false
	add_child(new_area)

	var new_collisionshape: CollisionShape2D = CollisionShape2D.new()
	var new_shape: RectangleShape2D = RectangleShape2D.new()
	new_shape.size = water_size
	new_collisionshape.shape = new_shape
	new_collisionshape.position = water_size/2.0 + Vector2(0, surface_pos_y/2.0)
	new_area.add_child(new_collisionshape)