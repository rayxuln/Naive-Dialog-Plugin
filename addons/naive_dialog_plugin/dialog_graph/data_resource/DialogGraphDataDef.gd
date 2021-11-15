extends Reference
class_name DialogGraphDataDef


enum EditorType {
	Defualt = 0,
}


#----- Methods -----
func dic_combine(d1:Dictionary, d2:Dictionary):
	var res = {}
	for k in d1.keys():
		res[k] = d1[k]
	for k in d2.keys():
		res[k] = d2[k]
	return res

func get_data_gen(name:String):
	var func_name = 'data_%s' % name
	return dic_combine(call(func_name), {
		
	})
