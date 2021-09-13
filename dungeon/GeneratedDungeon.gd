extends Spatial

const Player = preload("res://dungeon/Player.tscn")

export var dungeon_file = "res://data/map/intro.txt"

const tile_wall = preload("res://dungeon/wall.tscn")
const tile_corridor = preload("res://dungeon/corridor.tscn")
const tile_torch = preload("res://dungeon/torchwall.tscn")

const tiles = {
	"#": [tile_torch, tile_wall],
	" ": tile_corridor,
	"@": tile_corridor,
}

var player
var combat_grace_period:int = 4
var combat_grace_period_counter:int
var combat_chance_per_tile:float = 0.1
var property_types:Dictionary = {}
var randseed:int

onready var Map:Spatial = find_node("Map")
onready var Combat:Control = find_node("Combat")
onready var Fader:Control = find_node("Fader")

func _ready():
	for prop in get_property_list():
		property_types[prop.name] = prop.type
	var file = File.new()
	file.open(dungeon_file, File.READ)
	var content = file.get_line()
	while content != "map:":
		process_config_line(content)
		content = file.get_line()
	process_map(file)
	combat_grace_period_counter = combat_grace_period
	CombatMgr.register(player, self)

func _on_player_tile_move_complete():
	if combat_grace_period_counter > 0:
		combat_grace_period_counter -= 1
	else:
		if combat_chance_per_tile >= randf():
			CombatMgr.trigger_combat("combat config")
			combat_grace_period_counter = combat_grace_period

func process_config_line(line:String):
	var chunks = line.split(":", false, 1)
	if chunks.size() == 2:
		match property_types.get(chunks[0]):
			TYPE_INT:
				set(chunks[0], int(chunks[1]))
			TYPE_REAL:
				set(chunks[0], float(chunks[1]))
			TYPE_STRING:
				set(chunks[0], chunks[1])
			_: printerr("Unexpected property type: ", property_types.get(chunks[0]))
	
func process_map(file):
	rand_seed(randseed)
	var z = 0
	var content = file.get_line()
	while content != "":
		var x = 0
		for c in content:
			if c == "@":
				player = Player.instance(0)
				player.transform.origin = Vector3(3*x, 0, 3*z)
				#player.transform = player.transform.rotated(Vector3.UP, deg2rad(90))
				add_child(player)
			var tileScene = tiles.get(c)
			if tileScene is Array:
				tileScene = tileScene[randi()%tileScene.size()]
			if tileScene == null:
				printerr("Undefined tile character in "+dungeon_file+" at ("+x+","+z+") '"+c+"'")
				x += 1
				continue
			var tile:Spatial = tileScene.instance(0)
			add_child(tile)
			tile.transform.origin = Vector3(3*x, 0, 3*z)
			var rotate_amt = deg2rad(randi()%4 * 90)
			tile.transform.basis = tile.transform.basis.rotated(Vector3.UP, rotate_amt)
			x += 1
		content = file.get_line()
		z += 1
	file.close()

