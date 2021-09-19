extends TextureButton

var allyData

func setup(_allyData):
	allyData = _allyData

func is_selectable():
	return true
