extends DialogGraphDataDef




#----- Data Definitions -----
func data_text():
	return {
		'text': { # property : { definition }
			'type': TYPE_STRING,
			'editor': EditorType.Defualt,
			'default': '',
		},
	}

func data_text_selection():
	return dic_combine(data_text(), {
		'text_selection': {
			'type': TYPE_ARRAY,
			'type_hint': [TYPE_STRING],
			'editor': EditorType.Defualt,
			'default': [],
		},
	})
