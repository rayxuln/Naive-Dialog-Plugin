tool
extends Control

signal value_changed(v)

const PropertyValuePairType := preload('./PropertyValuePair.gd')

onready var list_container := $ScrollContainer/VBoxContainer/VBoxContainer

var property_def:Dictionary
var list:Array

var item_popup_menu:PopupMenu
var item_popup_menu_remove_name := tr('Remove')
var item_popup_menu_insert_above_name := tr('Insert Above')
var item_popup_menu_insert_below_name := tr('Insert Below')
enum ItemPopupMenuId {
	Remove = 0,
	InsertAbove = 1,
	InsertBelow = 2,
}
var item_popup_menu_item_id := -1

func _ready() -> void:
	create_item_popup_menu()
#----- Methods -----
func create_item_popup_menu():
	item_popup_menu = PopupMenu.new()
	item_popup_menu.add_item(item_popup_menu_remove_name, ItemPopupMenuId.Remove)
	item_popup_menu.add_separator()
	item_popup_menu.add_item(item_popup_menu_insert_above_name, ItemPopupMenuId.InsertAbove)
	item_popup_menu.add_item(item_popup_menu_insert_below_name, ItemPopupMenuId.InsertBelow)
	item_popup_menu.connect('id_pressed', self, '_on_item_popup_menu_id_pressed')
	add_child(item_popup_menu)

func create_list_item():
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
	menu_button.flat = true
	menu_button.text = '◎'
	hbox1.add_child(menu_button)
	item.set_meta('menu_button', menu_button)
	
	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	line_edit.size_flags_vertical = SIZE_EXPAND_FILL
	hbox1.add_child(line_edit)
	item.set_meta('line_edit', line_edit)
	
	var hbox2 = HBoxContainer.new()
	hbox1.add_child(hbox2)
	
	var up_button = Button.new()
	up_button.text = '↑'
	up_button.flat = true
	hbox2.add_child(up_button)
	
	var down_button = Button.new()
	down_button.text = '↓'
	down_button.flat = true
	hbox2.add_child(down_button)
	
	item.set_meta('up_button', up_button)
	item.set_meta('down_button', down_button)
	
	return item

func clear_list_item():
	for c in list_container.get_children():
		c.queue_free()

func update_list():
	clear_list_item()
	var count = 0
	for v in list:
		var item = create_list_item()
		list_container.add_child(item)
		item.set_meta('id', count)
		var line_edit:LineEdit = item.get_meta('line_edit')
		line_edit.text = str(v)
		line_edit.connect('text_changed', self, '_on_item_value_changed', [item])
		var up_button:Button = item.get_meta('up_button')
		up_button.connect('pressed', self, '_on_item_up_button_pressed', [item])
		var down_button:Button = item.get_meta('down_button')
		down_button.connect('pressed', self, '_on_item_down_button_pressed', [item])
		var menu_button:Button = item.get_meta('menu_button')
		menu_button.connect('pressed', self, '_on_item_menu_button_pressed', [item])
		
		count += 1

func move_up_list_item(id):
	if id == 0:
		return
	var v = list[id]
	list.remove(id)
	list.insert(id-1, v)
	update_list()

func move_down_list_item(id):
	if id == list.size()-1:
		return
	var v = list[id]
	list.remove(id)
	list.insert(id+1, v)
	update_list()

func add_list_item_at(id):
	list.insert(id, '')
	update_list()
	
func remove_list_item_at(id):
	list.remove(id)
	update_list()

func add_list_item_at_end():
	add_list_item_at(list.size())

func set_value(v):
	list = v
	update_list()

func get_value(v):
	return list

func get_layout_type():
	return PropertyValuePairType.LayoutType.Vertical

func update_size():
	rect_size = Vector2.ZERO
#----- Signals -----
func _on_item_value_changed(v, item):
	list[item.get_meta('id')] = v


func _on_AddButton_pressed() -> void:
	add_list_item_at_end()

func _on_item_up_button_pressed(item):
	move_up_list_item(item.get_meta('id'))

func _on_item_down_button_pressed(item):
	move_down_list_item(item.get_meta('id'))

func _on_item_popup_menu_id_pressed(id:int):
	if item_popup_menu_item_id < 0 or item_popup_menu_item_id >= list.size():
		return
	match id:
		ItemPopupMenuId.Remove:
			remove_list_item_at(item_popup_menu_item_id)
		ItemPopupMenuId.InsertAbove:
			add_list_item_at(item_popup_menu_item_id)
		ItemPopupMenuId.InsertBelow:
			add_list_item_at(item_popup_menu_item_id+1)
	item_popup_menu_item_id = -1

func _on_item_menu_button_pressed(item):
	item_popup_menu_item_id = item.get_meta('id')
	item_popup_menu.popup_centered()
	item_popup_menu.rect_global_position = get_global_mouse_position()
