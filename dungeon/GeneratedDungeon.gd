extends Spatial

const Player = preload("res://dungeon/Player.tscn")

export var dungeon_file = "res://data/map/intro.txt"

const tiles = {
	"#": preload("res://dungeon/wall.tscn"),
	" ": preload("res://dungeon/corridor.tscn"),
	"@": preload("res://dungeon/corridor.tscn"),
}

func _ready():
	var file = File.new()
	file.open(dungeon_file, File.READ)
	var z = 0
	var content = file.get_line()
	while content != "":
		var x = 0
		for c in content:
			if c == "@":
				var player = Player.instance(0)
				player.transform.origin = Vector3(3*x, 0, 3*z)
				#player.transform = player.transform.rotated(Vector3.UP, deg2rad(90))
				add_child(player)
			var tileScene = tiles.get(c)
			if tileScene == null:
				printerr("Undefined tile character in "+dungeon_file+" at ("+x+","+z+") '"+c+"'")
				x += 1
				continue
			var tile = tileScene.instance(0)
			add_child(tile)
			tile.transform.origin = Vector3(3*x, 0, 3*z)
			x += 1
		content = file.get_line()
		z += 1
	file.close()


