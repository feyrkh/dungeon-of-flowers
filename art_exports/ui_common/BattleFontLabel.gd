extends Node2D

const chars = {
	"0": ("res://art_exports/ui_common/0.tres"),
	"1": ("res://art_exports/ui_common/1.tres"),
	"2": ("res://art_exports/ui_common/2.tres"),
	"3": ("res://art_exports/ui_common/3.tres"),
	"4": ("res://art_exports/ui_common/4.tres"),
	"5": ("res://art_exports/ui_common/5.tres"),
	"6": ("res://art_exports/ui_common/6.tres"),
	"7": ("res://art_exports/ui_common/7.tres"),
	"8": ("res://art_exports/ui_common/8.tres"),
	"9": ("res://art_exports/ui_common/9.tres"),
	"x": ("res://art_exports/ui_common/x.tres"),
	"%": ("res://art_exports/ui_common/percent.tres"),
}

export(String) var text:String = "9" setget set_text
export(bool) var center:bool = true

func _ready():
	set_text(text)

func set_text(val:String):
	text = val
	Util.delete_children(self)
	var total_width = 0
	for c in text:
		var char_scene = chars.get(c)
		if char_scene != null:
			var atlas_tex:AtlasTexture = load(char_scene)
			var char_node = Sprite.new()
			char_node.centered = false
			char_node.texture = atlas_tex
			add_child(char_node)
			char_node.position = Vector2(total_width, -atlas_tex.get_height()/2)
			total_width += atlas_tex.get_width()
	if center:
		var half_width = total_width / 2
		for child in get_children():
			child.position.x -= half_width
			
			
	
