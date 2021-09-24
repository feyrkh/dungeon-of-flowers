extends Object
class_name Util

static func config(obj, c):
	var props = obj.get_property_list()
	var propNames = {}
	for prop in props:
		propNames[prop.name] = true
	for fieldName in c.keys():
		if propNames.has(fieldName):
			obj.set(fieldName, c[fieldName])
	if obj.has_method("post_config"):
		obj.post_config(c)
	return obj

static func delete_children(node):
	for n in node.get_children():
		n.queue_free()

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

