extends CanvasLayer


@onready var level_label := $LevelLabel as Label


func _ready() -> void:
	level_label.text = "LV 1"


func _on_player_level_changed(level: int) -> void:
	level_label.text = "LV %d" % maxi(1, level)
