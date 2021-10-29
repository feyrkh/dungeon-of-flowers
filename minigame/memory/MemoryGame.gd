extends Node2D

const TILESET_TEXTURE:Texture = preload("res://minigame/memory/tiles/tileset.png")
const MEMORY_TILE:PackedScene = preload("res://minigame/memory/MemoryTile.tscn")
const ICON_SIZE = 90

func _ready():
	if get_parent() == get_tree().root:
		setup(Util.read_json("res://data/move/poultice.json").get("game_config"))

func setup(config):
	var tiles_w = floor(TILESET_TEXTURE.get_width()/ICON_SIZE)
	var tiles_h = floor(TILESET_TEXTURE.get_height()/ICON_SIZE)
	var possible_symbols := []
	for x in range(tiles_w):
		for y in range(tiles_h):
			possible_symbols.append(Vector2(x, y))
	var card_pos = Vector2(20, 460)
	var correct_tile_pos = Vector2(20, 20)
	var cards = []
	for card_number in range(config.get("target_cards", 1)):
		possible_symbols.shuffle()
		config["possible_symbols"] = possible_symbols.slice(0, config.get("total_symbols", 7)-1)
		config["good_symbols"] = possible_symbols.slice(0, config.get("card_symbols", 4)-1)
		var correctTile = MEMORY_TILE.instance()
		correctTile.setup(config["good_symbols"], [], TILESET_TEXTURE, 0)
		correctTile.position = correct_tile_pos
		$CorrectCards.add_child(correctTile)
		correct_tile_pos.x += 200
		config["bad_symbols"] = possible_symbols.slice(config.get("card_symbols", 2), config.get("total_symbols", 7)-1)
		for card_idx in range(config["total_cards"]):
			var card = MEMORY_TILE.instance()
			var badness = card_idx*2
			if badness != 0:
				badness += randi() % 3
			card.setup(config["good_symbols"], config["bad_symbols"], TILESET_TEXTURE, badness)
			$ChoiceCards.add_child(card)
			cards.append(card)
	cards.shuffle()
	for card in cards:
		card.position = card_pos
		card_pos.x += 200
		if card_pos.x > 600:
			card_pos.x = 20
			card_pos.y += 200
