extends ShieldBasic

var shield_size = 1
var durability = 1

onready var Chunks = find_node("Chunks")

func _ready():
	if get_parent() == get_tree().root:
		var a = load("res://combat/AllyCombatDisplay.tscn").instance()
		get_parent().call_deferred("add_child", a)
		a.rect_position = Vector2(600, 600)
		var sd = {
			"shield_size": 18,
			"shield_speed": 1.0,
			"shield_durability": 5
		}
		Util.delay_call(0.1, self, "setup", [a, sd])

func setup(ally, _shield_data):
	self.shield_data = _shield_data
	global_position = ally.get_target(0) + shield_data.get("pos", Vector2(0, -100))
	shield_size = min(shield_data.get("shield_size", 1), $Chunks.get_child_count())
	speed_bonus = shield_data.get("shield_speed", 1.0)
	for i in range(shield_size, $Chunks.get_child_count()):
		$Chunks.get_child(i).visible = false
		$Chunks.get_child(i).queue_free()
	var chunk_data = shield_data.get("chunk_data", [])
	for i in range(shield_size):
		var cur_chunk_data
		if chunk_data.size() > i:
			cur_chunk_data = shield_data.get("chunk_data")[i]
		else:
			cur_chunk_data = shield_data.duplicate()
			chunk_data.append(cur_chunk_data)
		if cur_chunk_data:
			$Chunks.get_child(i).setup(cur_chunk_data, self)
		else:
			$Chunks.get_child(i).visible = false
			$Chunks.get_child(i).queue_free()
	shield_data["chunk_data"] = chunk_data

func shield_persists_between_rounds():
	for cd in shield_data.get("chunk_data", []):
		if cd != null:
			shield_data["shield_destroyed"] = false
			return
	shield_data["shield_destroyed"] = true

func destroy_module(module):
	var chunk_data = shield_data.get("chunk_data")
	var chunk_idx = chunk_data.find(module.shield_data)
	if chunk_idx >= 0:
		chunk_data[chunk_idx] = null
		shield_persists_between_rounds()
