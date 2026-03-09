extends CanvasLayer

const POPUP_IMAGE_FOLDER := "res://Assets/pop up infos for animals"
const EAT_PROMPT_REFRESH_INTERVAL := 0.1
const HOSTILE_ENEMY_REFRESH_INTERVAL := 0.25
const MAIN_MENU_SCENE_PATH := "res://Scenes/Menu Scenes/MainMenu.tscn"
const POPUP_IMAGE_ALIASES := {
	"camarasaurus": "brachiosaurus",
}

@onready var level_label := _resolve_level_label_node()
@onready var score_label := get_node_or_null("ScoreLabel") as Label
@onready var encounter_popup := $EncounterPopup as TextureRect
@onready var encounter_close := $EncounterPopup/CloseButton as Button
@onready var eat_prompt := $EatPrompt as Label
@onready var win_prompt := get_node_or_null("WinPrompt") as TextureRect
@onready var main_menu_button := get_node_or_null("WinPrompt/MainMenuButton") as BaseButton
@onready var exit_button := get_node_or_null("WinPrompt/ExitButton") as BaseButton

var _popup_images_by_key: Dictionary = {}
var _player: Node
var _eat_prompt_refresh_left := 0.0
var _hostile_enemy_refresh_left := 0.0
var _win_prompt_visible := false
var _has_seen_hostile_enemy := false


func _ready() -> void:
	_set_level_label_text(1)
	_cache_popup_images()
	encounter_popup.visible = false
	eat_prompt.visible = false
	hide_win_prompt()
	if not encounter_close.pressed.is_connected(_on_encounter_close_pressed):
		encounter_close.pressed.connect(_on_encounter_close_pressed)
	if main_menu_button != null and not main_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	if exit_button != null and not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)
	if level_label == null:
		push_warning("HUD level label node not found. Expected 'XPBar/Label' or 'LevelLabel'.")
	_connect_score_signal()
	_resolve_player()


func _process(_delta: float) -> void:
	_eat_prompt_refresh_left -= _delta
	if _eat_prompt_refresh_left > 0.0 and _player != null and is_instance_valid(_player):
		return
	_eat_prompt_refresh_left = EAT_PROMPT_REFRESH_INTERVAL

	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	if _player == null:
		if eat_prompt.visible:
			eat_prompt.visible = false
		return

	var show_prompt: bool = _player.has_method("is_near_fern") and bool(_player.call("is_near_fern"))
	if eat_prompt.visible != show_prompt:
		eat_prompt.visible = show_prompt

	_update_win_prompt_state(_delta)


func _on_player_level_changed(level: int) -> void:
	_set_level_label_text(level)


func _on_player_dinosaur_first_encountered(dinosaur_name: String, _dinosaur_description: String) -> void:
	var popup_texture := _resolve_popup_texture(dinosaur_name)
	if popup_texture == null:
		return
	encounter_popup.texture = popup_texture
	encounter_popup.visible = true


func _on_encounter_close_pressed() -> void:
	encounter_popup.visible = false


func show_win_prompt() -> void:
	if _win_prompt_visible:
		return
	_win_prompt_visible = true
	if win_prompt != null:
		win_prompt.visible = true
	if main_menu_button != null:
		main_menu_button.grab_focus()


func hide_win_prompt() -> void:
	_win_prompt_visible = false
	if win_prompt != null:
		win_prompt.visible = false


func _update_win_prompt_state(delta: float) -> void:
	if _win_prompt_visible:
		return
	_hostile_enemy_refresh_left = maxf(0.0, _hostile_enemy_refresh_left - delta)
	if _hostile_enemy_refresh_left > 0.0:
		return
	_hostile_enemy_refresh_left = HOSTILE_ENEMY_REFRESH_INTERVAL

	var hostile_left := _count_alive_hostile_enemies()
	if hostile_left > 0:
		_has_seen_hostile_enemy = true
		return
	if _has_seen_hostile_enemy:
		show_win_prompt()


func _count_alive_hostile_enemies() -> int:
	var tree := get_tree()
	if tree == null:
		return 0

	var hostile_count := 0
	for node in tree.get_nodes_in_group(&"enemies"):
		if node == null or not is_instance_valid(node):
			continue
		if node.has_method("is_alive") and not bool(node.call("is_alive")):
			continue

		var is_passive_enemy := false
		if node.has_method("is_passive_enemy"):
			is_passive_enemy = bool(node.call("is_passive_enemy"))
		elif _node_has_property(node, &"is_passive"):
			is_passive_enemy = bool(node.get("is_passive"))

		if is_passive_enemy:
			continue
		hostile_count += 1

	return hostile_count


func _node_has_property(node: Object, property_name: StringName) -> bool:
	for property_info in node.get_property_list():
		if StringName(property_info.name) == property_name:
			return true
	return false


func _on_main_menu_button_pressed() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	tree.change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_exit_button_pressed() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.quit()


func _cache_popup_images() -> void:
	_popup_images_by_key.clear()
	var directory := DirAccess.open(POPUP_IMAGE_FOLDER)
	if directory == null:
		push_warning("Popup image folder not found: %s" % POPUP_IMAGE_FOLDER)
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "png":
			var key := _normalize_dinosaur_key(file_name.get_basename())
			_popup_images_by_key[key] = "%s/%s" % [POPUP_IMAGE_FOLDER, file_name]
		file_name = directory.get_next()
	directory.list_dir_end()


func _resolve_popup_texture(dinosaur_name: String) -> Texture2D:
	var key := _normalize_dinosaur_key(dinosaur_name)
	if POPUP_IMAGE_ALIASES.has(key):
		key = POPUP_IMAGE_ALIASES[key]
	if not _popup_images_by_key.has(key):
		return null
	return load(_popup_images_by_key[key]) as Texture2D


func _normalize_dinosaur_key(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("_", "").replace("-", "")


func _resolve_player() -> void:
	for node in get_tree().get_nodes_in_group(&"players"):
		if node != null and is_instance_valid(node):
			_player = node
			_bind_player_signals(node)
			_sync_level_label_from_player(node)
			return
	_player = null


func _bind_player_signals(player_node: Node) -> void:
	var level_changed_callable := Callable(self, "_on_player_level_changed")
	if player_node.has_signal("level_changed") and not player_node.is_connected("level_changed", level_changed_callable):
		player_node.connect("level_changed", level_changed_callable)
	var dinosaur_encounter_callable := Callable(self, "_on_player_dinosaur_first_encountered")
	if player_node.has_signal("dinosaur_first_encountered") and not player_node.is_connected("dinosaur_first_encountered", dinosaur_encounter_callable):
		player_node.connect("dinosaur_first_encountered", dinosaur_encounter_callable)


func _sync_level_label_from_player(player_node: Node) -> void:
	if player_node.has_method("get_level"):
		_on_player_level_changed(int(player_node.call("get_level")))


func _set_level_label_text(level: int) -> void:
	if level_label == null:
		return
	level_label.text = "LV %d" % maxi(1, level)


func _connect_score_signal() -> void:
	var score_node := get_node_or_null("/root/Score")
	if score_node == null:
		return
	var score_changed_callable := Callable(self, "_on_score_changed")
	if score_node.has_signal("score_changed") and not score_node.is_connected("score_changed", score_changed_callable):
		score_node.connect("score_changed", score_changed_callable)
	if score_node.has_method("get_score"):
		_on_score_changed(int(score_node.call("get_score")))


func _on_score_changed(current_score: int) -> void:
	if score_label == null:
		return
	score_label.text = "SCORE %d" % maxi(0, current_score)


func _resolve_level_label_node() -> Label:
	var xp_label := get_node_or_null("XPBar/Label") as Label
	if xp_label != null:
		return xp_label
	return get_node_or_null("LevelLabel") as Label
