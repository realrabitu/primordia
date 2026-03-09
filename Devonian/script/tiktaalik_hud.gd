extends CanvasLayer

@export_node_path("CharacterBody2D") var player_path: NodePath = ^"../Player"

const POPUP_IMAGE_FOLDERS := [
	"res://Assets/Devonian/Devonian Pop-up infos",
	"res://Devonian/Devonian Pop-up infos",
	"res://Devonian/Devonian Pop-up infos/Gg",
]
const POPUP_IMAGE_ALIASES := {
	"cephalapsis": "cephalaspis",
	"eurypterus": "eurypterids",
}

@onready var health_bar := get_node_or_null("Healthbar") as ProgressBar
@onready var hunger_bar := get_node_or_null("HungerBar") as ProgressBar
@onready var stamina_bar := get_node_or_null("Staminabar") as ProgressBar
@onready var oxygen_bar := get_node_or_null("OxygenBar") as ProgressBar
@onready var health_label := get_node_or_null("Healthbar/HealthValue") as Label
@onready var hunger_label := get_node_or_null("HungerBar/HungerValue") as Label
@onready var stamina_label := get_node_or_null("Staminabar/StaminaValue") as Label
@onready var oxygen_label := get_node_or_null("OxygenBar/OxygenValue") as Label
@onready var score_label := get_node_or_null("ScoreLabel") as Label
@onready var encounter_popup := get_node_or_null("EncounterPopup") as TextureRect
@onready var encounter_close := get_node_or_null("EncounterPopup/CloseButton") as Button

var _player: Node = null
var _popup_images_by_key: Dictionary = {}


func _ready() -> void:
	_resolve_player()
	_cache_popup_images()
	if encounter_popup != null:
		encounter_popup.visible = false
	if encounter_close != null and not encounter_close.pressed.is_connected(_on_encounter_close_pressed):
		encounter_close.pressed.connect(_on_encounter_close_pressed)
	if health_label == null or hunger_label == null or stamina_label == null or oxygen_label == null:
		push_warning("Tiktaalik HUD labels were not found. Expected Healthbar/HealthValue, HungerBar/HungerValue, Staminabar/StaminaValue, OxygenBar/OxygenValue.")
	_bind_player_signals()
	_sync_stats_from_player()
	_connect_score_signal()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
		_bind_player_signals()
		_sync_stats_from_player()


func _resolve_player() -> void:
	_player = get_node_or_null(player_path)


func _bind_player_signals() -> void:
	if _player == null:
		return
	_connect_player_signal("health_changed", Callable(self, "_on_player_health_changed"))
	_connect_player_signal("hunger_changed", Callable(self, "_on_player_hunger_changed"))
	_connect_player_signal("stamina_changed", Callable(self, "_on_player_stamina_changed"))
	_connect_player_signal("oxygen_changed", Callable(self, "_on_player_oxygen_changed"))
	_connect_player_signal("dinosaur_first_encountered", Callable(self, "_on_player_dinosaur_first_encountered"))


func _connect_player_signal(signal_name: String, callable: Callable) -> void:
	if _player == null or not _player.has_signal(signal_name):
		return
	if not _player.is_connected(signal_name, callable):
		_player.connect(signal_name, callable)


func _sync_stats_from_player() -> void:
	if _player == null:
		_set_stat_display(health_bar, health_label, -1, -1)
		_set_stat_display(hunger_bar, hunger_label, -1, -1)
		_set_stat_display(stamina_bar, stamina_label, -1, -1)
		_set_stat_display(oxygen_bar, oxygen_label, -1, -1)
		return

	_on_player_health_changed(_read_player_stat("get_health"), _read_player_stat("get_max_health"))
	_on_player_hunger_changed(_read_player_stat("get_hunger"), _read_player_stat("get_max_hunger"))
	_on_player_stamina_changed(_read_player_stat("get_stamina"), _read_player_stat("get_max_stamina"))
	_on_player_oxygen_changed(_read_player_stat("get_oxygen"), _read_player_stat("get_max_oxygen"))


func _read_player_stat(method_name: String) -> int:
	if _player == null or not _player.has_method(method_name):
		return 0
	return int(_player.call(method_name))


func _on_player_health_changed(current: int, max_health: int) -> void:
	_set_stat_display(health_bar, health_label, current, max_health)


func _on_player_hunger_changed(current: int, max_hunger: int) -> void:
	_set_stat_display(hunger_bar, hunger_label, current, max_hunger)


func _on_player_stamina_changed(current: int, max_stamina: int) -> void:
	_set_stat_display(stamina_bar, stamina_label, current, max_stamina)


func _on_player_oxygen_changed(current: int, max_oxygen: int) -> void:
	_set_stat_display(oxygen_bar, oxygen_label, current, max_oxygen)


func _set_stat_display(target_bar: ProgressBar, target_label: Label, current_value: int, max_value: int) -> void:
	if current_value < 0 or max_value < 0:
		_set_label_text(target_label, "-- / --")
		if target_bar != null:
			target_bar.max_value = 1
			target_bar.value = 0
		return

	var safe_max := maxi(1, max_value)
	var safe_current := clampi(current_value, 0, safe_max)
	_set_label_text(target_label, "%d / %d" % [safe_current, safe_max])
	if target_bar != null:
		if target_bar.has_method("set_health_state"):
			target_bar.call("set_health_state", safe_current, safe_max)
		else:
			target_bar.max_value = safe_max
			target_bar.value = safe_current


func _set_label_text(target: Label, text: String) -> void:
	if target == null:
		return
	target.text = text


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
	_set_label_text(score_label, "SCORE %d" % maxi(0, current_score))


func _on_player_dinosaur_first_encountered(dinosaur_name: String, _dinosaur_description: String) -> void:
	if encounter_popup == null:
		return
	var popup_texture := _resolve_popup_texture(dinosaur_name)
	if popup_texture == null:
		return
	encounter_popup.texture = popup_texture
	encounter_popup.visible = true


func _on_encounter_close_pressed() -> void:
	if encounter_popup != null:
		encounter_popup.visible = false


func _cache_popup_images() -> void:
	_popup_images_by_key.clear()
	for folder in POPUP_IMAGE_FOLDERS:
		_index_popup_images_in_folder(folder)
	if _popup_images_by_key.is_empty():
		push_warning("Popup image folder not found or empty. Checked: %s" % str(POPUP_IMAGE_FOLDERS))


func _index_popup_images_in_folder(folder_path: String) -> void:
	var directory := DirAccess.open(folder_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "png":
			var full_path := "%s/%s" % [folder_path, file_name]
			var file_base := file_name.get_basename()
			_register_popup_key(file_base, full_path)

			var simplified_base := file_base
			if simplified_base.contains("_"):
				simplified_base = simplified_base.split("_", false)[0]
			if simplified_base.contains(" ("):
				simplified_base = simplified_base.split(" (", false)[0]
			_register_popup_key(simplified_base, full_path)
		file_name = directory.get_next()
	directory.list_dir_end()


func _register_popup_key(source_name: String, resource_path: String) -> void:
	var key := _normalize_creature_key(source_name)
	if key.is_empty():
		return
	if not _popup_images_by_key.has(key):
		_popup_images_by_key[key] = resource_path


func _resolve_popup_texture(creature_name: String) -> Texture2D:
	var key := _normalize_creature_key(creature_name)
	if POPUP_IMAGE_ALIASES.has(key):
		key = POPUP_IMAGE_ALIASES[key]
	if not _popup_images_by_key.has(key):
		return null
	return load(_popup_images_by_key[key]) as Texture2D


func _normalize_creature_key(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("_", "").replace("-", "").replace(".", "")
