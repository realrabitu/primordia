extends Node2D

const CameraBoundsServiceScript := preload("res://level/CameraBoundsServiceGd.gd")
const CAMERA_MARGIN_X := 320.0
const CAMERA_MARGIN_TOP := 260.0
const CAMERA_MARGIN_BOTTOM := 360.0

var _generated_root: Node2D
var _generated_bounds := Rect2()
var _players_cache: Array[Player] = []
var _players_dirty := true
var _cached_tile_layer: TileMapLayer
var _cached_tile_map: TileMap


func _ready() -> void:
    _generated_root = get_node_or_null(^"GeneratedTerrain") as Node2D
    if _generated_root == null:
        _generated_root = Node2D.new()
        _generated_root.name = "GeneratedTerrain"
        add_child(_generated_root)

    _cached_tile_layer = get_node_or_null(^"Layer0") as TileMapLayer
    if _cached_tile_layer == null:
        _cached_tile_map = get_node_or_null(^"TileMap") as TileMap

    var tree := get_tree()
    if not tree.node_added.is_connected(_on_tree_node_added):
        tree.node_added.connect(_on_tree_node_added)
    if not tree.node_removed.is_connected(_on_tree_node_removed):
        tree.node_removed.connect(_on_tree_node_removed)

    _update_camera_limits()


func _exit_tree() -> void:
    var tree := get_tree()
    if tree == null:
        return
    if tree.node_added.is_connected(_on_tree_node_added):
        tree.node_added.disconnect(_on_tree_node_added)
    if tree.node_removed.is_connected(_on_tree_node_removed):
        tree.node_removed.disconnect(_on_tree_node_removed)


func _update_camera_limits() -> void:
    CameraBoundsServiceScript.update_camera_limits(
        self,
        _generated_root,
        _generated_bounds,
        _collect_players(),
        CAMERA_MARGIN_X,
        CAMERA_MARGIN_TOP,
        CAMERA_MARGIN_BOTTOM,
        _cached_tile_layer,
        _cached_tile_map
    )


func _collect_players() -> Array[Player]:
    if not _players_dirty:
        return _players_cache

    var players: Array[Player] = []
    var search_root: Node = get_parent() if get_parent() != null else self
    var stack: Array[Node] = [search_root]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        if node is Player:
            players.append(node as Player)
        for child: Node in node.get_children():
            stack.append(child)

    _players_cache = players
    _players_dirty = false
    return _players_cache


func _on_tree_node_added(node: Node) -> void:
    if node is Player:
        _players_dirty = true


func _on_tree_node_removed(node: Node) -> void:
    if node is Player:
        _players_dirty = true
