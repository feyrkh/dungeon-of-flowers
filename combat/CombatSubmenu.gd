extends Control

signal cancel_submenu
signal select_submenu_item(item_idx)

onready var anim = find_node("AnimationPlayer")
onready var SubmenuArrowUp = find_node("SubmenuArrowUp")
onready var SubmenuArrowDown = find_node("SubmenuArrowDown")
onready var SubmenuEntries = [find_node("Submenu1"), find_node("Submenu2"), find_node("Submenu3"), find_node("Submenu4"), ]

var selected_entry_idx = 0
var selected_move_idx = 0
var selected_page_idx = 0
var move_entries = []

func setup(_move_entries):
	self.move_entries = _move_entries
	selected_entry_idx = 0

func _ready():
	set_process(false)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		hide()
		yield(anim, "animation_finished")
		emit_signal("cancel_submenu")
	elif Input.is_action_just_pressed("ui_down"):
		select_next_entry(1)
	elif Input.is_action_just_pressed("ui_up"):
		select_next_entry(-1)
	elif Input.is_action_just_pressed("ui_accept"):
		open_targeting_menu()


func select_next_entry(direction):
	var new_entry_idx = selected_entry_idx + direction
	var new_move_idx = selected_move_idx + direction
	if new_entry_idx < 0:  
		# already at top, do nothing
		return
	if new_entry_idx > 3 or selected_move_idx >= move_entries.size():
		# already_at_bottom, do nothing
		return
	selected_entry_idx = new_entry_idx
	selected_move_idx = selected_move_idx
	highlight_entry(selected_entry_idx)

func highlight_entry(entry_idx):
	for entry in SubmenuEntries:
		entry.find_node("Highlight").visible = false
		
		
func open_targeting_menu():
	pass

func hide():
	set_process(false)
	#SubmenuArrowUp.visible = false
	#SubmenuArrowDown.visible = false
	anim.play("fade")
	yield(anim, "animation_finished")
	self.visible = false

func show():
	selected_entry_idx = 0
	selected_move_idx = 0
	selected_page_idx = 0
	highlight_entry(0)
	self.visible = true
	anim.play_backwards("fade")
	yield(anim, "animation_finished")
	#SubmenuArrowUp.visible = true
	#SubmenuArrowDown.visible = true
	set_process(true)
