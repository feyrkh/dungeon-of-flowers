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


var markerPixelsPerSec
var successLineStart
var successLineEnd
var markerResetStyleBounce
var markerDirection
var markerMoveStyle
var isStarted = false
var markerPause = 0

export(NodePath) var dangerLinePath
export(NodePath) var successLinePath
export(NodePath) var markerPath
onready var dangerLine:Line2D = get_node("DangerLine")
onready var marker:Line2D = find_node("Marker")
onready var successLineContainer:Node = find_node("SuccessLines")

var config:Dictionary
var strikesMade:int = 0
var strikeDelay:int = 0

func _ready():
	if get_parent() == get_tree().root:
		setMinigameConfig({
			"markerMoveStyle": Enums.MarkerMoveStyle.WrapRight,
			"markerMoveSpeed": 0.4, # percentage per second; 1 means it will take 1 second, 0.5 means it will take 2 seconds
			"markerMoveDirection": 1, # 1 = to the right, -1 = to the left
			"markerStartPosition": 0, # 0 - 1.0
			"successZones": [
				{"width": 0.05, "position": 0.25, "level": 1, "color": Color.green},
				{"width": 0.03, "position": 0.525, "level": 1.5, "color": Color.orange},
				{"width": 0.01, "position": 0.8, "level": 2, "color": Color.orangered}
			],
			"failureLevel": 0.5,
			"strikes": 3,
			"strikeDelay": 0.1
		})
	setupGame()
	if get_parent() == get_tree().root:
		start()
	
func start():
	isStarted = true

func setMinigameConfig(config):
	self.config = config
	if !config.has("markerMoveStyle"):
		match randi()%4:
			0,1: markerMoveStyle = Enums.MarkerMoveStyle.Bounce
			2: markerMoveStyle = Enums.MarkerMoveStyle.WrapLeft
			3: markerMoveStyle = Enums.MarkerMoveStyle.WrapRight
		config["markerMoveStyle"] = markerMoveStyle
	markerMoveStyle = config["markerMoveStyle"]
	
func setupGame():
	.setupGame()
	
	dangerLine = get_node(dangerLinePath)
	var dangerLineLength = sqrt(pow(dangerLine.points[0].x - dangerLine.points[-1].x, 2) + pow(dangerLine.points[0].y - dangerLine.points[-1].y, 2))
	#successLine = get_node(successLinePath)
	marker = get_node(markerPath)

	for successLineData in config["successZones"]:
		var successLine:Line2D = SuccessLine.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
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
	markerPixelsPerSec = (dangerLine.points[-1].x - dangerLine.points[0].x) * config["markerMoveSpeed"]
	markerDirection = config["markerMoveDirection"]
	if markerDirection == 0: 
		markerDirection = 1
	var markerStartPosition = (dangerLine.points[-1].x - dangerLine.points[0].x)*config["markerStartPosition"] + dangerLine.points[0].x
	moveMarkerTo(markerStartPosition)
	
func _unhandled_key_input(event):
	if !isStarted or strikeDelay > 0: 
		return
	if event.is_action_pressed("ui_accept"):
		var successLevel = getBestSuccessZoneLevel()
		emit_signal("minigame_success", successLevel)
		print("Minigame result: "+str(successLevel))
		#setupGame()
		get_tree().set_input_as_handled()
		strikesMade += 1
		markerPause = 0.15
		Util.shake(self, 0.15, 10)
		if strikesMade >= config.get("strikes", 1):
			end_game()
		else:
			strikeDelay = config.get("strikeDelay", 0)

func markerInsideSuccessZone():
	return getBestSuccessZoneLevel() > config["failureLevel"]

func getBestSuccessZoneLevel():
	var val = config["failureLevel"]
	var markerX = marker.points[0].x
	var markerPosPercent = (markerX - dangerLine.points[0].x)/(dangerLine.points[-1].x - dangerLine.points[0].x) # Should be between 0 and 1
	for successLine in config["successZones"]:
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
	if !isSetup or !isStarted: return
	if markerPause > 0: 
		markerPause -= delta
		return
	strikeDelay = max(0, strikeDelay - delta)
	match markerMoveStyle:
		Enums.MarkerMoveStyle.Bounce: processBounceMove(delta)
		Enums.MarkerMoveStyle.WrapLeft: processWrapLeftMove(delta)
		Enums.MarkerMoveStyle.WrapRight: processWrapRightMove(delta)
	
func processBounceMove(delta):
	var newMarkerX = marker.points[0].x + (markerDirection * markerPixelsPerSec * delta)
	newMarkerX = max(dangerLine.points[0].x, newMarkerX)
	newMarkerX = min(dangerLine.points[-1].x, newMarkerX)
	moveMarkerTo(newMarkerX)
	if newMarkerX == dangerLine.points[0].x: markerDirection = 1
	if newMarkerX == dangerLine.points[1].x: markerDirection = -1
	
func processWrapLeftMove(delta):
	var newMarkerX = marker.points[0].x - (markerPixelsPerSec * delta)
	newMarkerX = max(dangerLine.points[0].x, newMarkerX)
	moveMarkerTo(newMarkerX)
	if newMarkerX == dangerLine.points[0].x: #moveMarkerTo(dangerLine.points[-1].x)
		end_game()

func end_game():
	yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("minigame_complete")
	queue_free() 
	
func processWrapRightMove(delta):
	var newMarkerX = marker.points[0].x + (markerPixelsPerSec * delta)
	newMarkerX = min(dangerLine.points[-1].x, newMarkerX)
	moveMarkerTo(newMarkerX)
	if newMarkerX == dangerLine.points[-1].x:
		emit_signal("minigame_complete")
		queue_free() 
		#moveMarkerTo(dangerLine.points[0].x)
	
func getPowerText(powerLevel):
	match powerLevel:
		0: return "FUEL PUMP NOT PRIMED"
		1: return "FUEL PUMP OPERATING AT MINIMUM CAPACITY"
		2: return "FUEL PUMP OPERATING AT REDUCED CAPACITY"
		3: return "FUEL PUMP OPERATING AT FULL CAPACITY"
