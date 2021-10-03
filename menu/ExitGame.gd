extends BaseMenuItem

func menu_action(menu):
	GameData.save_settings()
	get_tree().quit()
