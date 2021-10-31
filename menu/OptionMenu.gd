extends Menu
class_name OptionMenu

signal goto_previous_menu

var previous_menu:Menu

func _ready():
	menu_entries = ["MusicVolume", "SfxVolume", "ControllerType", "Back"]
	process_menu_entry_names()
	select_entry(selected_idx)
