extends Reference
class_name DialogGraphDataDef


enum EditorType {
	Default = 0,
	MultiTextEditor,
	StringEditor,
	BoolEditor,
	ArrayEditor,
}

const DATA_DEF_METHOD_PREFIX := 'data_'

#----- Methods -----
func dic_combine(d1:Dictionary, d2:Dictionary):
	var res = {}
	for k in d1.keys():
		res[k] = d1[k]
	for k in d2.keys():
		res[k] = d2[k]
	return res

func _data_base(data_type_name):
	return {
		'type': data_type_name,
		'property_map': {
			'interactable': {
				'type': TYPE_BOOL,
				'editor': EditorType.Default,
				'default': true,
			},
			'condition': {
				'type': TYPE_STRING,
				'editor': EditorType.Default,
				'default': '',
			},
		},
	}

func get_data_def(data_type_name:String):
	var func_name = 'data_%s' % data_type_name
	var data_def = _data_base(data_type_name)
	data_def.property_map = dic_combine(data_def.property_map, call(func_name))
	for k in data_def.property_map.keys():
		var p_def = data_def.property_map[k]
		if not p_def is Dictionary:
			data_def.property_map[k] = {}
			data_def.property_map[k].default = p_def
			p_def = data_def.property_map[k]
		if not p_def.has('type'):
			if not p_def.has('default'):
				p_def.default = ''
			p_def.type = typeof(p_def.default)
		if not p_def.has('editor'):
			p_def.editor = EditorType.Default
	return data_def

func get_empty_value_by_type(type:int):
	match type:
		TYPE_NIL:
			return null
		TYPE_BOOL:
			return false
		TYPE_INT:
			return 0
		TYPE_REAL:
			return 0.0
		TYPE_STRING:
			return ''
		TYPE_VECTOR2:
			return Vector2.ZERO
		TYPE_RECT2:
			return Rect2(0, 0, 0, 0)
		TYPE_VECTOR3:
			return Vector3.ZERO
		TYPE_TRANSFORM2D:
			return Transform2D.IDENTITY
		TYPE_PLANE:
			return Plane(0, 0, 0, 0)
		TYPE_QUAT:
			return Quat.IDENTITY
		TYPE_AABB:
			return AABB(Vector3.ZERO, Vector3.ZERO)
		TYPE_BASIS:
			return Basis.IDENTITY
		TYPE_TRANSFORM:
			return Transform.IDENTITY
		TYPE_COLOR:
			return Color.white
		TYPE_NODE_PATH:
			return ''
		TYPE_OBJECT:
			return null
		TYPE_DICTIONARY:
			return {}
		TYPE_ARRAY:
			return []
		TYPE_RAW_ARRAY:
			return []
		TYPE_INT_ARRAY:
			return []
		TYPE_REAL_ARRAY:
			return []
		TYPE_STRING_ARRAY:
			return []
		TYPE_VECTOR2_ARRAY:
			return []
		TYPE_VECTOR3_ARRAY:
			return []
		TYPE_COLOR_ARRAY:
			return []
	printerr('Unsupported type: %s' % type)
	return null

func gen_base_data():
	return {
		'def': {},
		'id': -1,
		'condition': '',
		'property_map': {},
	}

func gen_data(data_type_name:String):
	var data_def = get_data_def(data_type_name)
	var data = gen_base_data()
	data.def = data_def
	
	for k in data_def.property_map.keys():
		var p_def:Dictionary = data_def.property_map[k]
		if p_def.has('default'):
			data.property_map[k] = p_def.default
		else:
			data.property_map[k] = get_empty_value_by_type(p_def.type)
	
	return data

func get_data_def_name_list():
	var res := []
	for m in get_method_list():
		var name:String = m.name
		if name.begins_with(DATA_DEF_METHOD_PREFIX):
			var data_type_name = name.substr(DATA_DEF_METHOD_PREFIX.length())
			if data_type_name.empty(): continue
			res.append(data_type_name)
	return res
