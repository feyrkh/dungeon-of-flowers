extends MapEntity

const OVER_DRAIN_RATE = 0.05

var element = null
var threshold = 1.0
var threshold_upgrades = 0 # each upgrade gives +0.25 max threshold over the default threshold of 1.0
var efficiency = 1.0
var investment = null
var accumulated = 0
var last_direction:Vector2 = Vector2.UP

func _process(delta):
	if accumulated > threshold*3:
		accumulated = max(threshold, accumulated - delta*OVER_DRAIN_RATE * (accumulated/threshold))
	else:
		set_process(false)

func grias_pre_save_levelup():
	var save_data = {
		"element": element,
		"threshold": threshold,
		"threshold_upgrades": threshold_upgrades,
		"efficiency": efficiency,
		"investment": investment,
		"accumulated": accumulated,
		"last_direction": last_direction,
	}
	update_config(save_data)

func on_map_place(_tilemap_mgr, layer_name:String, cell:Vector2):
	.on_map_place(_tilemap_mgr, layer_name, cell)
	position = position + Vector2(32, 32)
	EventBus.emit_signal("grias_reset_focus_power_cache")
	render_component()
	set_process(true)

func get_component_label():
	if element != null:
		return "Compressed Energy (%s: %.2f)" % [C.element_name(element), accumulated]
	else:
		return "Compressed Energy (empty)"

func get_description():
	return "A support node which can merge multiple sparks of energy together, compressing them into a single more powerful spark, or split powerful sparks into multiple weaker sparks.\nMerging different elements will drain energy."

func get_component_menu_items():
	var menu_items = []
	EventBus.emit_signal("grias_component_description", get_description())
	var compress_item = preload("res://levelup/menu_items/CompressAmountMenuItem.tscn").instance()
	compress_item.setup(self)
	menu_items.append(compress_item)
	var improve_item = preload("res://levelup/menu_items/CompressImproveMenuItem.tscn").instance()
	improve_item.setup(self)
	menu_items.append(improve_item)
	var delete_item = preload("res://levelup/menu_items/DeleteNodeMenuItem.tscn").instance()
	delete_item.setup(self, tilemap_mgr, GameData.partial_investment_refund(investment), map_position)
	menu_items.append(delete_item)
	return menu_items

func _ready() -> void:
	EventBus.connect("grias_pre_save_levelup", self, "grias_pre_save_levelup")
	render_component()

func render_component():
	if element != null:
		modulate = C.element_color(element)
	else:
		modulate = Color.white

func spark_arrived(spark, tile_coords):
	spark.add_meridian_energy(1.0)
	EventBus.emit_signal("grias_levelup_fail_clear_fog", map_position, C.element_color(spark.element))
	var new_energy = spark.energy
	var new_element = spark.element
	if spark.element != element:
		if new_energy > accumulated:
			element = spark.element
			accumulated = new_energy - accumulated
		else:
			accumulated -= new_energy
	else:
		accumulated += new_energy
	last_direction = spark.direction
	spark.queue_free()
	set_process(true)

func check_new_spark():
	if accumulated < threshold:
		return
	accumulated -= threshold
	var spark = preload("res://levelup/GriasSpark.tscn").instance()
	spark.setup_non_core(last_direction, map_position, tilemap_mgr, position, element)
	spark.energy = threshold
	EventBus.emit_signal("grias_compress_energy", spark)
	spark.begin_move(map_position, map_position + last_direction)


func _on_Timer_timeout() -> void:
	check_new_spark()
