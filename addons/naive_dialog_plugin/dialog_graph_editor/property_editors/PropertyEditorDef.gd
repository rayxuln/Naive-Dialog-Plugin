extends Reference

var StringEditorPrefab := load(path_combine(get_root_path(), 'StringEditor.tscn'))
var MultiTextEditorPrefab := load(path_combine(get_root_path(), 'MultiTextEditor.tscn'))
var BoolEditorPrefab := load(path_combine(get_root_path(), 'BoolEditor.tscn'))
var ArrayEditorPrefab := load(path_combine(get_root_path(), 'ArrayEditor.tscn'))
var type_property_default_editor_map := {
	TYPE_STRING: DialogGraphDataDef.EditorType.StringEditor,
	TYPE_BOOL: DialogGraphDataDef.EditorType.BoolEditor,
	TYPE_ARRAY: DialogGraphDataDef.EditorType.ArrayEditor,
}
var type_property_editor_map := {
	DialogGraphDataDef.EditorType.StringEditor: StringEditorPrefab,
	DialogGraphDataDef.EditorType.MultiTextEditor: MultiTextEditorPrefab,
	DialogGraphDataDef.EditorType.BoolEditor: BoolEditorPrefab,
	DialogGraphDataDef.EditorType.ArrayEditor: ArrayEditorPrefab,
}

#----- Methods -----
func get_root_path():
	return get_script().resource_path.get_base_dir()

func path_combine(p1, p2):
	return '%s/%s' % [p1, p2]

func get_property_editor_instance_by_property_def(property_def):
	var editor_type = property_def.editor
	
	# translate default
	if editor_type == DialogGraphDataDef.EditorType.Default and  type_property_default_editor_map.has(property_def.type):
		editor_type = type_property_default_editor_map[property_def.type]
	
	if type_property_editor_map.has(editor_type):
		var prefab:PackedScene = type_property_editor_map[editor_type]
		var editor = prefab.instance()
		return editor
	
	return null

func get_property_editor_instance_by_type(type):
	if type_property_default_editor_map.has(type):
		var editor_type = type_property_default_editor_map[type]
		if type_property_editor_map.has(editor_type):
			var prefab:PackedScene = type_property_editor_map[editor_type]
			var editor = prefab.instance()
			return editor
	return null
