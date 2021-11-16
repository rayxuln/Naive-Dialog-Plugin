extends Resource
class_name DialogGraphData

export var id_count := -1

export var databse:Dictionary
export(int) var root
export var id_node_map:Dictionary
export var id_edge_map:Dictionary # {id: [{cond:Expression, to:id}] }


#----- Methods -----
func gen_new_id():
	id_count += 1;
	return id_count


func add_new_node(node_data:Dictionary):
	node_data.id = gen_new_id()
	id_node_map[node_data.id] = node_data
	return node_data.id

func add_node(node_data:Dictionary):
	id_node_map[node_data.id] = node_data

func get_node(id):
	return id_node_map[id]

func remove_node(id):
	id_node_map.erase(id)
