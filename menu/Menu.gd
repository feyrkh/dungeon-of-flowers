extends Control
class_name Menu

signal menu_paused(menu)
signal menu_resumed(menu)

const menu_item_change_sfx = preload("res://sound/mixkit-metallic-sword-strike-2160.wav")
const menu_item_action_sfx = preload("res://sound/mixkit-sword-cutting-flesh-2788.wav")
const menu_item_disabled_sfx = preload("res://sound/thump.mp3")

onready var Arrow = find_node("Arrow")
export var menu_entries = ["NewGame", "Tutorial", "Options", "Quit"]
export var paused_on_start = true
var selected_idx = 0

func _ready():
	process_menu_entry_names()
	select_entry(selected_idx)
	if paused_on_start:
		pause_menu()
	else:
		resume_menu()

func process_menu_entry_names():
	for i in range(menu_entries.size()):
		if menu_entries[i] is String:
			menu_entries[i] = find_node(menu_entries[i])
			if menu_entries[i].has_method("setup_menu"):
				menu_entries[i].setup_menu(self)

func pause_menu():
	set_process_input(false)
	visible = false

func resume_menu():
	for i in range(menu_entries.size()):
		if i != selected_idx and menu_entries[i].has_method("menu_deselected"):
			menu_entries[i].menu_deselected(self)
	set_process_input(true)
	visible = true

func release_focus():
	var current_focus_control = get_focus_owner()
	if current_focus_control:
		current_focus_control.release_focus()

func select_entry(entry_idx):
	release_focus()
	if menu_entries[selected_idx].has_method("menu_deselected"):
		menu_entries[selected_idx].menu_deselected(self)
	selected_idx = entry_idx
	var entry = menu_entries[entry_idx]
	Arrow.rect_global_position.y = entry.rect_global_position.y + entry.rect_size.y/2 - Arrow.rect_size.y/2 
	Arrow.rect_global_position.x = entry.get_parent().rect_global_position.x - 15
	if menu_entries[selected_idx].has_method("menu_selected"):
		menu_entries[selected_idx].menu_selected(self)

func _input(event):
	if event.is_action_pressed("ui_up"):
		var new_selected_idx = selected_idx - 1
		if new_selected_idx < 0: 
			new_selected_idx += menu_entries.size()
		select_entry(new_selected_idx)
		AudioPlayerPool.play(menu_item_change_sfx, 3.0)
	elif event.is_action_pressed("ui_down"):
		var new_selected_idx = (selected_idx + 1)%menu_entries.size()
		if new_selected_idx < 0: 
			new_selected_idx += menu_entries.size()
		select_entry(new_selected_idx)
		AudioPlayerPool.play(menu_item_change_sfx, 3.0)
	elif event.is_action_pressed("ui_right"):
		if menu_entries[selected_idx].has_method("menu_increment"):
			if menu_entries[selected_idx].increment_sfx: AudioPlayerPool.play(menu_item_action_sfx, 1.0)
			menu_entries[selected_idx].menu_increment(self)
	elif event.is_action_pressed("ui_left"):
		if menu_entries[selected_idx].has_method("menu_decrement"):
			if menu_entries[selected_idx].increment_sfx: AudioPlayerPool.play(menu_item_action_sfx, 1.0)
			menu_entries[selected_idx].menu_decrement(self)
	elif event.is_action_pressed("ui_accept"):
		if menu_entries[selected_idx].has_method("menu_action"):
			if menu_entries[selected_idx].disabled:
				AudioPlayerPool.play(menu_item_disabled_sfx, 1.0)
			else:
				AudioPlayerPool.play(menu_item_action_sfx, 1.0)
				menu_entries[selected_idx].menu_action(self)

