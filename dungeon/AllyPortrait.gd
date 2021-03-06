extends Control
class_name AllyPortrait

onready var Portrait:TextureRect = find_node("Portrait")
onready var PortraitSelected:TextureRect = find_node("PortraitBGSelected")
onready var HpLabel:Label = find_node("HpLabel")
onready var SpLabel:Label = find_node("SpLabel")
onready var HpFill:TextureRect = find_node("HpFill")
onready var SpFill:TextureRect = find_node("SpFill")

var data:AllyData
func _ready():
	EventBus.connect("ally_status_updated", self, "_on_ally_status_updated")

func setup(_data:AllyData):
	if _data == null:
		visible = false
		return
	visible = true
	self.data = _data
	Portrait.texture = load(data.texture)

func update_labels():
	HpLabel.text = str(int(data.hp.value)) + "/" + str(int(data.hp.max_value))
	SpLabel.text = str(int(data.sp.value)) + "/" + str(int(data.sp.max_value))
	HpFill.rect_scale.x = data.hp.get_max_value_ratio()
	SpFill.rect_scale.x = data.sp.get_max_value_ratio()

func deselect():
	PortraitSelected.visible = false

func select():
	PortraitSelected.visible = true

func _on_ally_status_updated(_data):
	if self.data != _data:
		return
	update_labels()
