tool
extends Control

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')
const PropertyValuePairPrefab := preload('./PropertyValuePair.tscn')
const PropertyEditorDef := preload('./PropertyEditorDef.gd')

onready var list_container := $ScrollContainer/VBoxContainer/VBoxContainer
onready var key_line_edit := $HBoxContainer/KeyLineEdit

var property_def
var map:Dictionary

var item_popup_menu:PopupMenu
var item_popup_menu_remove_name := tr('Remove')
enum ItemPopupMenuId {
	Remove = 0,
	TypeCanditateStart = 1000,
}
var item_popup_menu_item = null
var type_canditate_map := {}

func _ready() -> void:
	add_type_canditate(TYPE_STRING, 'String')
	add_type_canditate(TYPE_BOOL, 'Bool')
	add_type_canditate(TYPE_INT, 'Int')
	add_type_canditate(TYPE_REAL, 'Float')
	add_type_canditate(TYPE_ARRAY, 'Array')
	add_type_canditate(TYPE_DICTIONARY, 'Dictionary')
	create_item_popup_menu()
#----- Methods -----
func add_type_canditate(type:int, type_name:String):
	type_canditate_map[type] = {'name': type_name, 'id': ItemPopupMenuId.TypeCanditateStart + type}

func create_item_popup_menu():
	item_popup_menu = PopupMenu.new()
		# add supported type
	for type in type_canditate_map:
		item_popup_menu.add_item(type_canditate_map[type].name, type_canditate_map[type].id)
	
	item_popup_menu.add_separator()
	item_popup_menu.add_item(item_popup_menu_remove_name, ItemPopupMenuId.Remove)
	item_popup_menu.connect('id_pressed', self, '_on_item_popup_menu_id_pressed')
	add_child(item_popup_menu)

func create_map_item(v):
	var item = PanelContainer.new()
	item.size_flags_horizontal = SIZE_EXPAND_FILL
	item.size_flags_vertical = SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color.a = 0
	item.add_stylebox_override('panel', style)
	
	var hbox1 = HBoxContainer.new()
	hbox1.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox1.size_flags_vertical = SIZE_EXPAND_FILL
	item.add_child(hbox1)
	
	var menu_button = Button.new()
	menu_button.size_flags_vertical = 0
	menu_button.flat = true
	menu_button.text = '◎'
	hbox1.add_child(menu_button)
	item.set_meta('menu_button', menu_button)
	
	var property_value_pair = PropertyValuePairPrefab.instance()
	hbox1.add_child(property_value_pair)
	var pe_def = PropertyEditorDef.new()
	var editor = pe_def.get_property_editor_instance_by_type(typeof(v))
	item.set_meta('pair', property_value_pair)
	item.set_meta('editor', editor)
	
	return item

func clear_map_item():
	for c in list_container.get_children():
		c.queue_free()

func update_map():
	clear_map_item()
	for k in map.keys():
		var v = map[k]
		var item = create_map_item(v)
		list_container.add_child(item)
		item.set_meta('key', k)
		var menu_button:Button = item.get_meta('menu_button')
		menu_button.connect('pressed', self, '_on_item_menu_button_pressed', [item])
		
		var pair:PropertyValuePairType = item.get_meta('pair')
		pair.set_property(k)
		pair.connect('request_edit_property', self, '_on_pair_request_edit', [true, pair, item])
		pair.connect('request_change_property', self, '_on_pair_request_edit', [false, pair, item])
		
		var editor = item.get_meta('editor')
		if editor:
			editor.connect('value_changed', self, '_on_item_value_changed', [item])
			pair.set_editor(editor)
			editor.set_value(v)
		else:
			printerr('Unsupport map type: %s' % typeof(v))

func add_map_item_at(id):
	map[id] = ''
	update_map()
	
func remove_map_item_at(id):
	map.erase(id)
	update_map()

func set_value(v):
	map = v
	update_map()

func get_value():
	return map

func get_layout_type():
	return PropertyValuePairType.LayoutType.Vertical

func update_size():
	rect_size = Vector2.ZERO

func get_empty_value_by_type(type:int):
	var def := DialogGraphDataDef.new()
	return def.get_empty_value_by_type(type)
#----- Signals -----
func _on_item_value_changed(v, item):
	map[item.get_meta('key')] = v

func _on_AddButton_pressed() -> void:
	if map.has(key_line_edit.text):
		printerr('key: \'%s\' is already exist!' % [key_line_edit.text])
		return
	add_map_item_at(key_line_edit.text)

func _on_item_popup_menu_id_pressed(id:int):
	if item_popup_menu_item == null:
		return
	match id:
		ItemPopupMenuId.Remove:
			remove_map_item_at(item_popup_menu_item.get_meta('key'))
	if id >= ItemPopupMenuId.TypeCanditateStart:
		var new_type = id - ItemPopupMenuId.TypeCanditateStart
		var val = get_empty_value_by_type(new_type)
		map[item_popup_menu_item.get_meta('key')] = val
		update_map()
	
	item_popup_menu_item = null

func _on_item_menu_button_pressed(item):
	item_popup_menu_item = item
	item_popup_menu.popup_centered()
	item_popup_menu.rect_global_position = get_global_mouse_position()

func _on_pair_request_edit(edit_mode, pair:PropertyValuePairType, item):
	var old_key = pair.property
	pair.set_edit_mode(edit_mode)
	var new_key = pair.property
	if not edit_mode:
		if old_key == new_key:
			return
		if map.has(new_key):
			printerr('The key: \'%s\' is already exist!' % old_key)
			pair.property = old_key
		else:
			var v = map[old_key]
			map.erase(old_key)
			map[new_key] = v
			update_map()
