extends Resource
class_name DialogGraphData

var id_count := -1

export var databse := {}
export(int) var root
export var id_node_map := {}
export var id_edge_map := {} # {id: {cond: id} }


#----- Methods -----
func gen_new_id():
	id_count += 1;
	return id_count


func gen_node_data():
	return {
		'id': 0,
		'condition': '',
		'data_def': {},
		'data': {}
	}
