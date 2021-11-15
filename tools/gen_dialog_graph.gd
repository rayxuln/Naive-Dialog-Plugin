tool
extends EditorScript


const SAVE_PATH := 'res://DialogGraphTest1.tres'


func _run() -> void:
	var g = DialogGraphData.new()
	g.id_node_map = {
		0: {
			'id': 0,
			'text': 'hi',
			'script': 'DialogGraphNode.gd',
			'condition': '',
			'interactable': true,
			'type': 0,
		},
		1: {
			'id': 1,
			'text': 'glad to see you',
			'script': 'DialogGraphNode.gd',
			'condition': '',
			'interactable': true,
			'type': 0,
		},
		2: {
			'id': 2,
			'text': 'me too',
			'script': 'DialogGraphNode.gd',
			'condition': '',
			'interactable': true,
			'type': 0,
		},
		3: {
			'id': 3,
			'text': 'choose something?',
			'script': 'DialogGraphNode.gd',
			'condition': 'selection',
			'selection_list': [
				'OK!',
				'Nope',
				'Go back',
			],
			'interactable': true,
			'type': 1,
		},
		4: {
			'id': 4,
			'text': 'Nice!',
			'script': 'DialogGraphNode.gd',
			'condition': '',
			'interactable': true,
			'type': 0,
		},
		5: {
			'id': 5,
			'text': 'Nevermind',
			'script': 'DialogGraphNode.gd',
			'condition': '',
			'interactable': true,
			'type': 0,
		},
	}
	
	g.id_edge_map = {
		0: 1,
		1: 2,
		2: 3,
		3: [4, 5, 0]
	}
	
	var dir = Directory.new()
	if dir.file_exists(SAVE_PATH):
		dir.remove(SAVE_PATH)
	ResourceSaver.save(SAVE_PATH, g)
	print('done')


