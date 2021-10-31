extends Node2D

func _ready():
	EventBus.connect("control_scheme_changed", self, "on_control_scheme_changed")
	on_control_scheme_changed(GameData.get_setting(GameData.UI_PLATFORM, GameData.UI_PLATFORM_PC))

func on_control_scheme_changed(platform):
	for child in get_children():
		child.visible = false
	var active_child = find_node(platform)
	if !active_child:
		active_child = find_node(GameData.UI_PLATFORM_PC)
	active_child.visible = true
	if active_child is AnimatedSprite:
		active_child.frame = 0
		active_child.playing = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
