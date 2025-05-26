extends Node

const SAVES_PATH:String = "user://saves/"
const basical_player_data:PlayerData = preload("res://scene/ext/PlayerDataServerV2/basical_player_data_res.tres")

#Dictionary<String:PlayerData>, should be valid string for filename
var saves_manifest:Dictionary = {}

func _init() -> void:
	ensure_saves_directory_exist()
	acquire_saves_manifest()
	
func ensure_saves_directory_exist() -> void:
	if not DirAccess.dir_exists_absolute(SAVES_PATH):
		DirAccess.make_dir_recursive_absolute(SAVES_PATH)

func acquire_saves_manifest() -> void:
	var dir:DirAccess = DirAccess.open(SAVES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var save_id:String = file_name.strip_edges().replace(".tres", "")
				saves_manifest[save_id] = true
				file_name = dir.get_next()
				
		dir.list_dir_end()


#pass null to prminitial_data to generate a new profile, or pass a PlayerData to duplicate it. Otherwise, the behaviour is undefined.
func generate_new_savedata(id:String, prminitial_data = null) -> void:
	if not saves_manifest.has(id):
		var initial_data:PlayerData
		if prminitial_data == null:
			initial_data = PlayerData.new()
		else:
			initial_data = (prminitial_data as Resource).duplicate()
		
		saves_manifest[id] = initial_data

func load_data_at_id(id:String) -> int:
	if not saves_manifest.has(id):
		push_error("savefile \""+id+"\"doesn't exist, this load progress will be cancelled")
		return FAILED
	saves_manifest[id] = load(SAVES_PATH.path_join("%s.tres" % id))
	
	return OK

func save_data_at_id(id:String) -> int:
	if not saves_manifest.has(id):
		push_error("savefile \""+id+"\"doesn't exist, this save progress will be cancelled")
		return FAILED
	
	if typeof(saves_manifest.get(id)) == TYPE_BOOL:
		push_error("savefile \""+id+"\"exists but not loaded, this save progress will be cancelled")
		return FAILED
	
	return ResourceSaver.save(saves_manifest.get(id),SAVES_PATH.path_join("%s.tres" % id))

func delete_data_at_id(id:String) ->int:
	if not saves_manifest.has(id):
		push_warning("savefile \""+id+"\"doesn't exist, this delete progress will be cancelled")
		return FAILED
		
	var path_to_delete:String = SAVES_PATH.path_join("%s.tres" % id)
	#expected return point
	if FileAccess.file_exists(path_to_delete):
		return DirAccess.remove_absolute(path_to_delete)
	
	return FAILED

func get_data_at_id_of_name(id:String,data_name:String):
	if not saves_manifest.has(id):
		push_error("savefile \""+id+"\"doesn't exist, this acquisition progress will be cancelled")
		return null

	return (saves_manifest.get(id) as PlayerData).get(data_name)


func get_data_at_id(id:String,default = null):
	return saves_manifest.get(id,default)
