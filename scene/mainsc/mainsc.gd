class_name FIKAServerManager
extends Control

@onready var spt_path_edit:LineEdit = $Panel/Panel/LineEdit
@onready var infobox_container:ColorRect = $InfoboxContainer
@onready var infobox_info:Label = $InfoboxContainer/Infobox/Info
@onready var current_tracker:ColorRect = $Panel/Div/PresetsContainer/CurrentTracker
@onready var preset_container:VBoxContainer = $Panel/Div/PresetsContainer/ScrollContainer/VBoxContainer
@onready var current_container:Control = $Panel/Div/CurrentInfoContainer/Div
@onready var addbox_container:ColorRect = $AddboxContainer
@onready var if_erase_container:ColorRect = $IfEraseContainer

var refuserdata:PlayerData

const TRANSITION_DURATION_SEC:float = 0.2
const PRESET_DISPLAYER_SC:PackedScene = preload("res://scene/preset_displayer/preset_displayer.tscn")

const default_http_json_path:String = "<spt>SPT_Data/Server/configs/http.json"
const default_config_json_path:String = "<spt>user/launcher/config.json"
const default_fika_cfg_path:String = "<spt>BepInEx/config/com.fika.core.cfg"

var http_json_path:String = default_http_json_path
var config_json_path:String = default_config_json_path
var fika_cfg_path:String = default_fika_cfg_path

var SPT_APPD_EXISTANCE_VALIDATION_LIST:Array = [
	http_json_path,
	config_json_path,
	fika_cfg_path
]


func _ready() -> void:
	get_window().set_min_size(Vector2i(900,600))
	if PlayerDataServerV2.get_data_at_id("0") == null:
		PlayerDataServerV2.generate_new_savedata("0")
		PlayerDataServerV2.save_data_at_id("0")
	PlayerDataServerV2.load_data_at_id("0")
	refuserdata = PlayerDataServerV2.get_data_at_id("0")
	spt_path_edit.text = refuserdata.permanent_data.get_or_add("spt_installation","./")
	
	#init fika cfg
	var _current_preset:int = refuserdata.permanent_data.get_or_add("current_preset",-1)
	var _presets:Array = refuserdata.permanent_data.get_or_add("presets",[])
	
	http_json_path = refuserdata.permanent_data.get_or_add("http_json_path_override",http_json_path)
	config_json_path = refuserdata.permanent_data.get_or_add("config_json_path_override",config_json_path)
	fika_cfg_path = refuserdata.permanent_data.get_or_add("fika_cfg_path_override",fika_cfg_path)
	
	SPT_APPD_EXISTANCE_VALIDATION_LIST=[
		parse_path_overrode(http_json_path),
		parse_path_overrode(config_json_path),
		parse_path_overrode(fika_cfg_path)
	]
	
	spt_path_edit.emit_signal.call_deferred("editing_toggled",false)
	_update_context.call_deferred()


func _update_context() -> void:
	var scroll:ScrollContainer = $Panel/Div/PresetsContainer/ScrollContainer
	var v_scroll_mem = scroll.scroll_vertical
	while preset_container.get_child_count() > 0:
		preset_container.remove_child(preset_container.get_children()[0])
	
	var presets:Array = refuserdata.permanent_data.get("presets",[])
	for i in range(presets.size()):
		var pd_instance:PresetDisplayer = PRESET_DISPLAYER_SC.instantiate()
		pd_instance.data_ref = refuserdata
		pd_instance.preset_id = i
		preset_container.add_child(pd_instance)
	
	$Panel/Div/CurrentInfoContainer/Div/V/HTTPEdit.text = refuserdata.permanent_data.get("http_json_path_override",http_json_path)
	$Panel/Div/CurrentInfoContainer/Div/V/ConfigEdit.text = refuserdata.permanent_data.get("config_json_path_override",config_json_path)
	$Panel/Div/CurrentInfoContainer/Div/V/FikaCfgEdit.text = refuserdata.permanent_data.get("fika_cfg_path_override",fika_cfg_path)
	
	var current_preset:int = refuserdata.permanent_data.get("current_preset",-1)
	if  current_preset >= 0 and current_preset < presets.size():
		var hostip_display:Label = $Panel/Div/CurrentInfoContainer/Div/V/HostIP
		var clientip_display:Label = $Panel/Div/CurrentInfoContainer/Div/V/ClientIP
		hostip_display.text = presets[current_preset]["hostip"]
		clientip_display.text = presets[current_preset]["clientip"]
	
	scroll.set_v_scroll.call_deferred(v_scroll_mem)


func show_infobox(info:String = "Nothing there.") -> void:
	infobox_info.set_text(info)
	open_popup_container(infobox_container)


func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_update_spt_path(spt_path_edit.text)
		spt_path_edit.text = refuserdata.permanent_data["spt_installation"]


func _update_spt_path(new_path:String) -> void:
	new_path = new_path.replace("\\","/")
	
	if not new_path.ends_with("/"):
		new_path += "/"
	
	var spt_installation:DirAccess = DirAccess.open(new_path)
	
	if spt_installation == null:
		show_infobox(TranslationServer.translate("UI_WARN_INVALID_SPT_INSTALLATION").format([new_path]))
		return
	
	for vali:String in SPT_APPD_EXISTANCE_VALIDATION_LIST:
		if not spt_installation.file_exists(vali):
			show_infobox(TranslationServer.translate("UI_WARN_INVALID_FIKA_CHECK").format([new_path + vali]))
			return
	
	refuserdata.permanent_data["spt_installation"] = new_path
	PlayerDataServerV2.save_data_at_id("0")


func _on_infobox_container_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		close_popup_container(infobox_container)


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(infobox_info.text)


static func generate_new_preset(hostip:String,clientip:String,preset_name:String = "UI_INFO_PRESET_UNNAMED") -> Dictionary:
	var o:Dictionary = {
		"topped" = false,
		"hostip" = hostip,
		"clientip" = clientip,
		"name" = preset_name
	}
	
	return o


func _on_add_pressed() -> void:
	for child:LineEdit in $AddboxContainer/Addbox/Div/AddV.get_children():
		child.text = ""
	
	open_popup_container(addbox_container)


func _on_addbox_container_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		_close_addbox()


func _on_refresh_pressed() -> void:
	_update_context()


func _on_apply_add_pressed() -> void:
	var name_edit:LineEdit = $AddboxContainer/Addbox/Div/AddV/Name
	var hostip_edit:LineEdit = $AddboxContainer/Addbox/Div/AddV/HostIP
	var clientip_edit:LineEdit = $AddboxContainer/Addbox/Div/AddV/ClientIP
	
	if name_edit.text.length() == 0:
		show_infobox("UI_EMPTY_WARN_NAME") 
		return
	
	if hostip_edit.text.length() == 0:
		show_infobox("UI_EMPTY_WARN_HOST")
		return
	
	if clientip_edit.text.length() == 0:
		show_infobox("UI_EMPTY_WARN_CLIENT")
		return
	
	(refuserdata.permanent_data.get("presets",[]) as Array).append(FIKAServerManager.generate_new_preset(hostip_edit.text,clientip_edit.text,name_edit.text))
	refuserdata.permanent_data["current_preset"] = refuserdata.permanent_data.get("current_preset",0)
	
	_update_context()
	_close_addbox()
	PlayerDataServerV2.save_data_at_id("0")


func _close_addbox() -> void:
	close_popup_container(addbox_container)


func apply_preset() -> void:
	var presets:Array = refuserdata.permanent_data.get("presets",[])
	if presets.size() <= refuserdata.permanent_data.get("preset_to_apply",-1):
		show_infobox(TranslationServer.translate("UI_WARN_INVALID_CURRENT_PRESETID").format([refuserdata.permanent_data.get("preset_to_apply",-1)]))
		return
	
	refuserdata.permanent_data["current_preset"] = refuserdata.permanent_data.get("preset_to_apply",-1)

	var preset_data:Dictionary = presets[refuserdata.permanent_data["current_preset"]]
	var json:JSON = JSON.new()
	
	#tamper SPT_Data/Server/configs/http.json
	var http_json_ifs:FileAccess = FileAccess.open(parse_path_overrode(http_json_path),FileAccess.READ)
	if http_json_ifs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_I").format([parse_path_overrode(http_json_path)]))
		return
	
	var http_json_parse_result = json.parse(http_json_ifs.get_as_text(),true)
	if http_json_parse_result != OK:
		show_infobox(json.get_error_message())
		return
	http_json_ifs.close()
	http_json_ifs = null
	
	var http_backup_ofs:FileAccess = FileAccess.open(parse_path_overrode(http_json_path) + ".bak",FileAccess.WRITE_READ)
	if http_backup_ofs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_BACKUP_FAILED").format([parse_path_overrode(http_json_path) + ".bak"]))
	http_backup_ofs.store_string(json.get_parsed_text())
	http_backup_ofs.close()
	http_backup_ofs = null
	
	var http_json:Dictionary = json.get_data()
	http_json["ip"] = "0.0.0.0"
	http_json["backendIp"] = preset_data["clientip"]
	
	var http_json_ofs:FileAccess = FileAccess.open(parse_path_overrode(http_json_path),FileAccess.WRITE)
	if http_json_ofs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_O").format([parse_path_overrode(http_json_path)]))
		return
	http_json_ofs.store_string(JSON.stringify(http_json,"    ",false))
	http_json_ofs.close()
	http_json_ofs = null
	
	#tamper user/launcher/config.json
	var launcher_json_ifs:FileAccess = FileAccess.open(parse_path_overrode(config_json_path),FileAccess.READ)
	if launcher_json_ifs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_I").format([parse_path_overrode(config_json_path)]))
		return
	
	var launcher_json_parse_result = json.parse(launcher_json_ifs.get_as_text())
	if launcher_json_parse_result != OK:
		show_infobox(json.get_error_message())
	launcher_json_ifs.close()
	launcher_json_ifs=null
	
	var launcher_backup_ofs:FileAccess = FileAccess.open(parse_path_overrode(config_json_path) + ".bak",FileAccess.WRITE_READ)
	if launcher_backup_ofs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_BACKUP_FAILED").format([parse_path_overrode(config_json_path) + ".bak"]))
	launcher_backup_ofs.store_string(json.get_parsed_text())
	launcher_backup_ofs.close()
	launcher_backup_ofs = null
	
	var launcher_json:Dictionary = json.data
	launcher_json["IsDevMode"] = true
	launcher_json["Name"] = preset_data["name"]
	launcher_json["Url"] = "https://{}:6969".format([preset_data["hostip"]])
	var launcher_json_ofs:FileAccess = FileAccess.open(parse_path_overrode(config_json_path),FileAccess.WRITE)
	if launcher_json_ofs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_O").format([parse_path_overrode(config_json_path)]))
		return
	launcher_json_ofs.store_string(JSON.stringify(launcher_json,"  ",false))
	launcher_json_ofs.close()
	launcher_json_ofs=null

	#tamper BepInEx/config/com.fika.core.cfg
	#ConfigFile cannot parse it, sad:(
	#dis part is written with the help of Deepseek
	ugly_fika_cfg_tamper(preset_data)
	_update_context.call_deferred()
	show_infobox("UI_SUCCESS")


#This impl is literally ugly, Project Fika if u see this, STANDARDIZE THE CONFIG FILE OR IM GONna to beg for it T_T
#Use ConfigFile to parse it and u will know why
func ugly_fika_cfg_tamper(preset_data) -> void:
	var fika_cfg_ifs:FileAccess = FileAccess.open(parse_path_overrode(fika_cfg_path),FileAccess.READ)
	if fika_cfg_ifs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_I").format([parse_path_overrode(fika_cfg_path)]))
		return
	
	var lines:Array[String] = []
	var current_section = ""
	
	while not fika_cfg_ifs.eof_reached():
		var line:String = fika_cfg_ifs.get_line().strip_edges()
		lines.append(line)
		
		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.trim_prefix("[").trim_suffix("]")
			continue
		
		if current_section != "Network":
			continue
		
		if "=" in line and not line.begins_with("#"):
			var parts = line.split("=", true, 1)
			var key = parts[0].strip_edges()
			var _value = parts[1].strip_edges()
			
			if key == "Force IP":
				lines[-1] = "{0} = {1}".format([key,preset_data["hostip"]])
			
			if key == "Force Bind IP":
				lines[-1] = "{0} = {1}".format([key,preset_data["clientip"]])
	
	fika_cfg_ifs.close()
	fika_cfg_ifs = null
	
	var fika_cfg_ofs:FileAccess = FileAccess.open(parse_path_overrode(fika_cfg_path),FileAccess.WRITE)
	if fika_cfg_ofs == null:
		show_infobox(TranslationServer.translate("UI_TAMPER_ERROR_O").format([parse_path_overrode(fika_cfg_path)]))
		return
	
	for line in lines:
		fika_cfg_ofs.store_line(line)
	
	fika_cfg_ofs.close()
	fika_cfg_ofs = null


func ask_if_erase() -> void :
	open_popup_container(if_erase_container)


func erase_preset() -> void :
	var presets:Array = refuserdata.permanent_data.get("presets",[])
	var preset_to_delete:int = refuserdata.permanent_data.get("preset_to_delete",-1)
	if presets.size() <= preset_to_delete:
		show_infobox(TranslationServer.translate("UI_WARN_INVALID_CURRENT_PRESETID").format([preset_to_delete]))
		return
	
	presets.remove_at(preset_to_delete)
	close_popup_container(if_erase_container)
	PlayerDataServerV2.save_data_at_id("0")
	_update_context.call_deferred()


func open_popup_container(container:Control) -> void:
	var dis_tween:Tween = create_tween()
	container.show()
	container.anchor_top = 0.5
	container.anchor_bottom = 0.5
	dis_tween.set_ease(Tween.EASE_OUT)
	dis_tween.set_trans(Tween.TRANS_CUBIC)
	
	dis_tween.tween_property(container,"anchor_top",0.0,TRANSITION_DURATION_SEC)
	dis_tween.parallel()
	dis_tween.tween_property(container,"anchor_bottom",1.0,TRANSITION_DURATION_SEC)
	dis_tween.tween_callback(dis_tween.kill)


func close_popup_container(container:Control) -> void:
	container.anchor_top = 0.0
	container.anchor_bottom = 1.0
	var dis_tween:Tween = create_tween()
	dis_tween.set_ease(Tween.EASE_OUT)
	dis_tween.set_trans(Tween.TRANS_CUBIC)
	dis_tween.tween_property(container,"anchor_top",0.5,TRANSITION_DURATION_SEC)
	dis_tween.parallel()
	dis_tween.tween_property(container,"anchor_bottom",0.5,TRANSITION_DURATION_SEC)
	dis_tween.tween_callback(container.hide)
	dis_tween.tween_callback(dis_tween.kill)


func _on_if_erase_container_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		close_popup_container(if_erase_container)


func _on_yes_pressed() -> void:
	erase_preset()


func _on_no_pressed() -> void:
	close_popup_container(if_erase_container)


func _on_http_edit_text_submitted(new_text: String) -> void:
	if new_text.length() == 0:
		new_text = default_http_json_path
	http_json_path = new_text
	refuserdata["http_json_path_override"] = http_json_path


func _on_config_edit_text_submitted(new_text: String) -> void:
	if new_text.length() == 0:
		new_text = default_config_json_path
	config_json_path = new_text
	refuserdata["config_json_path_override"] = config_json_path


func _on_fika_cfg_edit_text_submitted(new_text: String) -> void:
	if new_text.length() == 0:
		new_text = default_fika_cfg_path
	fika_cfg_path = new_text
	refuserdata["fika_cfg_path_override"] = fika_cfg_path


func parse_path_overrode(path:String) -> String:
	return path.replacen("<spt>",refuserdata.permanent_data.get("spt_installation","error"))


func _on_lang_edit_text_submitted(new_text: String) -> void:
	TranslationServer.set_locale(new_text)


func _on_apply_pressed() -> void:
	refuserdata.permanent_data["preset_to_apply"] = refuserdata.permanent_data.get("current_preset",-1)
	apply_preset()
