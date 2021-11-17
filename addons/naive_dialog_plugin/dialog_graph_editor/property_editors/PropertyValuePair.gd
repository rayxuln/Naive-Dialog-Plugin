tool
extends Control

signal visible_check_button_toggled(v)

onready var property_label := $VBoxContainer/HBoxContainer2/PropertyLabel
onready var editor_container := $VBoxContainer/HBoxContainer2/HBoxContainer
onready var editor_ext_container := $VBoxContainer
onready var visible_check_button := $VBoxContainer/HBoxContainer2/HBoxContainer/VisibleCheckButton

enum LayoutType {
	Horizontal,
	Vertical,
}

var property
var property_def

var editor:Control

#----- Methods -----
func set_property(p, p_def):
	property = p
	property_def = p_def
	property_label.text = str(p)

func set_editor(e):
	editor = e
	editor.property_def = property_def
	if e.get_layout_type() == LayoutType.Horizontal:
		editor_container.add_child(e)
		visible_check_button.visible = false
	elif e.get_layout_type() == LayoutType.Vertical:
		editor_ext_container.add_child(e)
		visible_check_button.visible = true
		e.visible = visible_check_button.pressed

func set_visible_check_button(v:bool):
	visible_check_button.pressed = v
#----- Signals -----
func _on_VisibleCheckButton_toggled(button_pressed: bool) -> void:
	editor.visible = button_pressed
	emit_signal('visible_check_button_toggled', button_pressed)
