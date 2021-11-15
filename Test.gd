extends Node


func _process(delta: float) -> void:
	if $Runtime.is_dialog_started() and Input.is_action_just_pressed('ui_accept'):
		if $Control/Label/Tween.is_active():
			$Control/Label/Tween.stop_all()
			$Control/Label.percent_visible = 1.0
			if $Runtime.current_node and $Runtime.current_node.data.type == 0:
				$Control/Label/TipLabel.visible = true
		else:
			if $Runtime.current_node and $Runtime.current_node.data.type == 0:
				$Runtime.advance()
#----- Methods -----

#----- Signals -----
func _on_StartButton_pressed() -> void:
	$Runtime.start_dialog()


func _on_Runtime_request_advance(runtime, current_node) -> void:
	$Control/Label.visible = true
	if current_node.data.type == 0:
		$Control/Label.bbcode_text = '%s' % [current_node.data.text]
	else:
		var list = current_node.data.selection_list
		var msg = ''
		var count = 0
		for s in list:
			msg += '[url=%s]%s. %s[/url]\n' % [count, count, s]
			count += 1
		$Control/Label.bbcode_text = '%s:\n%s' % [current_node.data.text, msg]
	$Control/Label/Tween.stop_all()
	$Control/Label/Tween.interpolate_property($Control/Label, 'percent_visible', 0, 1, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Control/Label/Tween.start()
	$Control/Label/TipLabel.visible = false

func _on_Runtime_dialog_advanced(runtime, current_node) -> void:
	if current_node == null:
		$Control/Label.visible = false
		return
	$Control/Label/TipLabel.visible = false
	print('diolog advanced to: %s' % [current_node.id])


func _on_Label_meta_clicked(meta) -> void:
	$Runtime.advance({
		'selection': int(meta),
	})


func _on_Tween_tween_all_completed() -> void:
	if $Runtime.current_node and $Runtime.current_node.data.type == 0:
		$Control/Label/TipLabel.visible = true
