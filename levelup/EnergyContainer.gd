extends GridContainer

func _ready():
	GameData.connect("state_updated", self, "state_updated")
	update_counts()
	call_deferred("update_counts")

func state_updated(state_name, old_value, new_value):
	match state_name:
		"grias_levelup_energy":
			update_counts()

func update_counts(amts = GameData.get_state("grias_levelup_energy")):
	update_count(amts, C.ELEMENT_SOIL)
	update_count(amts, C.ELEMENT_WATER)
	update_count(amts, C.ELEMENT_SUN)
	update_count(amts, C.ELEMENT_DECAY)

func update_count(amts, element_id):
	var element_name = C.element_name(element_id).capitalize()
	find_node(element_name+"Energy").visible = amts[element_id] > 0
	find_node(element_name+"Energy").text = str(amts[element_id])
	find_node(element_name+"Icon").visible = amts[element_id] > 0
