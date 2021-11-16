tool
extends Control

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')

var list:Array

#----- Methods -----
func set_value(v):
	list = v

func get_value(v):
	return list

func get_layout_type():
	return PropertyValuePairType.LayoutType.Vertical

func update_size():
	rect_size = Vector2.ZERO
#----- Signals -----
