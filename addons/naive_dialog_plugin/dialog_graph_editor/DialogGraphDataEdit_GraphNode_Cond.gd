tool
extends Control

signal request_selected
signal text_changed(old_text, new_text)

signal request_up
signal request_down

var normal_bg_alpha := 0.0
var selected_bg_alpha := 0.35

var selected := false

var id
#----- Methods -----
func get_line_edit():
	return $HBoxContainer/LineEdit

func set_selected(v:bool):
	selected = v
	var style:StyleBoxFlat = get_stylebox('panel')
	if selected:
		style.bg_color.a = selected_bg_alpha
	else:
		style.bg_color.a = normal_bg_alpha
#----- Signals -----
func _on_LineEdit_focus_entered() -> void:
	emit_signal('request_selected')


func _on_LineEdit_text_changed(new_text: String) -> void:
	emit_signal('text_changed', get_line_edit().text, new_text)


func _on_UpButton_pressed() -> void:
	emit_signal('request_up')


func _on_DownButton_pressed() -> void:
	emit_signal('request_down')
