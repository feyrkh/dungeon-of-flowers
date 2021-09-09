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

static func shake(node:Node2D, shakeTime:float, shakeAmt:float):
	var startPos = node.position
	var startTime = OS.get_system_time_msecs()
	var endTime = startTime + round(shakeTime*1000)
	while OS.get_system_time_msecs() < endTime:
		if !node: return
		node.position = startPos + Vector2(rand_range(-shakeAmt, shakeAmt), rand_range(-shakeAmt, shakeAmt))
		yield(node.get_tree().create_timer(0.05), "timeout")
	node.position = startPos
