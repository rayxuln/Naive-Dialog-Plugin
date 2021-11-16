tool
extends Control

const TITLE_TEXT := 'Naive Dialog Editor'
const RESOURCE_EXT := 'tres'

var the_plugin:EditorPlugin

onready var dialog_graph_data_edit := $VBoxContainer/DialogGraphDataEdit
onready var title_label := $VBoxContainer/HBoxContainer/TitleLabel
onready var file_menu_button := $VBoxContainer/HBoxContainer/FileMenuButton
onready var save_file_dialog := $SaveFileDialog
onready var alert_dialog := $AlertDialog
onready var override_confirmation_dialog := $OverrideConfirmationDialog

var saved_undoredo_version:int

var new_node_data_stack := []
var deleted_node_data_stack := []

func _ready() -> void:
	if the_plugin == null:
		return
	the_plugin.get_undo_redo().connect('version_changed', self, '_on_undoredo_version_changed')
	create_file_menu()
#----- File Menus -----
var file_menu_new_name := tr('New')
var file_menu_save_name := tr('Save')
var file_menu_save_as_name := tr('Save As')
enum FileMenuId{
	New = 0,
	Save,
	SaveAs,
}
#----- Methods -----
func is_dirty():
	var undoredo = the_plugin.get_undo_redo()
	return undoredo.get_version() != saved_undoredo_version

func create_file_menu():
	var menu:PopupMenu = file_menu_button.get_popup()
	menu.add_item(file_menu_new_name, FileMenuId.New)
	menu.add_separator()
	menu.add_item(file_menu_save_name, FileMenuId.Save)
	menu.add_item(file_menu_save_as_name, FileMenuId.SaveAs)
	
	menu.connect('id_pressed', self, '_on_file_menu_id_pressed')
	

func choose_save_path():
	save_file_dialog.popup_centered()
	

func edit(dialog_graph_data:DialogGraphData):
	saved_undoredo_version = the_plugin.get_undo_redo().get_version()
	new_node_data_stack.clear()
	deleted_node_data_stack.clear()
	update_dialog_graph_data_edit(dialog_graph_data)
	update_title()
	print('edit')

func update_title():
	var res_path := ''
	if get_dialog_graph_data() != null:
		res_path = get_dialog_graph_data().resource_path
	
	if res_path.empty():
		title_label.text = TITLE_TEXT
	else:
		title_label.text = '%s - %s' % [TITLE_TEXT, res_path]
	if is_dirty():
		title_label.text += '*'

func update_dialog_graph_data_edit(dialog_graph_data:DialogGraphData):
	dialog_graph_data_edit.set_data(dialog_graph_data)
	

func get_dialog_graph_data() -> DialogGraphData:
	return dialog_graph_data_edit.dialog_graph_data

func save():
	var res_path = get_dialog_graph_data().resource_path
	var err = ResourceSaver.save(res_path, get_dialog_graph_data())
	if err != OK:
		error('Can\'t save resource to: %s, code: %s' % [res_path, err])
		return
	saved_undoredo_version = the_plugin.get_undo_redo().get_version()
	update_title()

func save_to(path):
	var res_path = get_dialog_graph_data().resource_path
	if path == res_path:
		save()
		return
	var err = ResourceSaver.save(path, get_dialog_graph_data())
	if err != OK:
		error('Can\'t save resource to: %s, code: %s' % [path, err])
		return
	saved_undoredo_version = the_plugin.get_undo_redo().get_version()
	edit(load(path))

func on_save():
	if not is_dirty():
		return
	if get_dialog_graph_data().resource_path.empty():
		error('The path of dialog graph data is not set', false, true)
		return
	save()

func on_show():
	if get_dialog_graph_data() == null:
		update_dialog_graph_data_edit(DialogGraphData.new())
		update_title()

func on_hide():
	pass

func error(msg, alert:=true, output:=true):
	if output:
		printerr(msg)
	if alert:
		alert_dialog.dialog_text = msg
		alert_dialog.popup_centered()
#----- Dos&Undos ------
func _undo_redo_create_node(def_type_name):
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Create \'%s\' Node' % def_type_name)
	undoredo.add_do_method(self, '_do_create_node', def_type_name)
	undoredo.add_undo_method(self, '_undo_create_node')
	undoredo.commit_action()
func _do_create_node(def_type_name):
	var id = dialog_graph_data_edit.create_new_node_at(dialog_graph_data_edit.gen_data_from_data_def_name(def_type_name), dialog_graph_data_edit.popup_local_mouse_position + dialog_graph_data_edit.scroll_offset)
	new_node_data_stack.push_back(dialog_graph_data_edit.id_node_map[id].data)
func _undo_create_node():
	var data = new_node_data_stack.pop_back()
	dialog_graph_data_edit.remove_node(data.id)

func _undo_redo_remove_node(node_data):
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Remove Node: \'%s\' - [%s]' % [node_data.def.type, node_data.id])
	undoredo.add_do_method(self, '_do_remove_node', node_data)
	undoredo.add_undo_method(self, '_undo_remove_node')
	undoredo.commit_action()
func _do_remove_node(node_data):
	deleted_node_data_stack.push_back(node_data)
	dialog_graph_data_edit.remove_node(node_data.id)
func _undo_remove_node():
	var node_data = deleted_node_data_stack.pop_back()
	dialog_graph_data_edit.create_node_with_data(node_data)

func _undo_redo_resize_node(node, min_size):
	node.rect_min_size = min_size
#	var undoredo := the_plugin.get_undo_redo()
#	undoredo.create_action('Resize Node: \'%s\' - [%s]' % [node.data.def.type, node.data.id])
#	undoredo.add_do_method(self, '_do_resize_node', node, min_size)
#	undoredo.add_undo_method(self, '_undo_resize_node', node, node.rect_min_size)
#	undoredo.commit_action()
#func _do_resize_node(node:Control, min_size):
#	node.rect_min_size = min_size
#func _undo_resize_node(node, min_size):
#	node.rect_min_size = min_size

func _undo_redo_dragged_node(node, old_pos, new_pos):
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Dragged Node: \'%s\' - [%s]' % [node.data.def.type, node.data.id])
	undoredo.add_do_property(node, 'offset', new_pos)
	undoredo.add_undo_property(node, 'offset', old_pos)
	undoredo.commit_action()

func _undo_redo_update_edge_list_node(node, old_edge_list, new_edge_list):
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Node: \'%s\' - [%s] => change condition list' % [node.data.def.type, node.data.id])
	undoredo.add_do_method(self, '_do_update_edge_list_node', node, new_edge_list)
	undoredo.add_undo_method(self, '_do_update_edge_list_node', node, old_edge_list)
	undoredo.commit_action()
func _do_update_edge_list_node(node, list):
	node.edge_list.clear()
	node.edge_list.append_array(list)
	node.update_content()
#----- Signals -----
func _on_file_menu_id_pressed(id:int):
	match id:
		FileMenuId.New:
			if is_dirty():
				override_confirmation_dialog.popup_centered()
			else:
				update_dialog_graph_data_edit(DialogGraphData.new())
				update_title()
				saved_undoredo_version = the_plugin.get_undo_redo().get_version()
		FileMenuId.Save:
			if get_dialog_graph_data().resource_path.empty():
				choose_save_path()
			else:
				save()
		FileMenuId.SaveAs:
			choose_save_path()

func _on_DialogGraphEditor_visibility_changed() -> void:
	if the_plugin == null:
		return
	if is_visible_in_tree():
		on_show()
	else:
		on_hide()


func _on_SaveFileDialog_file_selected(path: String) -> void:
	if path.empty():
		return
	if not path.is_abs_path() and not path.is_rel_path():
		error('The path is invalid: %s' % path, true, false)
		return
	if path.get_file().empty():
		return
	var dir = Directory.new()
	if dir.dir_exists(path):
		error('You need to choose a file path not a directory! => "%s"' % path, true, false)
		return
	if path.get_extension().empty():
		path = '%s.%s' % [path, RESOURCE_EXT]
	if dir.file_exists(path):
		error('The file: "%s" already exists!' % path, true, false)
		return
	save_to(path)


func _on_DialogGraphDataEdit_request_create_node(def_type_name) -> void:
	_undo_redo_create_node(def_type_name)

func _on_undoredo_version_changed():
	update_title()


func _on_DialogGraphDataEdit_requst_remove_node(node_data) -> void:
	_undo_redo_remove_node(node_data)


func _on_DialogGraphDataEdit_requst_resize_node(node, min_size) -> void:
	_undo_redo_resize_node(node, min_size)


func _on_DialogGraphDataEdit_node_dragged(node, old_pos, new_pos) -> void:
	_undo_redo_dragged_node(node, old_pos, new_pos)


func _on_OverrideConfirmationDialog_confirmed() -> void:
	update_dialog_graph_data_edit(DialogGraphData.new())
	update_title()
	saved_undoredo_version = the_plugin.get_undo_redo().get_version()


func _on_DialogGraphDataEdit_request_update_edge_list(node, old_edge_list, new_edge_list) -> void:
	_undo_redo_update_edge_list_node(node, old_edge_list, new_edge_list)
