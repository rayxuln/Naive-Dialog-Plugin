tool
extends TextEdit

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')

var property_def

#----- Methods -----
func set_value(v):
	text = v

func get_value():
	return text

func get_layout_type():
	return PropertyValuePairType.LayoutType.Vertical
#----- Signals -----
func _on_MultiTextEditor_text_changed() -> void:
	emit_signal('value_changed', text)
