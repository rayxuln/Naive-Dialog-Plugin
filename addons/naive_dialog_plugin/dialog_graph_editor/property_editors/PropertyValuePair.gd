tool
extends Control

signal visible_check_button_toggled(v)
signal request_edit_property()
signal request_change_property()

onready var property_label := $VBoxContainer/HBoxContainer2/PropertyLabel
onready var editor_container := $VBoxContainer/HBoxContainer2/HBoxContainer
onready var editor_ext_container := $VBoxContainer
onready var visible_check_button := $VBoxContainer/HBoxContainer2/HBoxContainer/VisibleCheckButton
onready var property_line_edit := $VBoxContainer/HBoxContainer2/PropertyLineEdit

enum LayoutType {
	Horizontal,
	Vertical,
}

var property
var property_def

var editor:Control

#----- Methods -----
func set_property(p, p_def = null):
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
	
func set_edit_mode(b):
	if b:
		property_line_edit.text = property
	else:
		property = property_line_edit.text
		property_label.text = property
	property_line_edit.visible = b
	property_label.visible = not b
#----- Signals -----
func _on_VisibleCheckButton_toggled(button_pressed: bool) -> void:
	editor.visible = button_pressed
	emit_signal('visible_check_button_toggled', button_pressed)


func _on_PropertyLabel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.doubleclick:
			emit_signal('request_edit_property')


func _on_PropertyLineEdit_text_entered(new_text: String) -> void:
	property_line_edit.release_focus()

func _on_PropertyLineEdit_focus_exited() -> void:
	emit_signal('request_change_property')
