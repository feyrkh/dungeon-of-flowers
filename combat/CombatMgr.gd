extends Node

const PixelFader = preload("res://util/pixelFader.tscn")
const CombatScreen = preload("res://combat/CombatScreen.tscn")
const fade_amt = 0.2
signal combat_start
signal combat_end
signal game_end
signal enemy_dead(enemy)
signal execute_combat_intentions(allies, enemies)
signal new_bullet(bullet)
signal attack_bullet_block()
signal attack_bullet_strike(ally_data)

signal player_move_complete(combat_data)
signal player_turn_complete(combat_data)
signal start_enemy_turn(combat_data)
signal start_player_turn(combat_data)
signal enemy_turn_complete(combat_data)

signal show_battle_header(text)
signal hide_battle_header()

var is_in_combat = false
var player
var dungeon
var combat

func register(_player, _dungeon):
	self.player = _player
	self.dungeon = _dungeon
	connect("combat_start", player, "_on_combat_start")
	connect("combat_end", player, "_on_combat_end")
	player.connect("tile_move_complete", dungeon, "_on_player_tile_move_complete")

func trigger_combat(combat_config_file):
	print("Starting combat: ", combat_config_file)
	is_in_combat = true
	emit_signal("combat_start")
	var fader = PixelFader.instance()
	dungeon.Fader.add_child(fader)
	fader.fade_out(fade_amt, 1)
	yield(fader, "fade_complete")
	combat = CombatScreen.instance()
	combat.combat_data = generate_combat_data(combat_config_file)
	dungeon.Combat.add_child(combat)
	fader.fade_in(fade_amt, 1)
	yield(fader, "fade_complete")
	fader.queue_free()
	combat.connect("allies_win", self, "_on_allies_win")
	combat.connect("allies_lose", self, "_on_allies_lose")

func close_combat():
	var fader = PixelFader.instance()
	dungeon.Fader.add_child(fader)
	fader.fade_out(fade_amt, 1)
	combat.queue_free()
	fader.fade_in(fade_amt, 1)
	yield(fader, "fade_complete")
	fader.queue_free()
	QuestMgr.combat_phase = "combat_ended"
	is_in_combat = false

func generate_combat_data(combat_config_file):
	var combat_data := CombatData.new()
	if combat_config_file != null:
		combat_data.load_from(combat_config_file)
	else:
		combat_data.load_from("default")
	return combat_data

func _on_allies_win(combat_data):
	close_combat()
	emit_signal("combat_end")

func _on_allies_lose(combat_data):
	close_combat()
	emit_signal("game_end")
