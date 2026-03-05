extends CanvasLayer

const POPUP_IMAGE_FOLDER := "res://Assets/pop up infos for animals"
const POPUP_IMAGE_ALIASES := {
	"camarasaurus": "brachiosaurus",
}

@onready var level_label := $LevelLabel as Label
@onready var encounter_popup := $EncounterPopup as TextureRect
@onready var encounter_close := $EncounterPopup/CloseButton as Button
@onready var eat_prompt := $EatPrompt as Label

var _popup_images_by_key: Dictionary = {}
var _player: Player


func _ready() -> void:
	level_label.text = "LV 1"
	_cache_popup_images()
	encounter_popup.visible = false
	eat_prompt.visible = false
	if not encounter_close.pressed.is_connected(_on_encounter_close_pressed):
		encounter_close.pressed.connect(_on_encounter_close_pressed)
	_resolve_player()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	if _player == null:
		eat_prompt.visible = false
		return
	eat_prompt.visible = _player.is_near_fern()


func _on_player_level_changed(level: int) -> void:
	level_label.text = "LV %d" % maxi(1, level)


func _on_player_dinosaur_first_encountered(dinosaur_name: String, _dinosaur_description: String) -> void:
	var popup_texture := _resolve_popup_texture(dinosaur_name)
	if popup_texture == null:
		return
	encounter_popup.texture = popup_texture
	encounter_popup.visible = true


func _on_encounter_close_pressed() -> void:
	encounter_popup.visible = false


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
		if node is Player:
			_player = node as Player
			return
	_player = null
