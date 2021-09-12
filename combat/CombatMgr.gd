extends Node

const PixelFader = preload("res://util/pixelFader.tscn")
const fade_amt = 0.2
signal combat_start
signal combat_end

var player
var dungeon

func register(player, dungeon):
	self.player = player
	self.dungeon = dungeon
	connect("combat_start", player, "_on_combat_start")
	connect("combat_end", player, "_on_combat_end")
	player.connect("tile_move_complete", dungeon, "_on_player_tile_move_complete")

func trigger_combat(combatConfig):
	print("Starting combat: ", combatConfig)
	emit_signal("combat_start")
	var fader = PixelFader.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	dungeon.add_child(fader)
	fader.fade_out(fade_amt, fade_amt)
	yield(fader, "fade_complete")
	yield(get_tree().create_timer(0.5), "timeout")
	fader.fade_in(fade_amt, fade_amt)
	yield(fader, "fade_complete")
	fader.queue_free()
	emit_signal("combat_end")
