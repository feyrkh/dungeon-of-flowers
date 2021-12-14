extends Node2D

const GriasSpark = preload("res://levelup/GriasSpark.tscn")

const INACTIVE = 0
const CURSOR = 1
const COMPONENT = 2
const CURSOR_OVERFLOW = Vector2(3, 3)
const TILE_SIZE = Vector2(64, 64)
const HALF_SCREEN = (Vector2(1920, 1080) - TILE_SIZE)/2
const SCREEN_SLIDE_AMOUNT = 400
const SCREEN_SLIDE_SPEED = SCREEN_SLIDE_AMOUNT * 5.0
const FOG_TRANSLATE = {
	"cleared": "",
	"chaos1": "Disordered Energy", 
	"chaos2": "Chaotic Energy", 
	"chaos3": "Frenzied Energy",
	"chaos4": "Anarchic Energy", 
	"outside": "Body Boundary"
	}

onready var Grid = find_node("Grid")
onready var Cursor = find_node("Cursor")
onready var CursorMode = find_node("CursorMode")
onready var ComponentMode = find_node("ComponentMode")
onready var Overlay = find_node("Overlay")
onready var OverlayLabel = find_node("OverlayLabel")
onready var TilemapMgr:TilemapMgr = find_node("TilemapMgr")
onready var Tilemaps = find_node("Tilemaps")
onready var EnergyOrbContainer = find_node("EnergyOrbContainer")
onready var ComponentModeParentContainer = find_node("ComponentModeParentContainer")
onready var ComponentMenuList = find_node("ComponentMenuList")
onready var ComponentMenuDescription = find_node("ComponentMenuDescription")
onready var ComponentMenuText = find_node("ComponentMenuText")
onready var ComponentMenuArrow = find_node("ComponentMenuArrow")
onready var EnergyContainer = find_node("EnergyContainer")

var state = INACTIVE setget set_state
var cursor_pos = Vector2(14, 7) setget set_cursor # Tilemap coordinates
var component_cursor_pos = 0 # index of the child of ComponentMenuList the cursor is currently pointed at
var component_input_captured = null # if input was captured by a component, this will be set
var desired_grid_pos = Vector2(0, 0)
var tween:Tween
var clear_tile_id = -1
var chaos1_tile_id = -1
var meridian_tile_id = -1

func set_state(val):
	state = val
	if state == INACTIVE:
		set_process_input(false)
	else:
		set_process_input(true)

func set_cursor(val:Vector2):
	cursor_pos = val
	Cursor.position = cursor_pos*64 - CURSOR_OVERFLOW
	desired_grid_pos = -(Cursor.position - HALF_SCREEN)
	Grid.position = desired_grid_pos
	update_cursor_label()

func update_cursor_label():
	var bits = PoolStringArray()
	var fog = TilemapMgr.get_tile_name("fog", cursor_pos.x, cursor_pos.y)
	if fog and fog != "":
		bits.append(FOG_TRANSLATE.get(fog, fog))
	var component = TilemapMgr.get_tile_scene("component", cursor_pos)
	if component:
		component = component.get_component_label()
	if component:
		bits.append(component)
	OverlayLabel.text = bits.join("\n")

func _ready():
	set_state(INACTIVE)
	set_cursor(Vector2(14, 7))
	if get_tree().root == get_parent():
		enter_levelup()
	load_from_file()
	find_node("component").visible = false
	update_cursor_label()
	EventBus.connect("grias_generate_energy", self, "grias_generate_energy")
	EventBus.connect("grias_levelup_clear_fog", self, "grias_levelup_clear_fog")
	EventBus.connect("grias_levelup_fail_clear_fog", self, "grias_levelup_fail_clear_fog")
	EventBus.connect("grias_levelup_major_component_upgrade", self, "grias_levelup_major_component_upgrade")
	EventBus.connect("map_tile_changed", self, "map_tile_changed")
	EventBus.connect("grias_component_menu_text", self, "grias_component_menu_text")
	EventBus.connect("grias_component_description", self, "grias_component_description")
	EventBus.connect("grias_component_cost", self, "grias_component_cost")
	EventBus.connect("grias_component_change", self, "grias_component_change")
	EventBus.connect("grias_levelup_component_input_capture", self, "grias_levelup_component_input_capture")
	EventBus.connect("grias_levelup_component_input_release", self, "grias_levelup_component_input_release")
	EventBus.connect("grias_exit_component_mode", self, "exit_component_mode")

func grias_component_change(change_type, cost_map, args):
	if change_type == "build_meridian":
		GameData.pay_cost(cost_map)
		var meridian = load("res://levelup/components/Meridian.tscn").instance()
		meridian.position = cursor_pos * 64 + Vector2(32, 32)
		meridian.element = args
		TilemapMgr.set_tile("component", cursor_pos.x, cursor_pos.y, meridian_tile_id)
		TilemapMgr.set_tile_scene("component", cursor_pos, meridian)
		exit_component_mode()
		return
	
	var scene = TilemapMgr.get_tile_scene("component", cursor_pos)
	if !scene or !scene.has_method("component_change"):
		printerr("Unexpected component change at ", cursor_pos, "; ", [change_type, cost_map, args])
		return
	scene.component_change(change_type, cost_map, args)
	update_cursor_label()

func grias_levelup_component_input_release():
	if component_input_captured and component_input_captured.has_method("component_input_ended"):
		component_input_captured.component_input_ended()
	component_input_captured = null

func grias_levelup_component_input_capture(component):
	component_input_captured = component
	if component_input_captured and component_input_captured.has_method("component_input_started"):
		component_input_captured.component_input_started()

func map_tile_changed(layer, x, y, tile):
	if state == COMPONENT and layer == "fog" and cursor_pos.x == x and cursor_pos.y == y:
		exit_component_mode()

func grias_component_cost(cost_map):
	ComponentModeParentContainer.rect_size.x = 400
	
func grias_component_menu_text(text):
	ComponentMenuText.text = text
	ComponentModeParentContainer.rect_size.x = 400
	
func grias_component_description(text):
	if text == null:
		text = ""
	ComponentMenuDescription.text = text
	ComponentModeParentContainer.rect_size.x = 400

func grias_generate_energy(core_node:GriasCore):
	var spark = GriasSpark.instance()
	EnergyOrbContainer.add_child(spark)
	spark.setup(core_node)
	var fade_swirl = preload("res://levelup/FogClear.tscn").instance()
	fade_swirl.position = core_node.position + Vector2(32, 32)
	EnergyOrbContainer.add_child(fade_swirl)
	fade_swirl.fade(C.element_color(core_node.element), 0.25, Vector2.ZERO, Vector2.ONE)

func grias_levelup_clear_fog(map_position:Vector2, fog_color:Color):
	TilemapMgr.set_tile("fog", map_position.x, map_position.y, clear_tile_id)
	var fade_swirl = preload("res://levelup/FogClear.tscn").instance()
	fade_swirl.position = map_position * 64 + Vector2(32, 32)
	EnergyOrbContainer.add_child(fade_swirl)
	fade_swirl.fade(fog_color)
	update_cursor_label()
	
func grias_levelup_fail_clear_fog(map_position:Vector2, fog_color:Color):
	var fade_swirl = preload("res://levelup/FogClear.tscn").instance()
	fade_swirl.position = map_position * 64 + Vector2(32, 32)
	EnergyOrbContainer.add_child(fade_swirl)
	fade_swirl.fail(fog_color)
	update_cursor_label()

func grias_levelup_major_component_upgrade(fog_color:Color):
	var fade_swirl = preload("res://levelup/FogClear.tscn").instance()
	var map_position = cursor_pos
	fade_swirl.position = map_position * 64 + Vector2(32, 32)
	EnergyOrbContainer.add_child(fade_swirl)
	fade_swirl.fade(fog_color, 5, Vector2(2, 2))
	update_cursor_label()

func load_from_file():
	TilemapMgr.load_from_file("res://levelup/grias_levelup_map.json", Tilemaps, {})

func _input(event):
	if state == CURSOR:
		cursor_input(event)
	elif state == COMPONENT:
		component_input(event)

func cursor_input(event):
	if event.is_action("ui_left") and !event.is_action_released("ui_left"):
		 move_cursor(Vector2.LEFT)
	if event.is_action ("ui_right") and !event.is_action_released("ui_right"):
		 move_cursor(Vector2.RIGHT)
	if event.is_action ("ui_up") and !event.is_action_released("ui_up"):
		 move_cursor(Vector2.UP)
	if event.is_action("ui_down") and !event.is_action_released("ui_down"):
		 move_cursor(Vector2.DOWN)
	if event.is_action_pressed("ui_accept"):
		enter_component_mode()
	if event.is_action_pressed("ui_cancel"):
		exit_levelup()

func component_input(event):
	if component_input_captured != null:
		if !component_input_captured.has_method("component_input"):
			EventBus.emit_signal("grias_levelup_component_input_release")
		else:
			component_input_captured.component_input(event)
			return
	if event.is_action_pressed("ui_cancel"):
		exit_component_mode()
	elif event.is_action_pressed("ui_accept"):
		var selected = selected_component_menu_item()
		if selected and selected.has_method("menu_item_action"):
			if selected.has_method("can_menu_item_action") and !selected.can_menu_item_action():
				print("Unable to perform menu item action")
				# TODO: sound effects and stuff
			else:
				selected.menu_item_action()
	elif event.is_action("ui_down") and !event.is_action_released("ui_down"):
		update_arrow_position(1)
	elif event.is_action ("ui_up") and !event.is_action_released("ui_up"):
		update_arrow_position(-1)
	elif (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")) and selected_component_menu_item() != null and selected_component_menu_item().has_method("unselected_component_input"):
		selected_component_menu_item().unselected_component_input(event)

func selected_component_menu_item():
	if component_cursor_pos < 0:
		return null
	return ComponentMenuList.get_child(component_cursor_pos)
	
func enter_levelup():
	EnergyContainer.update_counts()
	Grid.position = Vector2.ZERO
	ComponentMode.position = Vector2(-SCREEN_SLIDE_AMOUNT, 0)
	CursorMode.position = Vector2.ZERO
	set_cursor(Vector2(14, 7))
	set_state(CURSOR)
	EventBus.emit_signal("disable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	visible = true
	
func exit_levelup():
	if get_tree().root == get_parent():
		return # if this is the only thing running then we're in a temp scene
	set_state(INACTIVE)
	EventBus.emit_signal("enable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_INHERIT
	get_tree().paused = false
	visible = false
	
func enter_component_mode():
	EventBus.emit_signal("grias_component_description", "This component didn't set any description!")
	EventBus.emit_signal("grias_component_menu_text", "")
	EventBus.emit_signal("grias_component_cost", null)
	EnergyContainer.update_counts()
	Util.delete_children(ComponentMenuList)
	var fog_level = TilemapMgr.get_tile_name("fog", cursor_pos.x, cursor_pos.y)
	var menu_items = []
	match fog_level:
		"chaos1": 
			add_fog_menu_item(menu_items, fog_level)
		"chaos2": 
			add_fog_menu_item(menu_items, fog_level)
		"chaos3": 
			add_fog_menu_item(menu_items, fog_level)
		"chaos4": 
			add_fog_menu_item(menu_items, fog_level)
		"outside":
			add_fog_menu_item(menu_items, fog_level)
		"cleared":
			add_other_components(menu_items)
		_:
			add_fog_menu_item(menu_items, "external")
	render_components(menu_items)
	slide_component_mode_to(SCREEN_SLIDE_AMOUNT)
	set_state(INACTIVE)
	component_cursor_pos = -1
	ComponentMenuArrow.visible = false
	update_arrow_position(1)
	yield(tween, "tween_all_completed")
	update_arrow_position(0)

	if selected_component_menu_item() and selected_component_menu_item().has_method("menu_item_highlighted"):
		selected_component_menu_item().menu_item_highlighted()
	set_state(COMPONENT)

func update_arrow_position(dir=0):
	if ComponentMenuList.get_child_count() == 0:
		component_cursor_pos = -1
		ComponentMenuArrow.visible = false
		return
	
	if dir != 0:
		for i in range(ComponentMenuList.get_child_count()):
			if selected_component_menu_item() != null and selected_component_menu_item().has_method("menu_item_unhighlighted"):
				selected_component_menu_item().menu_item_unhighlighted()
			component_cursor_pos += dir
			update_arrow_position(0)
			if selected_component_menu_item() and selected_component_menu_item().has_method("can_highlight") and selected_component_menu_item().can_highlight():
				break
		if !selected_component_menu_item():
			ComponentMenuArrow.visible = false
		else:
			if !selected_component_menu_item().has_method("can_highlight") or !selected_component_menu_item().can_highlight():
				ComponentMenuArrow.visible = false
			if selected_component_menu_item().has_method("menu_item_highlighted"):
				selected_component_menu_item().menu_item_highlighted()
	else:
		component_cursor_pos = Util.wrap_range(component_cursor_pos, ComponentMenuList.get_child_count())
		if !selected_component_menu_item() or (!selected_component_menu_item().has_method("can_highlight") or !selected_component_menu_item().can_highlight()):
			ComponentMenuArrow.visible = false
			return
		ComponentMenuArrow.visible = true
		var target_item = ComponentMenuList.get_child(component_cursor_pos)
		ComponentMenuArrow.rect_global_position = target_item.rect_global_position - Vector2(ComponentMenuArrow.rect_size.x, -4)

func add_fog_menu_item(menu_items, fog_level):
	var fog_menu_item = preload("res://levelup/menu_items/FogMenuItem.tscn").instance()
	fog_menu_item.setup(fog_level)
	menu_items.append(fog_menu_item)
	#var core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
	#core.setup(C.ELEMENT_SOIL)
	#menu_items.append(core)

func add_other_components(menu_items):
	var tile_scene = TilemapMgr.get_tile_scene("component", cursor_pos)
	if !tile_scene:
		add_build_components(menu_items)
	else:
		add_scene_components(menu_items, tile_scene)

func add_build_components(menu_items):
	EventBus.emit_signal("grias_component_description", "Grias has ordered the energy here, and could focus it toward useful ends, given enough pollen.")
	var meridian_item = preload("res://levelup/menu_items/BuildMeridianMenuItem.tscn").instance()
	menu_items.append(meridian_item)

func add_scene_components(menu_items, tile_scene):
	if !tile_scene:
		return
	if !tile_scene.has_method("get_component_menu_items"):
		return
	var new_items = tile_scene.get_component_menu_items()
	if new_items is Array:
		menu_items.append_array(new_items)
	elif new_items != null:
		menu_items.append(new_items)

func add_delete_component(menu_items):
	pass

func render_components(menu_items):
	for menu_item in menu_items:
		ComponentMenuList.add_child(menu_item)

func exit_component_mode():
	if state != COMPONENT:
		return
	EnergyContainer.update_counts()
	slide_component_mode_to(0)
	set_state(INACTIVE)
	yield(tween, "tween_all_completed")
	Util.delete_children(ComponentMenuList)
	set_state(CURSOR)

func move_cursor(dir:Vector2):
	set_cursor(cursor_pos + dir)

func slide_component_mode_to(pos):
	if is_instance_valid(tween):
		tween.stop_all()
		tween.queue_free()
	tween = Util.one_shot_tween(self)
	var cur_pos = CursorMode.position.x
	var move_amt = pos - cur_pos
	var move_time = abs(move_amt) / SCREEN_SLIDE_SPEED
	tween.interpolate_property(CursorMode, "position:x", CursorMode.position.x, CursorMode.position.x+move_amt, move_time)
	tween.interpolate_property(EnergyOrbContainer, "position:x", EnergyOrbContainer.position.x, EnergyOrbContainer.position.x+move_amt, move_time)
	tween.interpolate_property(Overlay, "position:x", Overlay.position.x, Overlay.position.x+move_amt/2, move_time)
	tween.interpolate_property(Grid, "position:x", Grid.position.x, Grid.position.x-move_amt/2, move_time)
	tween.interpolate_property(ComponentMode, "position:x", ComponentMode.position.x, ComponentMode.position.x+move_amt*2, move_time)
	tween.start()

func custom_tile_handler(layer, layer_name, tileset, cell, tile_name, tile_id):
	if layer_name == "fog" and tile_name == "cleared":
		clear_tile_id = tile_id
	elif layer_name == "fog" and tile_name == "chaos1":
		chaos1_tile_id = tile_id
	elif layer_name == "component" and tile_name == "redirect_1":
		meridian_tile_id = tile_id
