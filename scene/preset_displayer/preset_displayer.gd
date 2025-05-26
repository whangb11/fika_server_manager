class_name PresetDisplayer
extends Control

var data_ref:PlayerData = null
var preset_id:int = -1
var preset_data:Dictionary = {}

@onready var host_ip_edit:LineEdit = $HBoxContainer/DataV/HostIPEdit
@onready var client_ip_edit:LineEdit = $HBoxContainer/DataV/ClientIPEdit
@onready var preset_name_display:Label = $PresetName
@onready var preset_name_edit:LineEdit = $PresetNameEdit
@onready var btn_apply:Button = $HBoxContainer/DataK/Apply
func _ready() -> void:
	_update_context.call_deferred()
	#inexist or index out of bound
	if data_ref == null or preset_id >= (data_ref.permanent_data.get("presets",[]) as Array).size() or preset_id < 0:
		return
	
	preset_data = (data_ref.permanent_data.get("presets",[]) as Array)[preset_id]
	

func _update_context() -> void:
	host_ip_edit.text = preset_data.get("hostip","none")
	client_ip_edit.text = preset_data.get("clientip","none")
	preset_name_display.text = preset_data.get("name","none")
	preset_name_edit.text = preset_data.get("name","none")
	if data_ref == null or preset_id >= (data_ref.permanent_data.get("presets",[]) as Array).size() or preset_id < 0:
		return
	#btn_apply.set_disabled(data_ref.permanent_data.get("current_preset",-1) == preset_id)

func _on_edit_pressed() -> void:
	preset_name_edit.show()



func _on_preset_name_edit_text_submitted(new_text: String) -> void:
	preset_data["name"] = new_text
	preset_name_edit.hide()
	_update_context.call_deferred()


func _on_host_ip_edit_text_submitted(new_text: String) -> void:
	preset_data["hostip"] = new_text
	_update_context.call_deferred()


func _on_client_ip_edit_text_submitted(new_text: String) -> void:
	preset_data["clientip"] = new_text
	_update_context.call_deferred()


func _on_apply_pressed() -> void:
	if data_ref == null or preset_id >= (data_ref.permanent_data.get("presets",[]) as Array).size() or preset_id < 0:
		return
	
	data_ref.permanent_data["preset_to_apply"] = preset_id
	for pnode:Node in get_tree().get_nodes_in_group("MainScene"):
		if is_instance_valid(pnode) and pnode.has_method("apply_preset"):
			pnode.apply_preset()


func _on_delete_pressed() -> void:
	if data_ref == null or preset_id >= (data_ref.permanent_data.get("presets",[]) as Array).size() or preset_id < 0:
		return
	
	data_ref.permanent_data["preset_to_delete"] = preset_id
	for pnode:Node in get_tree().get_nodes_in_group("MainScene"):
		if is_instance_valid(pnode) and pnode.has_method("ask_if_erase"):
			pnode.ask_if_erase()
