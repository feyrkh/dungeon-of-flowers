extends Control

const TOTAL_VISIBLE_TIME:float = 10.0
const FADE_IN_TIME:float = 9.5
const FADE_OUT_TIME:float = 0.5

const pollen_exposure_per_threat_level = 20
var threat_level = 0
var force_visible_time = 0

export(NodePath) var idleHudPath:NodePath
var idleHud

onready var ThreatFill:TextureRect = find_node("ThreatFill")
onready var ThreatLevelLabel:Label = find_node("ThreatLevelLabel")

const SAVE_ITEMS = ["threat_level"]
const SAVE_PREFIX = "ThrtLvl_"
func pre_save_game():
	Util.pre_save_game(self, SAVE_PREFIX, SAVE_ITEMS)

func post_load_game():
	Util.post_load_game(self, SAVE_PREFIX, SAVE_ITEMS)
	accumulate_threat(0)

func _ready():
	idleHud = get_node(idleHudPath)
	accumulate_threat(0)
	EventBus.connect("tile_entered", self, "tile_entered")
	EventBus.connect("pre_save_game", self, "pre_save_game")
	EventBus.connect("post_load_game", self, "post_load_game")

func tile_entered(player_coords:Vector2, player):
	accumulate_threat(GameData.dungeon.get_pollen_level(player_coords))

func accumulate_threat(pollen_level):
	var prev_level = int(threat_level)
	if threat_level < 0:
		threat_level = 0
	if pollen_level < 0:
		pollen_level = 0
	var divisor = floor(threat_level) + 1
	threat_level += (pollen_level/divisor) / pollen_exposure_per_threat_level
	ThreatFill.rect_scale.x = threat_level - int(threat_level)

	if prev_level != int(threat_level):
		if force_visible_time <= 0:
			force_visible_time = TOTAL_VISIBLE_TIME
		elif force_visible_time < FADE_OUT_TIME:
			force_visible_time = TOTAL_VISIBLE_TIME - force_visible_time # fade back in starting from our current opacity
		elif force_visible_time >= FADE_OUT_TIME:
			force_visible_time = FADE_IN_TIME # we're already visible (or maybe partly visible, but there's no scenario where we should be bumping up multiple threat levels in less than half a second but not instantly)
	ThreatLevelLabel.text = "THREAT LEVEL "+str(int(threat_level))

func _process(delta:float):
	if force_visible_time > 0:
		force_visible_time -= delta
		if force_visible_time < 0:
			force_visible_time = 0
		if force_visible_time > FADE_IN_TIME:
			modulate.a = 1.0 - ((force_visible_time - FADE_IN_TIME) / (TOTAL_VISIBLE_TIME - FADE_IN_TIME))
		elif force_visible_time < FADE_OUT_TIME:
			modulate.a = force_visible_time / FADE_OUT_TIME
		else:
			modulate.a = 1
	else:
		modulate.a = idleHud.modulate.a

