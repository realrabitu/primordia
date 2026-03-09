extends ProgressBar

@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

var health = 0 : set = _set_health


func _ensure_damage_bar() -> ProgressBar:
	if damage_bar == null:
		damage_bar = get_node_or_null("DamageBar") as ProgressBar
	return damage_bar

func _set_health(new_health):
	var prev_health = health
	health = clampi(int(new_health), 0, int(max_value))
	value = health

	if health < prev_health:
		if timer != null:
			timer.start()
	else:
		var bar := _ensure_damage_bar()
		if bar != null:
			bar.value = health

func init_health(_health):
	set_health_state(_health, _health)


func set_health_state(current_health: int, max_health: int) -> void:
	max_value = maxi(1, max_health)
	var bar := _ensure_damage_bar()
	if bar != null:
		bar.max_value = max_value
	health = current_health


func _on_player_health_changed(current: int, max_health: int) -> void:
	set_health_state(current, max_health)


func _on_player_hunger_changed(current: int, max_hunger: int) -> void:
	set_health_state(current, max_hunger)


func _on_player_stamina_changed(current: int, max_stamina: int) -> void:
	set_health_state(current, max_stamina)


func _on_player_xp_changed(current: int, required: int) -> void:
	set_health_state(current, required)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ensure_damage_bar()
	var bar := _ensure_damage_bar()
	if bar != null:
		bar.max_value = max_value
		bar.value = health
	var parent := get_parent()
	if parent and parent.has_signal("health_changed"):
		if not parent.health_changed.is_connected(_on_player_health_changed):
			parent.health_changed.connect(_on_player_health_changed)

func _on_timer_timeout() -> void:
	var bar := _ensure_damage_bar()
	if bar != null:
		bar.value = health
	
