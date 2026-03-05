extends SceneTree

const SCENE_PATH := "res://level/level.scn"
const ENEMY_SCENE := preload("res://enemy/enemy.tscn")
const NEW_ENEMIES := [
	Vector2(6120, 820),
	Vector2(6880, 720),
	Vector2(7640, 610),
	Vector2(8420, 540),
	Vector2(9280, 430),
	Vector2(10360, 340),
	Vector2(11580, 360),
	Vector2(12480, 300)
]

func _init() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % SCENE_PATH)
		quit(1)
		return

	var root := packed.instantiate()
	if root == null:
		push_error("Failed to instantiate %s" % SCENE_PATH)
		quit(1)
		return

	var enemies_node := root.get_node_or_null("Enemies")
	if enemies_node == null:
		enemies_node = Node.new()
		enemies_node.name = "Enemies"
		root.add_child(enemies_node)
		enemies_node.owner = root

	for index in range(13, 21):
		var existing := enemies_node.get_node_or_null("Enemy%d" % index)
		if existing != null:
			enemies_node.remove_child(existing)

	for i in NEW_ENEMIES.size():
		var enemy_instance := ENEMY_SCENE.instantiate() as Node2D
		enemy_instance.name = "Enemy%d" % (13 + i)
		enemy_instance.position = NEW_ENEMIES[i]
		enemy_instance.z_index = 2
		enemies_node.add_child(enemy_instance)
		enemy_instance.owner = root

	var out := PackedScene.new()
	var pack_err := out.pack(root)
	if pack_err != OK:
		push_error("Failed to pack scene: %s" % pack_err)
		quit(1)
		return

	var save_err := ResourceSaver.save(out, SCENE_PATH)
	if save_err != OK:
		push_error("Failed to save scene: %s" % save_err)
		quit(1)
		return

	var verify_scene := load(SCENE_PATH) as PackedScene
	var verify_root := verify_scene.instantiate()
	var verify_enemies := verify_root.get_node_or_null("Enemies")
	var present := []
	if verify_enemies != null:
		for index in range(13, 21):
			if verify_enemies.has_node("Enemy%d" % index):
				present.append(index)

	print("Saved level.scn with added enemies: ", present)
	quit(0)
