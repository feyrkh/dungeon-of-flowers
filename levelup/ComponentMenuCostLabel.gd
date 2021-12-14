extends Label


func _ready():
	EventBus.connect("grias_component_cost", self, "grias_component_cost")

func grias_component_cost(cost_map):
	visible = cost_map != null and cost_map.size() != 0
