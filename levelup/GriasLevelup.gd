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
const MIN_NODE_UNLOCK_INTERVAL = 25
const MAX_NODE_UNLOCK_INTERVAL = 35
const NODE_UNLOCK_CHANCE = 0.03
const NEXT_NODE_STAT_TYPE = ["health", "sp", "attack", "defense", "efficiency", ]

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
onready var BonusContainer = find_node("BonusContainer")

var state = INACTIVE setget set_state
var cursor_pos = Vector2(14, 7) setget set_cursor # Tilemap coordinates
var component_cursor_pos = 0 # index of the child of ComponentMenuList the cursor is currently pointed at
var component_input_captured = null # if input was captured by a component, this will be set
var desired_grid_pos = Vector2(0, 0)
var tween:Tween
var clear_tile_id = -1
var chaos1_tile_id = -1
var meridian_tile_id = -1
var powered_node_tile_id = -1
var focus_tile_id = -1
var next_node_unlock = 4
var next_node_stat_type = "health"

func save_levelup():
	EventBus.emit_signal("grias_pre_save_levelup")
	var save_data = {
		"next_node_unlock": next_node_unlock,
		"next_node_stat_type": next_node_stat_type,
	}
	GameData.set_state("__grias_levelup_state", save_data)

func restore_levelup():
	Util.config(self, GameData.get_state("__grias_levelup_state"))

func enter_levelup():
	restore_levelup()
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
	save_levelup()
	set_state(INACTIVE)
	EventBus.emit_signal("enable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_INHERIT
	get_tree().paused = false
	visible = false
	queue_free()

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
		update_cursor_rotate(component)
		var component_label = component.get_component_label()
		if component_label:
			bits.append(component_label)
	else:
		Cursor.show_rotation_icon(false)
	OverlayLabel.text = bits.join("\n")

func update_cursor_rotate(component):
	var can_rotate = component.has_method("can_cursor_rotate") and component.can_cursor_rotate()
	Cursor.show_rotation_icon(can_rotate)

func _ready():
	set_state(INACTIVE)
	set_cursor(Vector2(14, 7))
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
	EventBus.connect("grias_destroy_node", self, "grias_destroy_node")
	EventBus.connect("grias_component_refund", self, "grias_component_refund")
	EventBus.connect("grias_component_change", self, "grias_component_change")
	EventBus.connect("grias_levelup_component_input_capture", self, "grias_levelup_component_input_capture")
	EventBus.connect("grias_levelup_component_input_release", self, "grias_levelup_component_input_release")
	EventBus.connect("grias_exit_component_mode", self, "exit_component_mode")
	EventBus.connect("grias_component_hide_main_arrow", self, "grias_component_hide_main_arrow")

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
	if event.is_action_pressed("rotate_left"):
		rotate_cursor(-1)
	if event.is_action_pressed("rotate_right"):
		rotate_cursor(1)
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

	if event.is_action_pressed("rotate_left"):
		rotate_cursor(-1)
	if event.is_action_pressed("rotate_right"):
		rotate_cursor(1)
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

func grias_component_hide_main_arrow():
	ComponentMenuArrow.visible = false

func grias_component_change(change_type, cost_map, args):
	if change_type == "build_meridian":
		GameData.pay_cost(cost_map)
		var meridian = load("res://levelup/components/Meridian.tscn").instance()
		meridian.position = cursor_pos * 64
		meridian.on_map_place(TilemapMgr, "component", cursor_pos)
		meridian.element = args
		TilemapMgr.set_tile("component", cursor_pos.x, cursor_pos.y, meridian_tile_id)
		TilemapMgr.set_tile_scene("component", cursor_pos, meridian)
		yield(get_tree(), "idle_frame")
		component_cursor_pos = -1
		update_arrow_position(1)
		if selected_component_menu_item().has_method("menu_item_highlighted"):
			selected_component_menu_item().menu_item_highlighted()
		#exit_component_mode()
		return
	elif change_type == "build_focus":
		GameData.pay_cost(cost_map)
		var focus = load("res://levelup/components/FocusNode.tscn").instance()
		focus.position = cursor_pos * 64
		focus.on_map_place(TilemapMgr, "component", cursor_pos)
		TilemapMgr.set_tile("component", cursor_pos.x, cursor_pos.y, focus_tile_id)
		TilemapMgr.set_tile_scene("component", cursor_pos, focus)
		exit_component_mode()
		focus.set_rotation_on_build()
		focus.render_component()
	var scene = TilemapMgr.get_tile_scene("component", cursor_pos)
	if !scene or !scene.has_method("component_change"):
		printerr("Unexpected component change at ", cursor_pos, "; ", [change_type, cost_map, args])
		return
	scene.component_change(change_type, cost_map, args)
	update_cursor_label()

func grias_destroy_node(node, refund_map):
	GameData.refund_cost(refund_map)

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

func grias_component_refund(cost_map):
	ComponentModeParentContainer.rect_size.x = 400

func grias_component_menu_text(text):
	ComponentMenuText.text = text
	ComponentModeParentContainer.rect_size.x = 400

func grias_component_description(text):
	if text == null:
		text = ""
	ComponentMenuDescription.text = text
	ComponentModeParentContainer.rect_size.x = 400
	update_arrow_position()

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
	next_node_unlock -= 1
	if next_node_unlock <= 0 or randf() < NODE_UNLOCK_CHANCE and TilemapMgr.get_tile_scene("component", map_position) == null:
		next_node_unlock = round(rand_range(MIN_NODE_UNLOCK_INTERVAL, MAX_NODE_UNLOCK_INTERVAL))
		unlock_new_node(map_position)

func unlock_new_node(map_position):
	var node = load("res://levelup/components/PoweredNode.tscn").instance()
	node.position = map_position * 64
	node.stat_name = next_node_stat_type
	next_node_stat_type = NEXT_NODE_STAT_TYPE[randi()%NEXT_NODE_STAT_TYPE.size()]
	node.on_map_place(TilemapMgr, "component", map_position)

	TilemapMgr.set_tile("component", map_position.x, map_position.y, powered_node_tile_id)
	TilemapMgr.set_tile_scene("component", map_position, node)

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
	refresh_component_menu()
	update_cursor_label()

func load_from_file():
	TilemapMgr.load_from_file("res://levelup/grias_levelup_map.json", Tilemaps, {})


func selected_component_menu_item():
	if component_cursor_pos < 0:
		return null
	return ComponentMenuList.get_child(component_cursor_pos)


func enter_component_mode():
	EventBus.emit_signal("grias_component_description", "This component didn't set any description!")
	EventBus.emit_signal("grias_component_menu_text", "")
	EventBus.emit_signal("grias_component_cost", null)
	EnergyContainer.update_counts()
	Util.delete_children(ComponentMenuList)
	refresh_component_menu()
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

func refresh_component_menu():
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
	var focus_item = preload("res://levelup/menu_items/BuildFocusNodeMenuItem.tscn").instance()
	menu_items.append(meridian_item)
	menu_items.append(focus_item)

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
	var component_was_captured = component_input_captured != null
	Util.delete_children(ComponentMenuList)
	for child in ComponentMenuList.get_children():
		ComponentMenuList.remove_child(child)
	for menu_item in menu_items:
		ComponentMenuList.add_child(menu_item)
	if component_was_captured:
		component_input_captured = selected_component_menu_item()
	update_arrow_position()
	call_deferred("update_arrow_position")
	if selected_component_menu_item() and selected_component_menu_item().has_method("menu_item_highlighted"):
		selected_component_menu_item().call_deferred("menu_item_highlighted")

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

func rotate_cursor(dir:int):
	var scene = TilemapMgr.get_tile_scene("component", cursor_pos)
	if scene and scene.has_method("can_cursor_rotate") and scene.can_cursor_rotate():
		scene.cursor_rotate(dir)
		Cursor.perform_rotation(dir)

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

func process_tileset(layer):
	var tileset:TileSet = layer.tile_set
	var layer_name = layer.name
	for tile_id in tileset.get_tiles_ids():
		var tile_name = tileset.tile_get_name(tile_id)
		if layer_name == "fog" and tile_name == "cleared":
			clear_tile_id = tile_id
		elif layer_name == "fog" and tile_name == "chaos1":
			chaos1_tile_id = tile_id
		elif layer_name == "component" and tile_name == "redirect_1":
			meridian_tile_id = tile_id
		elif layer_name == "component" and tile_name == "powered_node":
			powered_node_tile_id = tile_id
		elif layer_name == "component" and tile_name == "focus":
			focus_tile_id = tile_id

func update_bonus_display() -> void:
	GameData.update_grias_bonuses()
	Util.delete_children(BonusContainer)
	var effect_map = GameData.get_state("grias_bonuses")
	var effects = {}
	for effect_name in effect_map:
		effects[C.GRIAS_STAT_LABEL.get(effect_name, effect_name)] = C.GRIAS_STAT_FORMAT.get(effect_name, "  %d")%[effect_map[effect_name]]
	var effect_names = effects.keys()
	effect_names.sort()
	for effect_name in effect_names:
		var effect_value = effects[effect_name]
		var name_label:Label = preload("res://levelup/menu_items/BonusListLabel.tscn").instance()
		name_label.align = Label.ALIGN_RIGHT
		name_label.text = effect_name
		var value_label = preload("res://levelup/menu_items/BonusListLabel.tscn").instance()
		value_label.align = Label.ALIGN_RIGHT
		value_label.text = effect_value
		BonusContainer.add_child(name_label)
		BonusContainer.add_child(value_label)
