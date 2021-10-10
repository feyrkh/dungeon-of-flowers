extends Control

const MENU_CLOSED = 0
const PAUSE_MENU_OPEN = 1
const OPTION_MENU_OPEN = 2

var menu_state = MENU_CLOSED

func _ready():
	find_node("OptionMenu").connect("goto_previous_menu", self, "on_options_menu_closed")
	EventBus.connect("disable_pause_menu", self, "on_disable_pause_menu")
	EventBus.connect("enable_pause_menu", self, "on_enable_pause_menu")
	$PauseMenu.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		pressed_escape()

func pressed_escape():
	if menu_state == MENU_CLOSED:
		open_pause_menu()
	elif menu_state == PAUSE_MENU_OPEN:
		close_pause_menu()
	elif menu_state == OPTION_MENU_OPEN:
		close_option_menu()

func open_pause_menu():
	EventBus.emit_signal("game_paused")
	get_tree().paused = true
	print("game paused")
	$PauseMenu.resume_menu()
	menu_state = PAUSE_MENU_OPEN

func close_pause_menu():
	$PauseMenu.pause_menu()
	get_tree().paused = false
	EventBus.emit_signal("game_unpaused")
	print("game unpaused")
	menu_state = MENU_CLOSED

func close_option_menu():
	$PauseMenu.resume_menu()
	$OptionMenu.pause_menu()
	menu_state = PAUSE_MENU_OPEN

func open_option_menu():
	$PauseMenu.pause_menu()
	$OptionMenu.resume_menu()
	menu_state = OPTION_MENU_OPEN
	
func on_options_menu_closed(menu):
	close_option_menu()

func on_disable_pause_menu():
	pause_mode = PAUSE_MODE_STOP
	set_process_input(false)

func on_enable_pause_menu():
	pause_mode = PAUSE_MODE_PROCESS
	set_process_input(true)
