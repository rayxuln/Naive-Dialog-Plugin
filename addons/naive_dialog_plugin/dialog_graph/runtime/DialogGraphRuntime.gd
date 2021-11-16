extends Node
class_name DialogGraphRuntime

signal request_advance(runtime, current_node)
signal dialog_started(runtime)
signal dialog_advanced(runtime, current_node)
signal dialog_ended(runtime)

var database := {}

export(Resource) var dialog_graph_data setget _on_set_dialog_graph_data
func _on_set_dialog_graph_data(v):
	if dialog_graph_data != v:
		clear_runtime()
		create_runtime(v)

var current_node:DialogGraphNode
var current_node_waiting_advance := false

var dialog_started := false

var id_node_map := {}
var root_id

func _process(delta: float) -> void:
	tick()
#----- Methods -----
func create_runtime(data:DialogGraphData):
	dialog_graph_data = data
	database = dialog_graph_data.databse.duplicate(true)
	
	for n_data in dialog_graph_data.id_node_map.values():
		var node = create_runtime_node(n_data)
		add_child(node)
		id_node_map[n_data.id] = node
	
	root_id = dialog_graph_data.root
	current_node_waiting_advance = false

func clear_runtime():
	dialog_graph_data = null
	database = {}
	current_node = null
	root_id = -1
	dialog_started = false
	current_node_waiting_advance = false
	for n in id_node_map.values():
		n.queue_free()
	id_node_map = {}

func create_runtime_node(data:Dictionary):
	var base_path:String = get_script().resource_path
	base_path = base_path.get_base_dir()
	var script_path = '%s/nodes/%s' % [base_path, data.script]
	var NodeType = load(script_path) as Script
	var node:DialogGraphNode = NodeType.new()
	if node == null:
		printerr('"%s" can\'t be newed' % script_path)
		return
	
	node.create_node(self, data)
	
	return node

func start_dialog():
	dialog_started = true
	current_node = id_node_map[root_id]
	current_node_waiting_advance = false
	emit_signal('dialog_started', self)
	emit_signal('dialog_advanced', self, current_node)

func is_dialog_started():
	return dialog_started

func end_dialog():
	if not dialog_started:
		return
	dialog_started = false
	current_node = null
	current_node_waiting_advance = false
	emit_signal('dialog_ended', self)

func tick():
	if not is_dialog_started():
		return
	if not current_node:
		end_dialog()
		return
	if current_node_waiting_advance:
		return
	var data:Dictionary = current_node.data
	if data.interactable:
		current_node_waiting_advance = true
		emit_signal('request_advance', self, current_node)
	else:
		advance()
	

func advance(params:={}):
	if not current_node:
		printerr('current node is null!')
		print_stack()
		return
	
	for k in params.keys():
		database[k] = params[k]
	
	var next_id = current_node.get_next(self)
	if next_id != null:
		current_node = id_node_map[next_id]
	else:
		current_node = null
	emit_signal('dialog_advanced', self, current_node)
	
	current_node_waiting_advance = false

func database_set(key, value):
	database[key] = value

func database_get(key):
	return database[key]

func database_erase(key):
	database.erase(key)
	
func database_has(key):
	return database.has(key)
#----- Signals -----



