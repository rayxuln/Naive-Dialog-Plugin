extends Node
class_name DialogGraphNode

var runtime

var data:Dictionary

var id

func _DialogGraphNode_Type_():
	pass
#----- Methods -----
func create_node(_runtime, _data:Dictionary):
	data = _data
	runtime = _runtime
	
	id = data.id
	name = str(data.id)

func calc_condition():
	var compiled_condition = Expression.new()
	var err = compiled_condition.parse(data.condition, runtime.database.keys())
	if err != OK:
		printerr('Can\'t compile condition: %s, err: %s' % [data.condition, compiled_condition.get_error_text()])
		return false
	return compiled_condition.execute(runtime.database.values())

func get_next(runtime):
	var edge_list = runtime.get_edge_list(id)
	if typeof(edge_list) == typeof(id):
		return edge_list
	if data.condition.empty():
		if edge_list == null or ((edge_list is Array or edge_list is Dictionary) and edge_list.empty()):
			return null
		if edge_list is Array:
			return edge_list.front()
		if edge_list is Dictionary:
			return edge_list.valuse().front()
		printerr('Unsupported edge type: %s' % edge_list)
	var res = calc_condition()
	if edge_list is Array:
		if res is int:
			return edge_list[res]
		else:
			printerr('Invalid index: %s, the condition is broken: %s' % [res, data.condition])
			return
	if edge_list is Dictionary:
		return edge_list[res]
	printerr('Unsupported edge type: %s' % [edge_list])


#----- Signals -----
