extends DialogGraphDataDef




#----- Data Definitions -----
func data_text():
	return {
		'speaker': '',
		'text': { # property : { definition }
			'type': TYPE_STRING,
			'editor': EditorType.MultiTextEditor,
			'default': '',
		},
	}

func data_text_selection():
	return dic_combine(data_text(), {
		'text_selection': {
			'type': TYPE_ARRAY,
			'editor': EditorType.Default,
			'default': [],
		},
		'condition': 'selection',
	})

func data_assignment():
	return {
		'interactable': false,
		'assignment_map': {
			'default': {},
		},
	}
