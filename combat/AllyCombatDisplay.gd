extends Control

onready var Portrait:TextureRect = find_node("Portrait")
onready var HpLabel:RichTextLabel = find_node("HpLabel")
onready var SpLabel:RichTextLabel = find_node("SpLabel")
onready var HpFill:TextureRect = find_node("HpFill")
onready var SpFill:TextureRect = find_node("SpFill")
onready var CombatIcons = find_node("CombatIcons")
onready var default_position = rect_position
onready var selected_position = rect_position - Vector2(0, 20)

export(Color) var selected_color = Color.white
export(Color) var deselected_color = Color(0.8, 0.8, 0.8)

var allyData:AllyData

func setup(_allyData:AllyData):
	Portrait.texture = _allyData.texture
	self.allyData = _allyData
	updateLabels()

func updateLabels():
	HpLabel.bbcode_text = str(allyData.hp) + "/" + str(allyData.max_hp)
	SpLabel.bbcode_text = str(allyData.sp) + "/" + str(allyData.max_sp)
	HpFill.rect_scale.x = float(allyData.hp) / float(allyData.max_hp)
	SpFill.rect_scale.x = float(allyData.sp) / float(allyData.max_sp)

func deselect():
	CombatIcons.hide()
	modulate = deselected_color
	rect_position = default_position

func select(category_idx):
	CombatIcons.show(category_idx)
	modulate = selected_color
	rect_position = selected_position

func select_category(selected_category_idx, direction):
	return CombatIcons.select_next_category(selected_category_idx, direction)
