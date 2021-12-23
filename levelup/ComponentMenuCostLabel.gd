extends Label


func _ready():
	EventBus.connect("grias_component_cost", self, "grias_component_cost")
	EventBus.connect("grias_component_refund", self, "grias_component_refund")

func grias_component_cost(cost_map):
	if cost_map != null and cost_map.size() != 0:
		text = "Cost: "
	else:
		text = " "

func grias_component_refund(cost_map):
	if cost_map != null and cost_map.size() != 0:
		text = "Refund: "
	else:
		text = " "

