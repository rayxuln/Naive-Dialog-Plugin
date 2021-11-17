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
onready var discard_changes_confirmation_dialog := $DiscardChangesConfirmationDialog

var saved_undoredo_version:int

var new_node_data_stack := []
var new_node_redo_data_stack := []
var deleted_node_data_stack := []
var connect_node_stack := []

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
	new_node_redo_data_stack.clear()
	deleted_node_data_stack.clear()
	connect_node_stack.clear()
	update_dialog_graph_data_edit(dialog_graph_data)
	update_title()

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
	edit(ResourceLoader.load(path, '', true))

func on_save():
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
	if new_node_redo_data_stack.empty():
		var id = dialog_graph_data_edit.create_new_node_at(dialog_graph_data_edit.gen_data_from_data_def_name(def_type_name), dialog_graph_data_edit.popup_local_mouse_position + dialog_graph_data_edit.scroll_offset)
		new_node_data_stack.push_back(id)
	else:
		new_node_data_stack.push_back(new_node_redo_data_stack.back().data.id)
		_undo_remove_node(new_node_redo_data_stack)
func _undo_create_node():
	var id = new_node_data_stack.pop_back()
	_do_remove_node(id, new_node_redo_data_stack)

func _undo_redo_remove_node(node_id):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Remove Node: \'%s\' - [%s]' % [node.data.def.type, node.data.id])
	undoredo.add_do_method(self, '_do_remove_node', node_id, deleted_node_data_stack)
	undoredo.add_undo_method(self, '_undo_remove_node', deleted_node_data_stack)
	undoredo.commit_action()
func _do_remove_node(node_id, stack):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	var from_list := []
	var from_edge_map := {}
	# change from nodes' edges
	for from in dialog_graph_data_edit.dialog_graph_data.id_edge_map.keys():
		var from_edge_list:Array =  dialog_graph_data_edit.dialog_graph_data.id_edge_map[from]
		var count := 0
		for edge in from_edge_list:
			if edge.to == node.data.id:
				if not from_edge_map.has(from):
					from_edge_map[from] = from_edge_list.duplicate(true)
				edge.to = -1
			count += 1
	for from in dialog_graph_data_edit.dialog_graph_data.id_node_map.keys():
		var from_data = dialog_graph_data_edit.dialog_graph_data.id_node_map[from]
		if from_data.to == node.data.id:
			from_list.append(from)
			from_data.to = -1
	stack.push_back({
		'data': node.data,
		'edge_list': node.edge_list,
		'from_list': from_list,
		'from_edge_map': from_edge_map,
	})
	dialog_graph_data_edit.remove_node(node.data.id)
	# remove this node's edges
	dialog_graph_data_edit.dialog_graph_data.id_edge_map.erase(node.data.id)
	
	dialog_graph_data_edit.update_connections()
func _undo_remove_node(stack):
	var node = stack.pop_back()
	var id = dialog_graph_data_edit.create_node_with_data(node.data)
	var new_node = dialog_graph_data_edit.id_node_map[id]
	
	# add this node's edge
	new_node.edge_list.append_array(node.edge_list)
	
	# change from nodes' edge
	for from in node.from_list:
		var from_node = dialog_graph_data_edit.id_node_map[from]
		from_node.data.to = id
	for from in node.from_edge_map.keys():
		var from_node = dialog_graph_data_edit.id_node_map[id]
		from_node.edge_list.clear()
		from_node.edge_list.append_array(node.from_edge_map[from])
	
	dialog_graph_data_edit.update_connections()

func _undo_redo_resize_node(node_id, min_size):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	node.rect_size = min_size
#	var undoredo := the_plugin.get_undo_redo()
#	undoredo.create_action('Resize Node: \'%s\' - [%s]' % [node.data.def.type, node.data.id])
#	undoredo.add_do_method(self, '_do_resize_node', node, min_size)
#	undoredo.add_undo_method(self, '_undo_resize_node', node, node.rect_min_size)
#	undoredo.commit_action()
#func _do_resize_node(node:Control, min_size):
#	node.rect_min_size = min_size
#func _undo_resize_node(node, min_size):
#	node.rect_min_size = min_size

func _undo_redo_dragged_node(node_id, old_pos, new_pos):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Dragged Node: \'%s\' - [%s]' % [node.data.def.type, node.data.id])
	undoredo.add_do_method(self, '_do_dragged_node', node_id, new_pos)
	undoredo.add_undo_method(self, '_do_dragged_node', node_id, old_pos)
	undoredo.commit_action()
func _do_dragged_node(node_id, offset):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	node.offset = offset


func _undo_redo_update_edge_list_node(node_id, old_edge_list, new_edge_list):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	var old_to = node.data.to if old_edge_list.empty() else -1
	var new_to = node.data.to if new_edge_list.empty() else -1
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Node: \'%s\' - [%s] => change condition list' % [node.data.def.type, node.data.id])
	undoredo.add_do_method(self, '_do_update_edge_list_node', node_id, new_edge_list, new_to)
	undoredo.add_undo_method(self, '_do_update_edge_list_node', node_id, old_edge_list, old_to)
	undoredo.commit_action()
func _do_update_edge_list_node(node_id, list, to):
	var node = dialog_graph_data_edit.id_node_map[node_id]
	node.edge_list.clear()
	node.edge_list.append_array(list)
	node.data.to = to
	node.update_content()
	dialog_graph_data_edit.update_connections()

func _undo_redo_connect_node(from_id, from_cond_id, to_id):
	var from = dialog_graph_data_edit.id_node_map[from_id]
	var to = dialog_graph_data_edit.id_node_map[to_id]
	
	var undoredo := the_plugin.get_undo_redo()
	undoredo.create_action('Connect Node: from \'%s[%s]\' to \'%s[%s]\', cond: \'%s\'' % [from.data.def.type, from.data.id, to.data.def.type, to.data.id, (from.edge_list[from_cond_id].cond if from_cond_id != -1 else 'No Cond')])
	undoredo.add_do_method(self, '_do_connect_node', from_id, from_cond_id, to_id)
	undoredo.add_undo_method(self, '_undo_connect_node', from_id, from_cond_id, to_id)
	undoredo.commit_action()
func _do_connect_node(from_id, from_cond_id, to_id):
	var from = dialog_graph_data_edit.id_node_map[from_id]
	var to = dialog_graph_data_edit.id_node_map[to_id]
	
	var data = {
		'to': from.data.to,
		'edge_list': from.edge_list.duplicate(true),
	}
	connect_node_stack.append(data)
	dialog_graph_data_edit.connect_edge(from, from_cond_id, to)
	dialog_graph_data_edit.update_connections()
func _undo_connect_node(from_id, from_cond_id, to_id):
	var from = dialog_graph_data_edit.id_node_map[from_id]
	var to = dialog_graph_data_edit.id_node_map[to_id]
	
	var data = connect_node_stack.pop_back()
	from.data.to = data.to
	from.edge_list.clear()
	from.edge_list.append_array(data.edge_list)
	dialog_graph_data_edit.update_connections()
#----- Signals -----
func _on_file_menu_id_pressed(id:int):
	match id:
		FileMenuId.New:
			if is_dirty():
				discard_changes_confirmation_dialog.popup_centered()
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
		var res = ResourceLoader.load(path, '', true)
		if res and res is DialogGraphData:
			res = null
			dir.remove(path)
			the_plugin.get_editor_interface().get_resource_filesystem().scan()
			yield(get_tree().create_timer(0.1), 'timeout')
		else:
			error('Can\'t override it, because it is not a DialogGraphData! "%s"' % path)
			return
	save_to(path)


func _on_DialogGraphDataEdit_request_create_node(def_type_name) -> void:
	_undo_redo_create_node(def_type_name)

func _on_undoredo_version_changed():
	update_title()


func _on_DialogGraphDataEdit_requst_remove_node(node) -> void:
	_undo_redo_remove_node(node.data.id)


func _on_DialogGraphDataEdit_requst_resize_node(node, min_size) -> void:
	_undo_redo_resize_node(node.data.id, min_size)


func _on_DialogGraphDataEdit_node_dragged(node, old_pos, new_pos) -> void:
	_undo_redo_dragged_node(node.data.id, old_pos, new_pos)


func _on_OverrideConfirmationDialog_confirmed() -> void:
	update_dialog_graph_data_edit(DialogGraphData.new())
	update_title()
	saved_undoredo_version = the_plugin.get_undo_redo().get_version()


func _on_DialogGraphDataEdit_request_update_edge_list(node, old_edge_list, new_edge_list) -> void:
	_undo_redo_update_edge_list_node(node.data.id, old_edge_list, new_edge_list)



func _on_DialogGraphDataEdit_request_connect_node(from, from_cond_id, to) -> void:
	_undo_redo_connect_node(from.data.id, from_cond_id, to.data.id)
