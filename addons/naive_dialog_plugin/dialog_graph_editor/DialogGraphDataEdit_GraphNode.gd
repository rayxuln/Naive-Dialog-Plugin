tool
extends GraphNode

signal request_update_edge_list(old_edge_list, new_edge_list)
signal request_set_as_root(v)

const CondPrefab := preload('./DialogGraphDataEdit_GraphNode_Cond.tscn')
const CondType := preload('./DialogGraphDataEdit_GraphNode_Cond.gd')

const PropertyValuePairPrefab := preload('./property_editors/PropertyValuePair.tscn')
const PropertyValuePairType := preload('./property_editors/PropertyValuePair.gd')
const PropertyEditorDef := preload('./property_editors/PropertyEditorDef.gd')

var data:Dictionary
var edge_list:Array

var cond_list := []

onready var bottom_hbox := $BottomHBoxContainer
onready var add_cond_button := $BottomHBoxContainer/AddCondButton
onready var remove_cond_button := $BottomHBoxContainer/RemoveCondButton
onready var property_list_scroll_container := $VBoxContainer/ScrollContainer
onready var property_list_check_button := $VBoxContainer/HBoxContainer/PropertyListCheckButton
onready var property_list_container := $VBoxContainer/ScrollContainer/VBoxContainer
onready var root_check_box := $HBoxContainer/RootCheckBox

enum SlotId {
	In = 0,
	Out = 0,
	CondStart = 2,
}
enum SlotType {
	In = 0,
	Out = 0,
}

var slot_in_color := Color.greenyellow
var slot_out_color := Color.white

var set_as_root_guard := false

#----- Methods -----
func set_data(d:Dictionary, e:Array):
	data = d
	edge_list = e
	update_title()
	update_content()

func set_as_root(v):
	set_as_root_guard = true
	root_check_box.pressed = v
	set_as_root_guard = false

func update_title():
	title = '%s[%s]' % [data.def.type, data.id]
	

func update_content():
	clear_cond()
	var count := 0
	for cond in edge_list:
		var c:CondType = create_cond(count)
		c.get_line_edit().text = cond.cond
		count += 1
	update_remove_cond_button()
	update_slot_display()
	update_property_list_check_button()
	update_property_list()
	update_size()

func update_cond_text():
	for c in cond_list:
		c.get_line_edit().text = edge_list[c.id].cond
		

func create_cond(id):
	var n = CondPrefab.instance()
	n.id = id
	add_child(n)
	move_child(n, get_child_count()-3)
	cond_list.append(n)
	n.connect('request_selected', self, '_on_cond_request_selected', [n])
	n.connect('text_changed', self, '_on_cond_text_changed', [n])
	n.connect('request_up', self, '_on_cond_request_up', [n], CONNECT_DEFERRED)
	n.connect('request_down', self, '_on_cond_request_down', [n], CONNECT_DEFERRED)
	return n

func clear_cond():
	for c in cond_list:
		remove_child(c)
		c.free()
	cond_list.clear()

func remove_cond(id):
	var cond = cond_list[id]
	cond_list.erase(cond)
	remove_child(cond)
	cond.free()
	
	var count := 0
	for c in cond_list:
		c.id = count
		count += 1

func append_empty_cond():
	var list = edge_list.duplicate(true)
	var edge = gen_edge()
	list.append(edge)
	emit_signal('request_update_edge_list', edge_list.duplicate(true), list)

func remove_last_cond():
	if cond_list.empty():
		return
	remove_cond_by_id(cond_list.size()-1)

func remove_cond_by_id(id):
	var list = edge_list.duplicate(true)
	list.remove(id)
	emit_signal('request_update_edge_list', edge_list.duplicate(true), list)

func gen_edge(cond:='', to:=-1):
	return {
		'cond': cond,
		'to': to,
	}

func select_cond(cond_id):
	for n in cond_list:
		if n.id == cond_id:
			n.set_selected(true)
		else:
			n.set_selected(false)

func unselect_all_cond():
	select_cond(-1)

func get_selected_cond():
	for n in cond_list:
		if n.selected:
			return n.id
	return -1

func update_remove_cond_button():
	remove_cond_button.visible = not cond_list.empty() or (get_selected_cond() != -1)

func update_slot_display():
	clear_all_slots()
	
	if cond_list.empty():
		set_slot(SlotId.In, true, SlotType.In, slot_in_color, true, SlotType.Out, slot_out_color)
	else:
		set_slot(SlotId.In, true, SlotType.In, slot_in_color, false, SlotType.Out, slot_out_color)
	
	for i in edge_list.size():
		var slot_id = SlotId.CondStart + i
		set_slot(slot_id, false, SlotType.In, slot_in_color, true, SlotType.Out, slot_out_color)

func update_size():
	if data.has('_editor_'):
		if data['_editor_'].has('min_size'):
			rect_size = data._editor_.min_size
	

func update_property_list_check_button():
	if data.has('_editor_'):
		if data['_editor_'].has('property_list_visible'):
			property_list_check_button.pressed = data['_editor_']['property_list_visible']

func update_property_list():
	for c in property_list_container.get_children():
		c.queue_free()
	
	var pm := {}
	if data.has('_editor_'):
		if data['_editor_'].has('property_map'):
				pm = data['_editor_']['property_map']
	
	for p in data.property_map.keys():
		var editor = get_property_editor_prefab_by_property(p)
		if editor:
			var pair = PropertyValuePairPrefab.instance()
			property_list_container.add_child(pair)
			pair.set_property(p, data.def.property_map[p])
			pair.set_editor(editor)
			pair.connect('visible_check_button_toggled', self, '_on_property_visible_check_button_toggled', [pair])
			if pm.has(p):
				if pm[p].has('visible'):
						pair.set_visible_check_button(pm[p].visible)
			editor.set_value(data.property_map[p])
			editor.connect('value_changed', self, '_on_editor_value_changed', [pair])

func move_cond_up(id):
	if id == 0:
		return
	var list = edge_list.duplicate(true)
	var edge = list[id]
	list.remove(id)
	list.insert(id-1, edge)
	emit_signal('request_update_edge_list', edge_list.duplicate(true), list)

func move_cond_down(id):
	if id == edge_list.size()-1:
		return
	var list = edge_list.duplicate(true)
	var edge = list[id]
	list.remove(id)
	list.insert(id+1, edge)
	emit_signal('request_update_edge_list', edge_list.duplicate(true), list)

func get_property_editor_prefab_by_property(property:String):
	var property_def:Dictionary = data.def.property_map[property]
	var pe_def = PropertyEditorDef.new()
	var editor = pe_def.get_property_editor_instance_by_property_def(property_def)
	if editor:
		return editor
	printerr('Unsupported property type: %s, property: %s' % [property_def.type, property])

func get_cond_start_slot():
	var start_id = 0
	for i in SlotId.CondStart:
		if is_slot_enabled_right(i):
			start_id += 1
	return start_id
#----- Singals -----
func _on_GraphNode_offset_changed() -> void:
	if not data.has('_editor_'):
		data['_editor_'] = {}
	data._editor_.offset = offset


func _on_GraphNode_resized() -> void:
	if not data.has('_editor_'):
		data['_editor_'] = {}
	data._editor_.min_size = rect_size


func _on_AddCondButton_pressed() -> void:
	append_empty_cond()


func _on_RemoveCondButton_pressed() -> void:
	var id = get_selected_cond()
	if id != -1:
		remove_cond_by_id(id)
	else:
		remove_last_cond()

func _on_cond_request_selected(cond):
	select_cond(cond.id)

func _on_cond_text_changed(old_text, new_text, cond):
	edge_list[cond.id].cond = new_text

func _on_cond_request_up(cond):
	move_cond_up(cond.id)

func _on_cond_request_down(cond):
	move_cond_down(cond.id)


func _on_PropertyListCheckButton_toggled(button_pressed: bool) -> void:
	property_list_scroll_container.visible = button_pressed
	if not data.has('_editor_'):
		data['_editor_'] = {}
	data._editor_['property_list_visible'] = button_pressed
	update_size()

func _on_editor_value_changed(v, pair):
	data.property_map[pair.property] = v

func _on_property_visible_check_button_toggled(v, pair:PropertyValuePairType):
	if not data.has('_editor_'):
		data['_editor_'] = {}
	if not data._editor_.has('property_map'):
		data._editor_['property_map'] = {}
	if not data._editor_.property_map.has(pair.property):
		data._editor_.property_map[pair.property] = {}
	data._editor_.property_map[pair.property].visible = v



func _on_RootCheckBox_toggled(button_pressed: bool) -> void:
	if not set_as_root_guard:
		emit_signal('request_set_as_root', button_pressed)
