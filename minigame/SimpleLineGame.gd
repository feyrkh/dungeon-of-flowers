extends BaseMinigame

const SuccessLine = preload("res://minigame/SuccessLine.tscn")
const Enums = preload("res://Enums.gd")

signal minigame_success(successAmount)
signal minigame_complete

export var minSecondsPerBounce = 0.5
export var maxSecondsPerBounce = 2.0
export var markerSpeedIncreasePerDifficultyLevel = 0.2
export var successWidth = 60
export var successDifficultyPenalty = 15
export var successLineMaxPercentOffsetFromCenter = 100
export(Color) var markerInZoneColor = Color(0, 1.0, 1.0, 1.0)
export(Color) var markerOutOfZoneColor = Color(1.0, 0, 0, 1.0)


var marker_pixels_per_sec
var success_line_start
var success_line_end
var marker_reset_style_bounce
var marker_direction
var marker_move_style
var isStarted = false
var markerPause = 0

export(NodePath) var dangerLinePath
export(NodePath) var successLinePath
export(NodePath) var markerPath
onready var dangerLine:Line2D = get_node("DangerLine")
onready var marker:Line2D = find_node("Marker")
onready var successLineContainer:Node = find_node("SuccessLines")

var config:Dictionary
var strikes_made:int = 0
var strike_delay:float = 0

func _ready():
	if get_parent() == get_tree().root:
		set_minigame_config({
			"marker_move_style": Enums.marker_move_style.WrapRight,
			"marker_move_speed": 0.4, # percentage per second; 1 means it will take 1 second, 0.5 means it will take 2 seconds
			"marker_move_direction": 1, # 1 = to the right, -1 = to the left
			"marker_start_position": 0, # 0 - 1.0
			"success_zones": [
				{"width": 0.05, "position": 0.25, "level": 1, "color": Color.green},
				{"width": 0.03, "position": 0.525, "level": 1.5, "color": Color.orange},
				{"width": 0.01, "position": 0.8, "level": 2, "color": Color.orangered}
			],
			"failure_level": 0.5,
			"strikes": 3,
			"strike_delay": 0.1
		})
	setupGame()
	if get_parent() == get_tree().root:
		start()
	
func start():
	isStarted = true

func set_minigame_config(_config):
	self.config = _config
	if !config.has("marker_move_style"):
		marker_move_style = Enums.MarkerMoveStyle.WrapRight
		config["marker_move_style"] = marker_move_style
	marker_move_style = config["marker_move_style"]
	
func setupGame():
	.setupGame()
	
	dangerLine = get_node(dangerLinePath)
	var dangerLineLength = sqrt(pow(dangerLine.points[0].x - dangerLine.points[-1].x, 2) + pow(dangerLine.points[0].y - dangerLine.points[-1].y, 2))
	#successLine = get_node(successLinePath)
	marker = get_node(markerPath)

	for successLineData in config["success_zones"]:
		var successLine:Line2D = SuccessLine.instance()
		successLineContainer.add_child(successLine)
		var successLineWidth = successLineData["width"]
		var successLineOffset = dangerLineLength * successLineData["position"]
		successLine.points[0].y = dangerLine.points[0].y
		successLine.points[1].y = dangerLine.points[0].y
		successLine.points[2].y = dangerLine.points[0].y
		successLine.points[1].x = successLineOffset+dangerLine.points[0].x
		successLine.points[0].x = successLineOffset-(successLineWidth*dangerLineLength)+dangerLine.points[0].x
		successLine.points[2].x = successLineOffset+(successLineWidth*dangerLineLength)+dangerLine.points[0].x
		successLine.default_color = successLineData["color"]
	#var secondsPerBounce = rand_range(minSecondsPerBounce, maxSecondsPerBounce) -  (markerSpeedIncreasePerDifficultyLevel * difficultyLevel)
	marker_pixels_per_sec = (dangerLine.points[-1].x - dangerLine.points[0].x) * config["marker_move_speed"]
	marker_direction = config.get("marker_move_direction", 1)
	if marker_direction == 0: 
		marker_direction = 1
	var marker_start_position = (dangerLine.points[-1].x - dangerLine.points[0].x)*config.get("marker_start_position", 0) + dangerLine.points[0].x
	moveMarkerTo(marker_start_position)
	
func _unhandled_key_input(event):
	if !isStarted or strike_delay > 0 or strikes_made >= config.get("strikes", 1) or has_meta('game_ending'): 
		return
	if event.is_action_pressed("ui_accept"):
		strike_delay = config.get("strike_delay", 0)
		strikes_made += 1
		var bestSuccessZone = getBestSuccessZoneLevel()
		var pitch_scale = min(4, max(0.01, 1/max(0.01, bestSuccessZone)))
		print("Strike sound pitch: ", pitch_scale)
		AudioPlayerPool.play(preload("res://sound/thump.mp3"), pitch_scale)
		var successLevel = bestSuccessZone * config.get("base_damage", 1)
		emit_signal("minigame_success", successLevel)
		print("Minigame result: "+str(successLevel))
		#setupGame()
		get_tree().set_input_as_handled()
		markerPause = 0.15
		Util.shake(self, 0.15, 1)
		if strikes_made >= config.get("strikes", 1):
			end_game()

func markerInsideSuccessZone():
	return getBestSuccessZoneLevel() > config["failure_level"]

func getBestSuccessZoneLevel():
	var val = config["failure_level"]
	var markerX = marker.points[0].x
	var markerPosPercent = (markerX - dangerLine.points[0].x)/(dangerLine.points[-1].x - dangerLine.points[0].x) # Should be between 0 and 1
	for successLine in config["success_zones"]:
		if markerPosPercent > successLine["position"] - successLine["width"] and markerPosPercent < successLine["position"] + successLine["width"]:
			if successLine["level"] > val: 
				val = successLine["level"]
	return val
	#return (markerX >= successLine.points[0].x) and (markerX <= successLine.points[-1].x)
	
func moveMarkerTo(xCoord):
	marker.points[0].x = xCoord
	marker.points[1].x = xCoord
	setMarkerColor()

func setMarkerColor():
	if markerInsideSuccessZone(): 
		marker.default_color = markerInZoneColor
	else: 
		marker.default_color = markerOutOfZoneColor

func _process(delta):
	if !isSetup or !isStarted or has_meta('game_ending'): return
	if markerPause > 0: 
		markerPause -= delta
		return
	strike_delay = max(0, strike_delay - delta)
	match marker_move_style:
		Enums.MarkerMoveStyle.Bounce: processBounceMove(delta)
		Enums.MarkerMoveStyle.WrapLeft: processWrapLeftMove(delta)
		Enums.MarkerMoveStyle.WrapRight: processWrapRightMove(delta)
	
func processBounceMove(delta):
	var newMarkerX = marker.points[0].x + (marker_direction * marker_pixels_per_sec * delta)
	newMarkerX = max(dangerLine.points[0].x, newMarkerX)
	newMarkerX = min(dangerLine.points[-1].x, newMarkerX)
	moveMarkerTo(newMarkerX)
	if newMarkerX == dangerLine.points[0].x: marker_direction = 1
	if newMarkerX == dangerLine.points[1].x: marker_direction = -1
	
func processWrapLeftMove(delta):
	var newMarkerX = marker.points[0].x - (marker_pixels_per_sec * delta)
	newMarkerX = max(dangerLine.points[0].x, newMarkerX)
	moveMarkerTo(newMarkerX)
	if newMarkerX == dangerLine.points[0].x: #moveMarkerTo(dangerLine.points[-1].x)
		end_game()

func end_game():
	if has_meta('game_ending'):
		return
	set_meta('game_ending', true)
	emit_signal("minigame_complete", self)
	
func processWrapRightMove(delta):
	var newMarkerX = marker.points[0].x + (marker_pixels_per_sec * delta)
	newMarkerX = min(dangerLine.points[-1].x, newMarkerX)
	moveMarkerTo(newMarkerX)
	if newMarkerX == dangerLine.points[-1].x:
		end_game()
		#moveMarkerTo(dangerLine.points[0].x)
	
func getPowerText(powerLevel):
	match powerLevel:
		0: return "FUEL PUMP NOT PRIMED"
		1: return "FUEL PUMP OPERATING AT MINIMUM CAPACITY"
		2: return "FUEL PUMP OPERATING AT REDUCED CAPACITY"
		3: return "FUEL PUMP OPERATING AT FULL CAPACITY"
