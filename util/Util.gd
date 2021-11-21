extends Object
class_name Util

const IGNORE_FIELD_NAMES = ["Reference", "script", "Script Variables"]

static func config(obj, c):
	var props = obj.get_property_list()
	var propNames = {}
	var propTypes = {}
	for prop in props:
		propNames[prop.name] = true
		propTypes[prop.name] = prop.type
	for fieldName in c.keys():
		if propNames.has(fieldName):
			if propTypes[fieldName] == TYPE_OBJECT:
				print("Couldn't restore object: ", fieldName)
			else:
				obj.set(fieldName, c[fieldName])
	if obj.has_method("post_config"):
		obj.post_config(c)
	return obj

static func to_config(obj):
	var props = obj.get_property_list()
	var result = {}
	for prop in props:
		if IGNORE_FIELD_NAMES.find(prop.name) >= 0:
			continue
		result[prop.name] = to_config_field(obj, prop)

	return result

static func to_config_field(obj, prop):
	if prop["type"] == TYPE_OBJECT:
		return to_config(obj.get(prop.name))
	if prop["type"] == TYPE_ARRAY:
		var arr = []
		for entry in obj.get(prop.name):
			if entry is Object:
				arr.append(to_config(entry))
			else:
				arr.append(entry)
		return arr
	else:
		return obj.get(prop.name)

static func inc(dict:Dictionary, key:String, amt, clamp_lower=null, clamp_higher=null):
	dict[key] = dict.get(key,0)+amt
	if clamp_lower != null:
		dict[key] = max(clamp_lower, dict.get(key, 0))
	if clamp_higher != null:
		dict[key] = min(clamp_higher, dict.get(key, 0))

static func delete_children(node):
	for n in node.get_children():
		n.queue_free()

static func randi_range(min_val, max_val):
	min_val = int(round(min_val))
	max_val = int(round(max_val))
	if min_val == max_val:
		return min_val
	return (randi() % (max_val - min_val)) + min_val

static func wrap_range(val, min_val, max_val): 
	if max_val < min_val:
		var swap = min_val
		min_val = max_val
		max_val = swap
	var diff = max_val - min_val
	while val < min_val:
		val += diff
	while val >= max_val:
		val -= diff
	return val
	

static func delay_call(t:float, node:Node, method_name:String, args:Array=[]):
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = t
	node.add_child(timer)
	timer.connect("timeout", node, method_name, args)
	timer.connect("timeout", timer, "queue_free")
	
static func shake(node:Node2D, shakeTime:float, shakeAmt:float, callback_target=null, callback_method=null):
	if !node: 
		return
	if node.has_meta('shaking'):
		return
	node.set_meta('shaking', true)
	var startPos = node.position
	var startTime = OS.get_system_time_msecs()
	var endTime = startTime + round(shakeTime*1000)
	while OS.get_system_time_msecs() < endTime:
		if !node or !is_instance_valid(node): return
		node.position = startPos + Vector2(rand_range(-shakeAmt, shakeAmt), rand_range(-shakeAmt, shakeAmt))
		yield(node.get_tree().create_timer(0.05), "timeout")
	if !node or !is_instance_valid(node): 
		return
	node.position = startPos
	node.remove_meta('shaking')
	if callback_target and callback_method and callback_target.has_method(callback_method):
		callback_target.call_deferred(callback_method)

static func fadeout(node:Node2D, time:float):
	if !node: 
		return
	if node.has_meta('fadeout'):
		return
	node.set_meta('fadeout', true)
	var i = 1
	while i >= 0:
		i-=0.05
		node.modulate = (Color(1, 1, 1, i))
		yield(node.get_tree().create_timer(0.05), "timeout")
		if !node:
			return
	node.remove_meta('fadeout')

static func get_decibels_for_volume_percentage(volume_percent): # 0 - 100.0 range, usually
	volume_percent = volume_percent / 100.0
	return (60.0 * volume_percent) - 60 # range goes from -80 decibels (silent?) to 0 (normal) or higher (really loud)

func get_areas_at_position(source:Node2D):
	var target_areas = source.get_world_2d().direct_space_state.intersect_point(source.global_position, 32, [], 2, false, true)
	print("On top of ", target_areas.size(), " targets")
	for target in target_areas:
		print("  mult: ", target["collider"].multiplier)

static func read_json(filename, default: Dictionary={}) -> Dictionary:
	return DialogicResources.load_json(filename, default)

static func one_shot_tween(parent) -> Tween:
	var tween = Tween.new()
	parent.add_child(tween)
	tween.connect("tween_all_completed", tween, "queue_free")
	return tween

static func read_text(filename, default=null):
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		file.close()
		return default
	var data_text: String = file.get_as_text()
	file.close()
	return data_text

static func read_lines(filename, default=null):
	var text = read_text(filename)
	if text == null:
		return default
	return text.split("\n")

static func pre_save_game(object:Object, prefix:String, save_items:Array):
	for item in save_items:
		var val = object.get(item)
		GameData.set_state(prefix+item, val)

static func post_load_game(object, prefix:String, save_items:Array):
	for item in save_items:
		var val = GameData.get_state(prefix+item)
		if val == null:
			val = object.get(item)
		object.set(item, val)
		
