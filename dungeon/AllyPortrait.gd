extends Control
class_name AllyPortrait

onready var Portrait:TextureRect = find_node("Portrait")
onready var PortraitSelected:TextureRect = find_node("PortraitBGSelected")
onready var HpLabel:Label = find_node("HpLabel")
onready var SpLabel:Label = find_node("SpLabel")
onready var HpFill:TextureRect = find_node("HpFill")
onready var SpFill:TextureRect = find_node("SpFill")

var ally_data:AllyData

func _ready():
	EventBus.connect("ally_status_updated", self, "_on_ally_status_updated")

func setup(_ally_data:AllyData):
	self.ally_data = _ally_data
	Portrait.texture = ally_data.texture

func update_labels():
	HpLabel.text = str(ally_data.hp) + "/" + str(ally_data.max_hp)
	SpLabel.text = str(ally_data.sp) + "/" + str(ally_data.max_sp)
	HpFill.rect_scale.x = float(ally_data.hp) / float(ally_data.max_hp)
	SpFill.rect_scale.x = float(ally_data.sp) / float(ally_data.max_sp)

func deselect():
	PortraitSelected.visible = false

func select():
	PortraitSelected.visible = true

func _on_ally_status_updated(_ally_data):
	if self.ally_data != _ally_data:
		return
	update_labels()
