extends Node2D

const SCREEN_WIDTH = 1920

var shield_data
var shield_owner

func setup(_shield_data, _shield_owner):
	self.shield_owner = _shield_owner
	self.shield_data = _shield_data
	var gray = randf()*0.3 + 0.7
	self.modulate = Color(gray, gray, gray)
	if shield_data.get("shield_damage", 0) >= shield_data.get("shield_strength", 12):
		queue_free()
		return
	get_weakness()

func get_weakness():
	var weakness_ratio = float(shield_data.get("shield_damage", 0)) / shield_data.get("shield_strength", 12)
	self.modulate = Color(1.0, 1.0-weakness_ratio, 1.0-weakness_ratio)
	return weakness_ratio

func _on_Area2D_body_entered(bullet:Node2D):
	var dmg = bullet.shield_block(self, max(0, shield_data.get("shield_strength", 12) - shield_data.get("shield_damage", 0)))
	shield_data["shield_damage"] = min(shield_data.get("shield_strength", 12), shield_data.get("shield_damage", 0) + dmg)
	if shield_data.get("shield_damage", 0) >= shield_data.get("shield_strength", 12):
		shield_owner.destroy_module(self)
		queue_free()
	get_weakness()
	EventBus.emit_signal("refresh_bonus_icons")
