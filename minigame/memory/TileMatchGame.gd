extends Node2D

signal minigame_success(successAmount)
signal minigame_complete

const TILESET_TEXTURE:Texture = preload("res://minigame/memory/tiles/tileset.png")
const HEAL_TEXTURE:Texture = preload("res://minigame/memory/tiles/heal_icon.png")
const REGEN_TEXTURE:Texture = preload("res://minigame/memory/tiles/regen_icon.png")
const REGEN_TIME_TEXTURE:Texture = preload("res://minigame/memory/tiles/time_icon.png")
const MEMORY_TILE:PackedScene = preload("res://minigame/memory/MemoryTile.tscn")
const ICON_SIZE = 90.0
const BONUS_ORDER = [HEAL_TEXTURE, REGEN_TEXTURE, REGEN_TIME_TEXTURE]

onready var Cursor = find_node("Cursor")
onready var ProgressTimer = find_node("ProgressTimer")

var game_config
var matrix = []
var matrix_rows = 0
var matrix_cols = 0
var cursor_idx = Vector2(0, 0)
var selected_card
var goal_cards = []
var avg_score = 0
var scores = []

var state = "starting"

func set_minigame_config(_config:Dictionary, _source, _target):
	game_config = _config

func _ready():
	set_process(false)
	if get_parent() == get_tree().root:
		position.x = 1920 - $ColorRect.rect_size.x
		GameData.get_state("TileMatch_tutor", true)
		setup(Util.read_json("res://data/move/poultice.json").get("game_config"))
		start(true)
	else:
		setup(game_config)
	update_cursor_position()
	ProgressTimer.connect("timer_complete", self, "on_timer_complete")
	state = "selecting"

func start(with_tutorial=true):
	if with_tutorial and !GameData.get_state("TileMatch_tutor", false):
		EventBus.emit_signal("show_tutorial", "FirstTimeTooltip", true)
		GameData.set_state("TileMatch_tutor", true)
	state = "selecting"
	set_process(true)

func on_timer_complete():
	finish_game()

func _process(delta):
	if state == "selecting":
		ProgressTimer.update_timer(delta)

func _input(e:InputEvent):
	if state != "selecting":
		return
	if e.is_action_pressed("ui_accept"):
		select_card()
		get_tree().set_input_as_handled()
	elif e.is_action_pressed("ui_left"):
		move_cursor(-1, 0)
		get_tree().set_input_as_handled()
	elif e.is_action_pressed("ui_right"):
		move_cursor(1, 0)
		get_tree().set_input_as_handled()
	elif e.is_action_pressed("ui_up"):
		move_cursor(0, -1)
		get_tree().set_input_as_handled()
	elif e.is_action_pressed("ui_down"):
		move_cursor(0, 1)
		get_tree().set_input_as_handled()

func select_card():
	state = "scoring"
	var best_card = goal_cards[0]
	var best_score = 0
	for goal_card in goal_cards:
		var cur_score = selected_card.get_similarity_score(goal_card.icons)
		if cur_score > best_score:
			best_score = cur_score
			best_card = goal_card
	matrix[cursor_idx.y][cursor_idx.x] = null
	goal_cards.remove(goal_cards.find(best_card))
	avg_score += best_score / $CorrectCards.get_child_count()
	$Tween.interpolate_property(selected_card, "global_position", selected_card.global_position, best_card.global_position + Vector2(0, 220), 0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.interpolate_property(best_card, "modulate", best_card.modulate, Color(0.3, 0.3, 0.3), 0.5)
	$Tween.interpolate_property(selected_card.find_node("ColorRect"), "modulate", selected_card.find_node("ColorRect").modulate, selected_card.get_color(best_score), 0.5)
	$Cursor.visible = false
	$Tween.call_deferred("start")
	yield($Tween, "tween_all_completed")
#	$Tween.remove_all()

	selected_card.set_score(best_score)
	selected_card.get_parent().remove_child(selected_card)
	$ChosenCards.add_child(selected_card)
	selected_card.replace_icons(BONUS_ORDER[$ChosenCards.get_child_count()-1])
	scores.append(selected_card.score)
	selected_card.fade_score(0.25, 0, selected_card.score)
	selected_card = null
	var found_good_position = false
	for y in range(matrix_rows):
		for x in range(matrix_cols):
			if matrix[y][x] != null:
				cursor_idx = Vector2(x, y)
				update_cursor_position()
				found_good_position = true
				break
		if found_good_position:
			break
	if goal_cards.size() > 0:
		$Cursor.visible = true
		state = "selecting"
	else:
		finish_game()


func move_cursor(xdir, ydir):
	for i in range(max(matrix_rows, matrix_cols)):
		cursor_idx.x = (cursor_idx.x + xdir)
		if cursor_idx.x < 0:
			cursor_idx.x = matrix_cols - 1
		elif cursor_idx.x >= matrix_cols:
			cursor_idx.x = 0
		cursor_idx.y = cursor_idx.y + ydir
		if cursor_idx.y < 0:
			cursor_idx.y = matrix_rows - 1
		elif cursor_idx.y >= matrix_rows:
			cursor_idx.y = 0
		selected_card = matrix[cursor_idx.y][cursor_idx.x]
		if selected_card != null:
			break
	update_cursor_position()

func update_cursor_position():
	selected_card = matrix[cursor_idx.y][cursor_idx.x]
	Cursor.global_position = selected_card.global_position

func setup(config):
	self.game_config = config
	ProgressTimer.reset_timer(game_config.get("time", 10))
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
		var correct_tile = MEMORY_TILE.instance()
		correct_tile.setup(config["good_symbols"], [], TILESET_TEXTURE, 0)
		correct_tile.position = correct_tile_pos
		$CorrectCards.add_child(correct_tile)
		goal_cards.append(correct_tile)
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
	var cur_row = []
	matrix = [cur_row]
	var delay = 0.1
	for card in cards:
		card.flip(0, 0)
		card.flip(0.1, delay)
		delay = delay + 0.05
		card.position = card_pos
		card_pos.x += 200
		cur_row.append(card)
		if card_pos.x > 600:
			cur_row = []
			#matrix.append(cur_row)
			card_pos.x = 20
			card_pos.y += 200
		if cur_row.size() > 0 and matrix.find(cur_row) < 0:
			matrix.append(cur_row)
	matrix_rows = matrix.size()
	matrix_cols = matrix[0].size()

func finish_game():
	state = "finishing"
	Cursor.visible = false
	var ending_tween = Tween.new()
	add_child(ending_tween)
	state = "ending"
	var delay = 1.25
	for card in $CorrectCards.get_children():
		ending_tween.interpolate_property(card, "global_position", card.global_position, $PilePosition.global_position, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT, delay)
		ending_tween.interpolate_property(card, "modulate", card.modulate, Color.white, 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		card.flip(0.1, delay-0.25)
		delay += 0.1

		#card.fade_icons(1.5)
	for card in $ChoiceCards.get_children():
		ending_tween.interpolate_property(card, "global_position", card.global_position, $PilePosition.global_position + Vector2(0, 440), 1.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT, delay)
		card.flip(0.1, delay-0.25)
		delay += 0.1
		#card.fade_icons(1.5)

		#card.fade_icons(1.5)
	delay += 0.3
	#for card in $ChosenCards.get_children():
		#ending_tween.interpolate_property(card, "score", card.score, avg_score, 1.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT, delay)
	#	ending_tween.interpolate_property(card.find_node("Score"), "scale", card.find_node("Score").scale, Vector2.ZERO, 1.5, Tween.TRANS_LINEAR, 2, delay)
	#	ending_tween.interpolate_property(card.find_node("ColorRect"), "modulate", card.find_node("ColorRect").modulate, card.get_color(avg_score), 1.5, 0, 2, delay)
	#	ending_tween.interpolate_property(card, "global_position", card.global_position, $PilePosition.global_position + Vector2(0, 220), 1.5, Tween.TRANS_LINEAR, 2, delay)
	#	card.fade_icons(1.5)
	#	card.fade_score(0.5, delay, card.score)

	ending_tween.call_deferred("start")
	yield(ending_tween, "tween_all_completed")
	ending_tween.queue_free()
	yield(get_tree().create_timer(0.5), "timeout")

	var perfects = 0
	var terribles = 0
	var heal_str = 0.1
	var regen_str = 0
	var regen_time = 0

	if scores.size() > 0:
		heal_str = max(scores[0], game_config.get("min_effect", 0.25))
	if scores.size() > 1:
		regen_str = scores[1]
	if scores.size() > 2:
		 regen_time = scores[2]

	if heal_str < 0.5:
		terribles += 1
	if heal_str > 0.9:
		perfects += 1
	if regen_str < 0.5:
		terribles += 1
	if regen_str > 0.9:
		perfects += 1

	if regen_time < 0.5:
		regen_time = 0
		terribles += 1
	elif regen_time < 0.75:
		regen_time = 1
	elif regen_time < 0.9:
		regen_time = 2
	else:
		regen_time = 3
		perfects += 1
	if regen_str > 0:
		regen_time += 1

	if perfects >= 3:
		GameData.inc_state(GameData.TILE_MATCH_HANDICAP, -0.3, 0, GameData.TILE_MATCH_HANDICAP_MIN, GameData.TILE_MATCH_HANDICAP_MAX)
	if terribles >= 2:
		GameData.inc_state(GameData.TILE_MATCH_HANDICAP, 0.2, 0, GameData.TILE_MATCH_HANDICAP_MIN, GameData.TILE_MATCH_HANDICAP_MAX)

	var effect = load("res://combat/effects/EffectHeal.gd").new()
	effect.heal_amt = round(game_config.get("heal", 0) * heal_str)
	effect.regen_amt = round(game_config.get("heal", 0) * heal_str * regen_str * game_config.get("regen_strength_mod", 0.25))
	effect.regen_rounds = ceil(regen_time * game_config.get("regen_length", 1))
	print("Minigame result: ", effect)
	emit_signal("minigame_success", effect)
	emit_signal("minigame_complete", self)
