@tool
extends Node

@export var water_terrain_layer_path: NodePath = ^"WaterTerrain"
@export var water_scene_path: NodePath = ^"Water"
@export var terrain_set_id: int = -1
@export var terrain_id: int = -1
@export var sync_scene_on_ready: bool = true
@export var hide_layer_in_game: bool = true
@export var fill_rect: Rect2i = Rect2i(0, 0, 12, 4)

@export_tool_button("Sync Scene From Water Tiles") var sync_scene_button: Callable = func() -> void:
	sync_water_scene_from_tiles()

@export_tool_button("Fill Rect As Terrain Water") var fill_rect_button: Callable = func() -> void:
	fill_rect_with_water_terrain(fill_rect)


func _ready() -> void:
	_update_layer_visibility()
	if sync_scene_on_ready:
		call_deferred("sync_water_scene_from_tiles")


func _update_layer_visibility() -> void:
	var layer := _get_water_layer()
	if layer == null:
		return
	if Engine.is_editor_hint():
		layer.visible = true
	else:
		layer.visible = not hide_layer_in_game


func _get_water_layer() -> TileMapLayer:
	return get_node_or_null(water_terrain_layer_path) as TileMapLayer


func _get_water_scene() -> Node2D:
	return get_node_or_null(water_scene_path) as Node2D


func fill_rect_with_water_terrain(rect: Rect2i) -> void:
	var layer := _get_water_layer()
	if layer == null:
		push_warning("WaterTileBridge: WaterTerrain layer was not found.")
		return
	if terrain_set_id < 0 or terrain_id < 0:
		push_warning("WaterTileBridge: Set terrain_set_id and terrain_id first.")
		return
	if not layer.has_method("set_cells_terrain_connect"):
		push_warning("WaterTileBridge: TileMapLayer has no set_cells_terrain_connect method.")
		return

	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			cells.append(Vector2i(x, y))

	layer.callv("set_cells_terrain_connect", [cells, terrain_set_id, terrain_id, true])
	sync_water_scene_from_tiles()


func sync_water_scene_from_tiles() -> void:
	var layer := _get_water_layer()
	var water_scene := _get_water_scene()
	if layer == null:
		push_warning("WaterTileBridge: WaterTerrain layer was not found.")
		return
	if water_scene == null:
		push_warning("WaterTileBridge: Water scene was not found.")
		return

	var used_cells: Array[Vector2i] = layer.get_used_cells()
	if used_cells.is_empty():
		return

	var tile_size := Vector2(64.0, 64.0)
	if layer.tile_set != null:
		tile_size = layer.tile_set.tile_size

	var min_cell := used_cells[0]
	var max_cell := used_cells[0]
	for c in used_cells:
		min_cell.x = mini(min_cell.x, c.x)
		min_cell.y = mini(min_cell.y, c.y)
		max_cell.x = maxi(max_cell.x, c.x)
		max_cell.y = maxi(max_cell.y, c.y)

	var min_center := layer.map_to_local(min_cell)
	var _max_center := layer.map_to_local(max_cell)
	var top_left_local := min_center - tile_size * 0.5
	var size := Vector2(
		float(max_cell.x - min_cell.x + 1) * tile_size.x,
		float(max_cell.y - min_cell.y + 1) * tile_size.y
	)

	water_scene.position = layer.to_global(top_left_local)
	if water_scene.get_parent() != null:
		water_scene.position = water_scene.get_parent().to_local(water_scene.position)

	if "water_size" in water_scene:
		water_scene.set("water_size", size)
	if water_scene.has_method("rebuild_water"):
		water_scene.call("rebuild_water")
