extends Node

signal setting_updated(setting_name, old_value, new_value)
signal state_updated(state_name, old_value, new_value)
signal dialogic_signal(arg)

const SAVE_GAME_MAJOR_VERSION = '000001'
const SAVE_GAME_MINOR_VERSION = '000001'

const MUSIC_VOLUME = "music_volume"
const SFX_VOLUME = "sfx_volume"
const TUTORIAL_ON = "tutorial_on"
const STEP_COUNTER = "_step_counter"
const ATTACK_RING_HANDICAP = "hcap_atk_ring"
const STACKING_TOWER_HANDICAP = "hcap_stack_tower"
const TILE_MATCH_HANDICAP = "hcap_tile_match"
const TILE_MATCH_HANDICAP_MIN = -5
const TILE_MATCH_HANDICAP_MAX = 10

const UI_PLATFORM = "ui_platform"
const UI_PLATFORM_PC = "pc"
const UI_PLATFORM_XBOX = "xbox"

var c = '$'
var allies = []
var world_tile_position = Vector2()
var player_rotation = 0
var facing = "north"
var settings_file = "user://settings.save"
var cur_dungeon = "intro"
var dungeon setget set_dungeon, get_dungeon
var _dungeon_scene
var player:Spatial
var game_time = 0  # number of seconds that the game has been running
var transients = []

var settings = { # default settings go here
	MUSIC_VOLUME: 65,
	SFX_VOLUME: 65,
	TUTORIAL_ON: true
}

var game_state = {
}

var map_data = {}

var inventory = {}

func set_map_data(layer:String, coords:Vector2, val):
	if !map_data.has(layer):
		map_data[layer] = {}
	if val == null:
		map_data[layer].erase(coords)
	else:
		map_data[layer][coords] = val

func get_map_data(layer, coords:Vector2):
	return map_data.get(layer, {}).get(coords, null)

func get_map_layer_data(layer):
	if !map_data.has(layer):
		map_data[layer] = {}
	return map_data[layer]

func map_tile_changed(layer, x, y, tile_id):
	var layer_data = get_map_layer_data(layer)
	if !layer_data.has("_tiles"):
		layer_data["_tiles"] = {}
	layer_data["_tiles"][Vector2(x,y)] = tile_id

func set_dungeon(val):
	_dungeon_scene = val

func get_dungeon():
	if _dungeon_scene && is_instance_valid(_dungeon_scene):
		return _dungeon_scene
	_dungeon_scene = get_tree().root.find_node("Dungeon", true, false)
	return _dungeon_scene

func listen_for_setting_change(listener):
	connect("setting_updated", listener, "on_setting_change")

func _init():
	set_state("randseed", randi())

func _ready():
	save_game_defaults()
	EventBus.connect("new_player_location", self, "on_new_player_location")
	EventBus.connect("acquire_item", self, "on_acquire_item")
	EventBus.connect("post_load_game", self, "post_load_game")
	EventBus.connect("post_new_game", self, "post_new_game")
	EventBus.connect("map_tile_changed", self, "map_tile_changed")
	randomize()
	load_settings()

func _process(delta):
	game_time += delta

func post_new_game():
	pass

func post_load_game():
	pass

func on_acquire_item(item_name, amount):
	Util.inc(inventory, item_name, amount)

func on_use_item(item_name, amount):
	Util.inc(inventory, item_name, amount, 0)

func save_game_defaults():
	save_game_default("grias_levelup_energy", [5, 5, 5, 0])

func save_game_default(k, default_val_if_missing):
	if game_state.has(k):
		return
	game_state[k] = default_val_if_missing

func save_game(save_file):
	transients = []
	EventBus.emit_signal("pre_save_game")
	var f := File.new()
	#var err = f.open_encrypted_with_pass(save_file, File.WRITE, "dof"+str(c)+str(2021)+"|"+"liquid"+"enthusiasm")
	var err = f.open(save_file, File.WRITE)
	if err != 0:
		printerr(save_file, " : Failed to open save file while saving, got error: ", err)
		return false
	f.store_var(SAVE_GAME_MAJOR_VERSION)
	f.store_var(SAVE_GAME_MINOR_VERSION)
	f.store_var(game_state)
	for ally in allies:
		if ally != null:
			f.store_var(ally.save_data())
		else:
			f.store_var(null)
	f.store_var(world_tile_position)
	f.store_var(player_rotation)
	f.store_var(facing)
	f.store_var(cur_dungeon)
	f.store_var(inventory)
	f.store_var(map_data)
	f.store_var(game_time)
	f.store_var(transients)
	f.close()
	EventBus.emit_signal("post_save_game")
	return true

func load_game(save_file):
	get_tree().paused = false
	EventBus.emit_signal("pre_load_game")
	var f := File.new()
	#var err = f.open_encrypted_with_pass(save_file, File.READ, "dof"+str(c)+str(2021)+"|"+"liquid"+"enthusiasm")
	var err = f.open(save_file, File.READ)
	if err != 0:
		printerr(save_file, " : Failed to open save file while loading, got error: ", err)
		return false
	var save_game_version = f.get_var()
	if save_game_version != SAVE_GAME_MAJOR_VERSION:
		printerr(save_file, " : has a different save game major version than the current loading code. File: ", save_game_version, "; Code: ", SAVE_GAME_MAJOR_VERSION)
		return false
	save_game_version = f.get_var()
	if save_game_version != SAVE_GAME_MINOR_VERSION:
		printerr(save_file, " : has a different save game minor version than the current loading code. File: ", save_game_version, "; Code: ", SAVE_GAME_MAJOR_VERSION)
		return false # TODO: Support loading older minor versions
	game_state = f.get_var()
	allies = [null, null, null]
	allies[0] = f.get_var(true)
	allies[1] = f.get_var(true)
	allies[2] = f.get_var(true)
	for i in range(allies.size()):
		var data = allies[i]
		if data != null:
			allies[i] = AllyData.new()
			allies[i].load_data(data)
	world_tile_position = f.get_var()
	player_rotation = f.get_var()
	facing = f.get_var()
	cur_dungeon = f.get_var()
	inventory = f.get_var()
	if inventory == null: inventory = {}
	map_data = f.get_var()
	if map_data == null: map_data = {}
	game_time = f.get_var()
	if game_time == null: game_time = 0
	transients = f.get_var()
	if transients == null: transients = []
	f.close()
	get_tree().change_scene("res://dungeon/GeneratedDungeon.tscn")
	dungeon = get_tree().root
	save_game_defaults()
	load_transients()
	yield(get_tree(), "idle_frame")
	EventBus.emit_signal("post_load_game")
	yield(get_tree(), "idle_frame")
	EventBus.emit_signal("finalize_load_game")
	return true

func add_transient(scene_filename, scene_config, scene_transform):
	transients.append({"f":scene_filename, "c":scene_config, "t":scene_transform})

func load_transients():
	for transient in transients:
		var scene = load(transient.get("f"))
		if scene == null:
			printerr("Unable to load scene for transient: ", transient)
			continue
		var instance = scene.instance()
		instance.set_transient_data(transient.get("c"))
		instance.transform = transient.get("t")
		dungeon.add_child(instance)
	transients = []

func on_dialogic_signal(arg):
	match arg:
		"combat_gameover":
			gameover()
		_: emit_signal("dialogic_signal", arg)

func save_settings():
	var f = File.new()
	var err = f.open(settings_file, File.WRITE)
	if err != 0:
		printerr(settings_file, " : Failed to open settings file while saving, got error: ", err)
		return
	f.store_var(settings)
	f.close()

func load_settings():
	var f = File.new()
	if f.file_exists(settings_file):
		var err = f.open(settings_file, File.READ)
		if err != 0:
			printerr(settings_file, " : Failed to open settings file while loading, got error: ", err)
			return
		var new_settings:Dictionary = f.get_var()
		f.close()
		for setting in new_settings.keys():
			update_setting(setting, new_settings[setting])

func update_setting(setting, val):
	var old_value = settings.get(setting, null)
	settings[setting] = val
	if old_value != val:
		emit_signal("setting_updated", setting, old_value, val)
		print("Setting ", setting, "=", val)

func set_setting(setting, val):
	update_setting(setting, val)

func get_setting(setting, defaultVal=null):
	return settings.get(setting, defaultVal)

func get_state(state_entry, default_val=null):
	if !game_state.has(state_entry):
		game_state[state_entry] = default_val
	return game_state.get(state_entry)

func set_state(state_entry, val):
	update_state(state_entry, val)

func inc_state(state_entry, delta, default_val=0, min_val=null, max_val=null):
	var new_val = get_state(state_entry, default_val)
	new_val = new_val + delta
	if min_val != null and new_val < min_val:
		new_val = min_val
	if max_val != null and new_val > max_val:
		new_val = max_val
	update_state(state_entry, new_val)

func update_state(state_entry, val):
	var old_value = game_state.get(state_entry, null)
	game_state[state_entry] = val
	if !state_entry.begins_with("_") and (val is Array or old_value != val):
		emit_signal("state_updated", state_entry, old_value, val)
		print("State ", state_entry, "=", val)

func on_new_player_location(x, y, rot_deg):
	world_tile_position = Vector2(x, y)
	player_rotation = round(rot_deg)
	match int(round(rot_deg)):
		0: facing = "north"
		-90: facing = "east"
		180,-180: facing = "south"
		90: facing = "west"
		_:
			printerr("Unknown facing with angle ", int(round(rot_deg)))

func setup_allies():
	if get_state(TUTORIAL_ON):
		allies = [null, new_char_grias(), null]
	else:
		allies = [new_char_echincea(), new_char_grias(), mock_shantae()]

func new_game():
	get_tree().paused = false
	EventBus.emit_signal("pre_new_game")
	set_state(TUTORIAL_ON, get_setting(TUTORIAL_ON))
	save_game_defaults()
	setup_allies()
	if get_state(TUTORIAL_ON):
		cur_dungeon = "intro"
		QuestMgr.pollen_spread_enabled = false
	else:
		cur_dungeon = "floor1"
		QuestMgr.pollen_spread_enabled = true
	get_tree().change_scene("res://dungeon/GeneratedDungeon.tscn")
	yield(get_tree(), "idle_frame")
	EventBus.emit_signal("post_new_game")
	yield(get_tree(), "idle_frame")
	EventBus.emit_signal("finalize_new_game")

func gameover():
	yield(get_tree().create_timer(1), "timeout")
	get_tree().change_scene("res://menu/MainMenu.tscn")

func new_char_echincea():
	var ally = AllyData.new()
	ally.label = "Echinacea"
	ally.className = "Floriculturist"
	ally.max_hp = 100
	ally.hp = 100
	ally.sp = 20
	ally.max_sp = 20
	ally.texture = "res://img/hero1.png"
	ally.moves = [
		MoveList.get_move('thump'),
	]
	if !GameData.get_state(TUTORIAL_ON):
		ally.moves.append(MoveList.get_move("poultice"))
	ally.shields = [
		#{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(0, -130), "scale": Vector2(0.5, 0.5)},
	]
	return ally

func mock_shantae():
	var ally = AllyData.new()
	ally.label = "Arum"
	ally.className = "Titan"
	ally.max_hp = 100
	ally.hp = 100
	ally.sp = 20
	ally.max_sp = 20
	ally.texture = "res://img/hero3.jpg"
	ally.moves = [
		MoveList.get_move('thump'),
	]
	ally.shields = [
		#{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(0, -130), "scale": Vector2(1.0, 1.0)},
	]
	return ally

func new_char_grias():
	var ally = AllyData.new()
	ally.label = "Grias"
	ally.className = "Knight"
	ally.max_hp = 100
	ally.hp = 100
	ally.sp = 20
	ally.max_sp = 20
	ally.texture = "res://img/hero4.jpg"
	ally.moves = [
		MoveList.get_move('slash'),
	]
	if !GameData.get_state(TUTORIAL_ON):
		ally.moves.append(MoveList.get_move("bodyguard"))
	ally.shields = [
		#{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(-150, -130), "scale": Vector2(2.0, 1.0)},
		#{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(150, -130), "scale": Vector2(2.0, 1.0)},
	]
	return ally

func set_rand_seed():
	var s = get_state("randseed")
	print("setting randseed to: ", s)
	rand_seed(get_state("randseed", 0))

func get_allies_in_party():
	var result = {}
	for ally in allies:
		if ally == null: continue
		match ally.label:
			"Grias": result["g"] = true
			"Echinacea": result["e"] = true
			"Echincea": result["e"] = true # oops
			"Arum": result["a"] = true
	return result

func pay_cost(cost_map):
	var currency = get_state("grias_levelup_energy", [0, 0, 0, 0, 0, 0, 0])
	for k in cost_map.keys():
		currency[k] -= cost_map[k]
	set_state("grias_levelup_energy", currency)

func can_afford(cost_map):
	var currency = get_state("grias_levelup_energy", [0, 0, 0, 0, 0, 0, 0])
	for k in cost_map.keys():
		if currency[k] < cost_map[k]:
			return false
	return true

func cost_after_investment(cost_map, invest_map):
	# Subtract investments from cost and return the new map
	var new_cost:Dictionary = cost_map.duplicate()
	for k in invest_map:
		if new_cost.has(k):
			new_cost[k] = max(0, new_cost[k]-invest_map[k])
			if new_cost[k] <= 0:
				new_cost.erase(k)
	return new_cost
