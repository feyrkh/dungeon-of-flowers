extends Node

const PixelFader = preload("res://util/pixelFader.tscn")
const CombatScreen = preload("res://combat/CombatScreen.tscn")
const fade_amt = 0.2
signal combat_start
signal combat_end
signal game_end
signal enemy_dead(enemy)

var player
var dungeon
var combat

func register(_player, _dungeon):
	self.player = _player
	self.dungeon = _dungeon
	connect("combat_start", player, "_on_combat_start")
	connect("combat_end", player, "_on_combat_end")
	player.connect("tile_move_complete", dungeon, "_on_player_tile_move_complete")

func trigger_combat(combatConfig):
	print("Starting combat: ", combatConfig)
	emit_signal("combat_start")
	var fader = PixelFader.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	dungeon.Fader.add_child(fader)
	fader.fade_out(fade_amt, 1)
	yield(fader, "fade_complete")
	combat = CombatScreen.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	combat.combat_data = null # TODO: keep track of combat data
	dungeon.Combat.add_child(combat)
	fader.fade_in(fade_amt, 1)
	yield(fader, "fade_complete")
	fader.queue_free()
	combat.connect("allies_win", self, "_on_allies_win")
	combat.connect("allies_lose", self, "_on_allies_lose")

func close_combat():
	var fader = PixelFader.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	dungeon.Fader.add_child(fader)
	fader.fade_out(fade_amt, 1)
	combat.queue_free()
	fader.fade_in(fade_amt, 1)
	yield(fader, "fade_complete")
	fader.queue_free()

func _on_allies_win(combat_data):
	close_combat()
	emit_signal("combat_end")

func _on_allies_lose(combat_data):
	close_combat()
	emit_signal("game_end")
