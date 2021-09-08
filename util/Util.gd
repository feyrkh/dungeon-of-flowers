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

