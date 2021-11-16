tool
extends VBoxContainer

signal visible_check_button_toggled(v)

onready var property_label := $HBoxContainer2/PropertyLabel
onready var editor_container := $HBoxContainer2/HBoxContainer
onready var visible_check_button := $HBoxContainer2/HBoxContainer/VisibleCheckButton

enum LayoutType {
	Horizontal,
	Vertical,
}

var property

var editor:Control

#----- Methods -----
func set_property(p):
	property = p
	property_label.text = str(p)

func set_editor(e):
	editor = e
	if e.get_layout_type() == LayoutType.Horizontal:
		editor_container.add_child(e)
		visible_check_button.visible = false
	elif e.get_layout_type() == LayoutType.Vertical:
		add_child(e)
		visible_check_button.visible = true
		e.visible = visible_check_button.pressed

func set_visible_check_button(v:bool):
	visible_check_button.pressed = v
#----- Signals -----
func _on_VisibleCheckButton_toggled(button_pressed: bool) -> void:
	editor.visible = button_pressed
	emit_signal('visible_check_button_toggled', button_pressed)
