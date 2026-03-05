class_name Game extends Node


@onready var _pause_menu := $InterfaceLayer/PauseMenu as PauseMenu


func _ready() -> void:
	_connect_existing_enemy_signals()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_fullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or \
				mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_tree().root.set_input_as_handled()

	elif event.is_action_pressed(&"toggle_pause"):
		var tree := get_tree()
		tree.paused = not tree.paused
		if tree.paused:
			_pause_menu.open()
		else:
			_pause_menu.close()
		get_tree().root.set_input_as_handled()


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
	var player := _resolve_killer_player(killer)
	if player == null:
		return
	player.add_xp(xp_reward)


func _resolve_killer_player(killer: Node) -> Player:
	if killer is Player:
		return killer as Player
	if killer is Bullet:
		return (killer as Bullet).source_player
	return null
