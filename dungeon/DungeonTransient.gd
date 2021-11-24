extends Spatial
class_name DungeonTransient

func _ready():
	EventBus.connect("pre_save_game", self, "pre_save_game")
	EventBus.connect("post_load_game", self, "post_load_game")

func pre_save_game():
	GameData.add_transient(filename, get_transient_data(), transform)

func post_load_game():
	pass

func set_transient_data(transient_data):
	if transient_data != null and transient_data is Dictionary:
		Util.config(self, transient_data)

func get_transient_data():
	return null
