extends Control

signal cancel_submenu
signal select_submenu_item(submenu, move_data)

onready var anim = find_node("AnimationPlayer")
onready var SubmenuArrowUp = find_node("SubmenuArrowUp")
onready var SubmenuArrowDown = find_node("SubmenuArrowDown")
onready var SubmenuEntries = [find_node("SubmenuEntry1"), find_node("SubmenuEntry2"), find_node("SubmenuEntry3"), find_node("SubmenuEntry4"), ]

var selected_entry_idx = 0
var selected_page_idx = 0
var move_entries = []
var ally_data

func setup(_ally_data, _move_entries):
	selected_entry_idx = 0
	selected_page_idx = 0
	self.move_entries = _move_entries
	render_moves()

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

func render_moves():
	var cur_page = []
	for i in range(4):
		var cur = i + selected_page_idx*4
		var move_data = null
		if i < move_entries.size():
			move_data = move_entries[i]
		SubmenuEntries[i].setup(move_data)

func select_next_entry(direction):
	var new_entry_idx = selected_entry_idx + direction
	if new_entry_idx < 0:  
		# already at top, wrap around
		new_entry_idx = 3
		var new_entry = SubmenuEntries[new_entry_idx]
		while new_entry.is_disabled():
			new_entry_idx -= 1
			new_entry = SubmenuEntries[new_entry_idx]
			if new_entry_idx == selected_entry_idx: 
				break
			
	var new_entry = SubmenuEntries[new_entry_idx]
	if new_entry_idx > 3 or new_entry.is_disabled():
		new_entry_idx = 0
		new_entry = SubmenuEntries[0]
	
	selected_entry_idx = new_entry_idx
	highlight_entry(selected_entry_idx)

func highlight_entry(entry_idx):
	for entry in SubmenuEntries:
		entry.find_node("Highlight").visible = false
	SubmenuEntries[entry_idx].find_node("Highlight").visible = true
		
		
func open_targeting_menu():
	self.visible = false
	set_process(false)
	emit_signal("select_submenu_item", self, move_entries[selected_entry_idx + selected_page_idx*4])

func on_targeting_cancelled():
	self.visible = true
	set_process(true)

func on_targeting_completed():
	hide()

func hide():
	set_process(false)
	#SubmenuArrowUp.visible = false
	#SubmenuArrowDown.visible = false
	anim.play("fade")
	yield(anim, "animation_finished")
	self.visible = false

func show():
	selected_entry_idx = 0
	selected_page_idx = 0
	highlight_entry(0)
	self.visible = true
	anim.play_backwards("fade")
	yield(anim, "animation_finished")
	#SubmenuArrowUp.visible = true
	#SubmenuArrowDown.visible = true
	set_process(true)
