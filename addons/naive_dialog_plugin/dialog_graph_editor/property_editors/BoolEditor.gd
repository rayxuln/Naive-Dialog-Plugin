tool
extends CheckBox

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')

var property_def

#----- Methods -----
func set_value(v):
	pressed = v

func get_value(v):
	return pressed

func get_layout_type():
	return PropertyValuePairType.LayoutType.Horizontal
#----- Signals -----
func _on_BoolEditor_toggled(button_pressed: bool) -> void:
	emit_signal('value_changed', button_pressed)
