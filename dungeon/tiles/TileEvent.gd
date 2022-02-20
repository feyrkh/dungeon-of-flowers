# Trigger events when the player steps onto a tile
# Child nodes can have these methods:
#    can_trigger_event(self, map_config): optional, if return false then the event is considered untriggered
#    trigger_event(self, map_config): run the actual event code you want, if the event can be triggered
#    setup(self, map_config): called on_map_place for each child in order
#    on_map_place(_dungeon, layer_name, cell): called on_map_place for each child in order, after setup
# By default the events can fire only once. Trigger count is incremented once per child that triggers, so with 2 children
# it might go up by 2 every time you step on the tile, if neither has can_trigger_event() == false. Change max_trigger_count
# to <= 0 if you want unlimited triggers, or any positive number for limited triggers.

# Map config:
# set_state: map of state names and values, will be set just before the first time an event is triggered
# max_trigger_count: how many times the attached events can trigger, or <= 0 for infinite
# event_require_item: name of an inventory item that must be >= 1 count in order to trigger the event
# -- child nodes may have their own map configs as well

extends DungeonEntity
class_name TileEvent

var player_on_tile:bool = false
export(int) var max_trigger_count = 1
export(int) var event_trigger_count = 0
export(String) var event_require_item = null
var set_state

func pre_save_game():
	.pre_save_game()
	map_config["event_trigger_count"] = event_trigger_count
	for child in get_children():
		if child.has_method("pre_save_game"):
			child.pre_save_game()
	update_config(map_config)

func _ready() -> void:
	EventBus.connect("tile_entered", self, "tile_entered")

func on_map_place(_dungeon, layer_name:String, cell:Vector2):
	.on_map_place(_dungeon, layer_name, cell)
	for child in get_children():
		Util.config(child, map_config)
		if child.has_method("setup"):
			child.setup(self, map_config)
		if child.has_method("on_map_place"):
			child.on_map_place(_dungeon, layer_name, cell)

func tile_entered(player_coords:Vector2, player):
	if player_coords == self.map_position:
		player_on_tile = true
		trigger_event()
	else:
		player_on_tile = false

func trigger_event():
	if max_trigger_count > 0 and event_trigger_count >= max_trigger_count:
		return
	if event_require_item and GameData.inventory.get(event_require_item, 0) <= 0:
		return
	# Set game state from TileEvent
	var event_set_state = map_config.get("event_set_state", {})
	for k in event_set_state:
		GameData.set_state(k, event_set_state[k])
	# Increment game state from TileEvent
	var event_inc_state = map_config.get("event_inc_state", {})
	for k in event_inc_state:
		Util.inc(GameData.game_state, k, event_inc_state[k])
	for child in get_children():
		if child.has_method("can_trigger_event") and !child.can_trigger_event(self, map_config):
			continue
		if set_state and event_trigger_count == 0:
			for k in set_state:
				GameData.set_state(k, set_state[k])
		if child.has_method("trigger_event"):
			child.trigger_event(self, map_config)
		event_trigger_count += 1
