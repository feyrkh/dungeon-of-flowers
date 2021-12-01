extends Sprite

const colors = [Color.white, Color.yellow, Color.brown, Color.blue, Color.black]

var cur_color = 0
var next_color = 1
var counter = 0

func _process(delta):
	counter += delta
	if counter > 1:
		counter -= 1
		cur_color = (cur_color + 1) % colors.size()
		next_color = (cur_color + 1) % colors.size()
	modulate = lerp(colors[cur_color], colors[next_color], counter)

