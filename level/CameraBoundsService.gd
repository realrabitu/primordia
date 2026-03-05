class_name CameraBoundsService
extends RefCounted


static func update_camera_limits(level_node: Node2D, generated_root: Node2D, generated_bounds: Rect2, players: Array, margin_x: float, margin_top: float, margin_bottom: float) -> void:
	var world_bounds := compute_world_bounds(level_node, generated_root, generated_bounds)
	for player in players:
		if player == null or player.camera == null:
			continue
		player.camera.limit_left = int(floor(world_bounds.position.x - margin_x))
		player.camera.limit_top = int(floor(world_bounds.position.y - margin_top))
		player.camera.limit_right = int(ceil(world_bounds.end.x + margin_x))
		player.camera.limit_bottom = int(ceil(world_bounds.end.y + margin_bottom))


static func compute_world_bounds(level_node: Node2D, generated_root: Node2D, generated_bounds: Rect2) -> Rect2:
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for child in level_node.get_children():
		if child == generated_root:
			continue
		if child is Node2D:
			var point := (child as Node2D).global_position
			min_x = minf(min_x, point.x)
			min_y = minf(min_y, point.y)
			max_x = maxf(max_x, point.x)
			max_y = maxf(max_y, point.y)

	if generated_root != null and generated_root.get_child_count() > 0:
		min_x = minf(min_x, generated_bounds.position.x)
		min_y = minf(min_y, generated_bounds.position.y)
		max_x = maxf(max_x, generated_bounds.end.x)
		max_y = maxf(max_y, generated_bounds.end.y)

	var local_tile_layer := level_node.get_node_or_null(^"Layer0") as TileMapLayer
	if local_tile_layer != null:
		var used_layer := local_tile_layer.get_used_rect()
		if used_layer.size != Vector2i.ZERO:
			var layer_tile_size := local_tile_layer.tile_set.tile_size
			var layer_top_left := local_tile_layer.to_global(Vector2(used_layer.position * layer_tile_size))
			var layer_bottom_right := local_tile_layer.to_global(Vector2((used_layer.position + used_layer.size) * layer_tile_size))
			min_x = minf(min_x, layer_top_left.x)
			min_y = minf(min_y, layer_top_left.y)
			max_x = maxf(max_x, layer_bottom_right.x)
			max_y = maxf(max_y, layer_bottom_right.y)
	else:
		var local_tile_map := level_node.get_node_or_null(^"TileMap") as TileMap
		if local_tile_map != null:
			var used := local_tile_map.get_used_rect()
			if used.size != Vector2i.ZERO:
				var tile_size := local_tile_map.tile_set.tile_size
				var top_left := local_tile_map.to_global(Vector2(used.position * tile_size))
				var bottom_right := local_tile_map.to_global(Vector2((used.position + used.size) * tile_size))
				min_x = minf(min_x, top_left.x)
				min_y = minf(min_y, top_left.y)
				max_x = maxf(max_x, bottom_right.x)
				max_y = maxf(max_y, bottom_right.y)

	if min_x == INF:
		return Rect2(-320.0, -220.0, 1600.0, 1200.0)

	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
