tool
extends LineEdit

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')

var property_def

#----- Methods -----
func set_value(v):
	text = v

func get_value(v):
	return text

func get_layout_type():
	return PropertyValuePairType.LayoutType.Horizontal
#----- Signals -----
func _on_StringEditor_text_changed(new_text: String) -> void:
	emit_signal('value_changed', new_text)
