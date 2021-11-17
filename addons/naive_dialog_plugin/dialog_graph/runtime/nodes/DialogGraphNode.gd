extends Node
class_name DialogGraphNode

var data:Dictionary

var id

func _DialogGraphNode_Type_():
	pass
#----- Methods -----
func create_node(_data:Dictionary):
	data = _data
	
	id = data.id
	name = str(data.id)

func calc_condition(runtime):
	return calc_exp(data.property_map.condition, runtime.database.keys(), runtime.database.values())

func calc_exp(e, keys:=[], values:=[]):
	if e.empty():
		return e
	var compiled = Expression.new()
	var err = compiled.parse(e, keys)
	if err != OK:
		printerr('Can\'t compile expression: %s, err: %s' % [e, compiled.get_error_text()])
		return false
	return compiled.execute(values)

func get_next(runtime):
	if data.to != -1:
		return data.to
	var edge_list:Array = runtime.dialog_graph_data.id_edge_map[data.id]
	if edge_list.empty():
		return null
	if data.property_map.condition.empty():
		for edge in edge_list:
			if edge.cond.empty() and edge.to != -1:
				return edge.to
		return null
	var res = calc_condition(runtime)
	print('cond: %s = %s' % [data.property_map.condition, res])
	for edge in edge_list:
		if edge.to == -1:
			continue
		if edge.cond.empty():
			continue
		var val = calc_exp(edge.cond, runtime.database.keys(), runtime.database.values())
		print('edge cond: %s = %s' % [edge.cond, val])
		if res == val:
			return edge.to
	return null


#----- Signals -----
