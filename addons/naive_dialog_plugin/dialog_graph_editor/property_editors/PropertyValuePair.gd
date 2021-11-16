tool
extends VBoxContainer


onready var property_label := $HBoxContainer2/PropertyLabel
onready var editor_container := $HBoxContainer2/HBoxContainer

enum LayoutType {
	Horizontal,
	Vertical,
}

#----- Methods -----
func set_property(p:String):
	property_label.text = p

func set_editor(e):
	if e.get_layout_type() == LayoutType.Horizontal:
		editor_container.add_child(e)
	elif e.get_layout_type() == LayoutType.Vertical:
		add_child(e)

#----- Signals -----
