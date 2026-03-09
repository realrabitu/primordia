extends Node

signal score_changed(current: int)

var _score := 0


func _ready() -> void:
	_connect_existing_enemy_signals()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func get_score() -> int:
	return _score


func reset_score() -> void:
	_set_score(0)


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	_set_score(_score + amount)


func _set_score(value: int) -> void:
	var next_value := maxi(0, value)
	if next_value == _score:
		return
	_score = next_value
	score_changed.emit(_score)


func _connect_existing_enemy_signals() -> void:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		_connect_enemy_signal(node)


func _on_tree_node_added(node: Node) -> void:
	_connect_enemy_signal(node)


func _connect_enemy_signal(node: Node) -> void:
	if not node.is_in_group(&"enemies"):
		return
	if not node.has_signal(&"slain"):
		return
	var slain_handler := Callable(self, "_on_enemy_slain")
	if node.is_connected(&"slain", slain_handler):
		return
	node.connect(&"slain", slain_handler)


func _on_enemy_slain(killer: Node, xp_reward: int) -> void:
	if xp_reward <= 0:
		return
	if _resolve_killer_player(killer) == null:
		return
	add_score(xp_reward)


func _resolve_killer_player(killer: Node) -> Node:
	if killer != null and killer.is_in_group(&"players"):
		return killer
	if killer is Bullet:
		var source_player := (killer as Bullet).source_player as Node
		if source_player != null and source_player.is_in_group(&"players"):
			return source_player
	return null