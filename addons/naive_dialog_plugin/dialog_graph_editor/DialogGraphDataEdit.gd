tool
extends GraphEdit

signal request_create_node(data_def_name)
signal requst_remove_node(node)
signal requst_resize_node(node, min_size)
signal request_update_edge_list(node, old_edge_list, new_edge_list)
signal request_connect_node(from, from_cond_id, to)
signal request_disconnect_node(from, from_cond_id, to)
signal node_dragged(node, old_pos, new_pos)

const BUILTIN_DIALOG_GRAPH_DATA_DEF_PATH := 'res://addons/naive_dialog_plugin/dialog_graph/data_resource/BuiltinDialogGraphDataDef.gd'
const GraphNodePrefab := preload('./DialogGraphDataEdit_GraphNode.tscn')
const GraphNodeType := preload('./DialogGraphDataEdit_GraphNode.gd')


var dialog_graph_data:DialogGraphData = null

var popup:PopupMenu
var popup_new_name := tr('New')
enum PopupMenuId {
	New = 0,
}
var popup_local_mouse_position:Vector2

var popup_new_menu:PopupMenu
var popup_new_menu_name := 'new_menu'
var popup_new_menu_name_list := []
var popup_new_menu_id_list := []

var id_node_map := {}

func _ready() -> void:
	create_popup()
#----- Methods -----
func create_popup():
	popup = PopupMenu.new()
	add_child(popup)
	
	popup_new_menu = PopupMenu.new()
	popup_new_menu.connect('id_pressed', self, '_on_popup_new_menu_id_pressed')
	popup.add_child(popup_new_menu)
	popup_new_menu.name = popup_new_menu_name
	popup.add_submenu_item(popup_new_name, popup_new_menu_name, PopupMenuId.New)

func set_data(d:DialogGraphData):
	dialog_graph_data = d
	update_content()

func update_content():
	update_nodes()
	update_connections()

func clear_all_nodes():
	for id in id_node_map.keys():
		var n = id_node_map[id]
		remove_child(n)
		n.free()
	id_node_map.clear()

func update_nodes():
	clear_all_nodes()
	for n_data in dialog_graph_data.id_node_map.values():
		create_node_with_exist_data(n_data)

func update_connections():
	clear_connections()
	create_connections()

func create_connections():
	for id in dialog_graph_data.id_edge_map.keys():
		var node_data:Dictionary = dialog_graph_data.id_node_map[id]
		
		if node_data.to != -1:
			connect_dialog_graph_node(id_node_map[id], -1, id_node_map[node_data.to])
			continue
		
		var count := 0
		for edge in dialog_graph_data.id_edge_map[id]:
			var from = id_node_map[id]
			if edge.to != -1:
				var to = id_node_map[edge.to]
				connect_dialog_graph_node(from, count, to) # otherwise use the default
			
			count += 1

func connect_dialog_graph_node(from:GraphNodeType, from_cond_id, to:GraphNodeType):
	var from_slot = GraphNodeType.SlotId.Out
	if from_cond_id != -1:
		from_slot = from_cond_id + from.get_cond_start_slot()
	connect_node(from.name, from_slot, to.name, GraphNodeType.SlotId.In)

func connect_edge(from:GraphNodeType, from_cond_id, to:GraphNodeType):
	if from_cond_id == -1:
		from.data.to = to.data.id
	else:
		from.edge_list[from_cond_id].to = to.data.id

func disconnect_edge(from:GraphNodeType, from_cond_id, to:GraphNodeType):
	if from_cond_id == -1:
		from.data.to = -1
	else:
		from.edge_list[from_cond_id].to = -1

func get_data_def_name_list():
	var def_script = load(BUILTIN_DIALOG_GRAPH_DATA_DEF_PATH)
	var def_ins:DialogGraphDataDef = def_script.new()
	return def_ins.get_data_def_name_list()

func get_data_def(data_def_name):
	var def_script = load(BUILTIN_DIALOG_GRAPH_DATA_DEF_PATH)
	var def_ins:DialogGraphDataDef = def_script.new()
	return def_ins.get_data_def(data_def_name)

func gen_data_from_data_def_name(data_def_name):
	var def_script = load(BUILTIN_DIALOG_GRAPH_DATA_DEF_PATH)
	var def_ins:DialogGraphDataDef = def_script.new()
	return def_ins.gen_data(data_def_name)

func create_new_node_at(data:Dictionary, offset:Vector2):
	var id = dialog_graph_data.add_new_node(data)
	data['_editor_'] = {
		'offset': offset,
	}
	
	return create_node_with_data(data)

func create_node_with_exist_data(data:Dictionary):
	var id = data.id
	var node = GraphNodePrefab.instance()
	if not dialog_graph_data.id_edge_map.has(id):
		dialog_graph_data.id_edge_map[id] = []
	id_node_map[id] = node
	add_child(node)
	node.set_data(data, dialog_graph_data.id_edge_map[id])
	
	if data.has('_editor_'):
		var editor_data:Dictionary = data._editor_
		if editor_data.has('offset'):
			node.offset = editor_data.offset
		if editor_data.has('min_size'):
			node.rect_size = editor_data.min_size
	
	node.connect('close_request', self, '_on_node_request_close', [node])
	node.connect('resize_request', self, '_on_node_request_resize', [node])
	node.connect('dragged', self, '_on_node_dragged', [node])
	node.connect('request_update_edge_list', self, '_on_node_request_update_edge_list', [node])
	return id

func create_node_with_data(data:Dictionary):
	var id = data.id
	dialog_graph_data.add_node(data)
	return create_node_with_exist_data(data)

func remove_node(id):
	var node = id_node_map[id]
	dialog_graph_data.remove_node(id)
	node.queue_free()
	id_node_map.erase(id)

#func connect_node_by_id(from_id, cond, to_id):
#	var from = id_node_map[from_id]
#	var to = id_node_map[to_id]
#	dialog_graph_data.id_edge_map[from_id][cond] = to_id
#	connect_node(from.name, GraphNodeType.SlotId.Out, to.name, GraphNodeType.SlotId.In)

func on_popup_show():
	popup_new_menu.clear()
	var count := 0
	for n in get_data_def_name_list():
		popup_new_menu.add_item(n, count)
		count += 1
#----- Signals -----
func _on_DialogGraphDataEdit_popup_request(position: Vector2) -> void:
	on_popup_show()
	
	popup.popup_centered()
	popup.rect_position = position
	popup_local_mouse_position = get_local_mouse_position()

func _on_popup_new_menu_id_pressed(id:int):
	var name_list = get_data_def_name_list()
	var def_type_name = name_list[id]
	emit_signal('request_create_node', def_type_name)
#	create_new_node_at(gen_data_from_data_def_name(def_type_name), popup_local_mouse_position + scroll_offset)

func _on_node_request_close(node:GraphNodeType):
	emit_signal('requst_remove_node', node)

func _on_node_request_resize(min_size:Vector2, node:GraphNodeType):
	emit_signal('requst_resize_node', node, min_size)

func _on_node_dragged(old_pos, new_pos, node):
	emit_signal('node_dragged', node, old_pos, new_pos)

func _on_node_request_update_edge_list(old_edge_list, new_edge_list, node):
	emit_signal('request_update_edge_list', node, old_edge_list, new_edge_list)


func _on_DialogGraphDataEdit_connection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
#	print('connection request from: %s, from_slot: %s, to: %s, to_slot: %s' % [from, from_slot, to, to_slot])
	var from_node:GraphNodeType = get_node(from)
	var to_node:GraphNodeType = get_node(to)
	var from_slot_type = from_node.get_slot_type_right(from_slot)
	if not from_slot_type == GraphNodeType.SlotType.Out:
		return
	var from_cond_id = -1
	if not from_node.is_slot_enabled_right(GraphNodeType.SlotId.Out):
		var start_id = from_node.get_cond_start_slot()
		from_cond_id = from_slot - start_id
	emit_signal('request_connect_node', from_node, from_cond_id, to_node)


func _on_DialogGraphDataEdit_disconnection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	var from_node:GraphNodeType = get_node(from)
	var to_node:GraphNodeType = get_node(to)
	var from_slot_type = from_node.get_slot_type_right(from_slot)
	if not from_slot_type == GraphNodeType.SlotType.Out:
		return
	var from_cond_id = -1
	if not from_node.is_slot_enabled_right(GraphNodeType.SlotId.Out):
		var start_id = from_node.get_cond_start_slot()
		from_cond_id = from_slot - start_id
	emit_signal('request_disconnect_node', from_node, from_cond_id, to_node)
