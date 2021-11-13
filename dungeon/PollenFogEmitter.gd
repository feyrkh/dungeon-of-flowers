extends Spatial

const PARTICLES_PER_POLLEN_LEVEL = 50
const LIFETIME_PER_POLLEN_LEVEL = 3

var map_position:Vector2
var map_layer:String
var pollen_level = 0

func _ready():
	EventBus.connect("new_player_location", self, "new_player_location")

func new_player_location(x, y, rot):
	if Vector2(x,y).distance_squared_to(map_position) > 100:
		$Particles.emitting = false
		pollen_level = -1
		return
	var new_pollen = GameData.dungeon.get_pollen_level(map_position.x, map_position.y)
	if new_pollen == pollen_level:
		return
	pollen_level = new_pollen
	if pollen_level == 0:
		$Particles.emitting = false
		return
	$Particles.emitting = true
	$Particles.amount = pollen_level * PARTICLES_PER_POLLEN_LEVEL
	$Particles.lifetime = pollen_level * LIFETIME_PER_POLLEN_LEVEL
	
func on_map_place(dungeon, layer_name:String, cell:Vector2):
	self.map_position = cell
	self.map_layer = layer_name
