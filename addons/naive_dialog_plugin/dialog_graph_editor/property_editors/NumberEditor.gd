tool
extends LineEdit

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')

var property_def

var type:int

#----- Methods -----
func set_value(v):
	type = typeof(v)
	text = str(v)

func get_value():
	if type == TYPE_INT:
		return int(text)
	return float(text)

func get_layout_type():
	return PropertyValuePairType.LayoutType.Horizontal
#----- Signals -----
func _on_NumberEditor_focus_exited() -> void:
	var val = int(text) if type == TYPE_INT else float(text)
	text = str(val)
	emit_signal('value_changed', val)


func _on_NumberEditor_text_entered(new_text: String) -> void:
	release_focus()
