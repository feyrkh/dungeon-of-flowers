extends Control

signal cancel_submenu
signal select_submenu_item(item_idx)

onready var Portrait:TextureRect = find_node("Portrait")
onready var PortraitSelected:TextureRect = find_node("PortraitBGSelected")
onready var HpLabel:RichTextLabel = find_node("HpLabel")
onready var SpLabel:RichTextLabel = find_node("SpLabel")
onready var HpFill:TextureRect = find_node("HpFill")
onready var SpFill:TextureRect = find_node("SpFill")
onready var CombatIcons = find_node("CombatIcons")
onready var Submenu = find_node("Submenu")
onready var default_position = rect_position
onready var selected_position = rect_position - Vector2(0, 20)
onready var category_zoom_icons = [find_node("IconZoomFight"), find_node("IconZoomSkill"), find_node("IconZoomDefend"), find_node("IconZoomItem")]

export(Color) var selected_color = Color.white
export(Color) var deselected_color = Color(0.8, 0.8, 0.8)

var allyData:AllyData
var last_category_idx

func setup(_allyData:AllyData):
	Portrait.texture = _allyData.texture
	self.allyData = _allyData
	updateLabels()

func _ready():
	CombatIcons.categories.append(find_node("IconStatus"))

func updateLabels():
	HpLabel.bbcode_text = str(allyData.hp) + "/" + str(allyData.max_hp)
	SpLabel.bbcode_text = str(allyData.sp) + "/" + str(allyData.max_sp)
	HpFill.rect_scale.x = float(allyData.hp) / float(allyData.max_hp)
	SpFill.rect_scale.x = float(allyData.sp) / float(allyData.max_sp)

func deselect():
	PortraitSelected.visible = false
	CombatIcons.hide()
	modulate = deselected_color
	rect_position = default_position

func select(category_idx):
	PortraitSelected.visible = true
	CombatIcons.show(category_idx)
	modulate = selected_color
	rect_position = selected_position
	return category_idx

func select_category(selected_category_idx, direction):
	return CombatIcons.select_next_category(selected_category_idx, direction)

func select_status_category():
	return CombatIcons.select(4)

func select_no_category():
	CombatIcons.select_no_category()
	
func open_category_submenu(category_idx):
	for icon in category_zoom_icons:
		icon.visible = false
	last_category_idx = category_idx
	category_zoom_icons[category_idx].visible = true
	CombatIcons.hide()
	Submenu.show()

func _on_Submenu_cancel_submenu():
	CombatIcons.show(last_category_idx)
	category_zoom_icons[last_category_idx].visible = false
	emit_signal("cancel_submenu")
