tool
extends EditorPlugin

var dialog_graph_editor = preload('./dialog_graph_editor/DialogGraphEditor.tscn').instance()

func _enter_tree() -> void:
	dialog_graph_editor.the_plugin = self
	get_editor_interface().get_editor_viewport().add_child(dialog_graph_editor)
	make_visible(false)


func _exit_tree() -> void:
	dialog_graph_editor.queue_free()


func has_main_screen():
		return true


func make_visible(visible):
		dialog_graph_editor.visible = visible


func get_plugin_name():
		return "Naive Dialog Plugin"


func get_plugin_icon():
		return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")


func edit(object: Object) -> void:
	if object is DialogGraphData:
		dialog_graph_editor.edit(object)

func handles(object: Object) -> bool:
	return object is DialogGraphData

func save_external_data() -> void:
	dialog_graph_editor.on_save()

func apply_changes() -> void:
	dialog_graph_editor.on_save()

func build() -> bool:
	dialog_graph_editor.on_save()
	return true
