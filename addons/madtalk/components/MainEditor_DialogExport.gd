@tool
extends Window


var mt_ie := MadTalkImportExport.new()
var dialog_data: DialogData
var current_sheet_id: String = ""

var template_ExportSheetListItem := preload("res://addons/madtalk/components/Export_SheetListItem.tscn")

@onready var panel_options := $PanelOptions
@onready var panel_sheets := $PanelSheets
@onready var panel_output := $PanelOutput

@onready var btn_exporter := $PanelOptions/BtnExporter
@onready var exporter_desc := $PanelOptions/ExporterDesc
@onready var panel_locales := $PanelOptions/LocalesPanel
@onready var locales_edit := $PanelOptions/LocalesPanel/LocalesEdit
@onready var output_edit := $PanelOutput/OutputEdit
@onready var label_sheets := $PanelOptions/LabelSheets
@onready var sheet_list := $PanelSheets/SheetScroll/VBox

var export_sheets := []

func setup(data: DialogData, sheet_id: String):
	dialog_data = data
	current_sheet_id = sheet_id
	export_sheets = [sheet_id]
	update_exported_sheets()
	
	mt_ie.refresh_list_importers()
	
	# mt_ie.exporters_list = { "absolute path to .gd": "Friendly Name", }
	
	btn_exporter.clear()
	for path in mt_ie.exporters_list:
		btn_exporter.add_item(mt_ie.exporters_list[path])
	btn_exporter.select(-1)
	
	panel_options.show()
	panel_sheets.hide()
	panel_output.hide()

func set_current_sheet(sheet: String, reset_export_sheet: bool = false):
	current_sheet_id = sheet
	if reset_export_sheet:
		export_sheets = [current_sheet_id]
		update_exported_sheets()

func _on_btn_close_pressed() -> void:
	hide()

# ------------------------------------------

func extract_locales() -> Array:
	var a := Array(locales_edit.text.split("\n"))
	var result := []
	for i in range(a.size()):
		var locale: String = a[i].strip_edges()
		if locale.length() > 0:
			result.append(locale)
	return result


func export():
	if (not dialog_data) or (btn_exporter.selected < 0) or (btn_exporter.selected >= mt_ie.exporters_list.size()):
		print("MadTalk exporter error")
		return
	
	var exporter_script = mt_ie.exporters_list.keys()[ btn_exporter.selected ]
	var exporter = load(exporter_script).new()
	var locales: Array = extract_locales() if panel_locales.visible else []
	
	var result := ""
	for sheet_id: String in export_sheets:
		if (not sheet_id in dialog_data.sheets):
			continue
	
		if result.length() > 0:
			result += "\n\n"
		
		result += exporter.export(dialog_data.sheets[sheet_id], locales)
		
	
	output_edit.text = result
	
	panel_options.hide()
	panel_sheets.hide()
	panel_output.show()
	
	output_edit.select_all()
	output_edit.grab_focus()


func refresh_export_sheet_list():
	for child in sheet_list.get_children():
		child.queue_free()
	
	for sheet_id in dialog_data.sheets:
		var sheet_data: DialogSheetData = dialog_data.sheets[sheet_id]
		
		var new_item := template_ExportSheetListItem.instantiate()
		sheet_list.add_child(new_item)
		new_item.get_node("SheetIDLabel").text = sheet_id
		new_item.get_node("DescLabel").text = sheet_data.sheet_description
		new_item.get_node("BtnSelect").button_pressed = (sheet_id in export_sheets)


func update_exported_sheets(load_from_list: bool = false):
	if load_from_list:
		export_sheets.clear()
		for item in sheet_list.get_children():
			if item.get_node("BtnSelect").button_pressed:
				export_sheets.append(item.get_node("SheetIDLabel").text)
	
	var s := ""
	for sheet_id in export_sheets:
		s += "[color=#ffcc55][b]%s[/b][/color]\n" % sheet_id
	label_sheets.text = s


func _on_btn_exporter_item_selected(index: int) -> void:
	if (btn_exporter.selected < 0) or (btn_exporter.selected >= mt_ie.exporters_list.size()):
		print("MadTalk exporter error")
		return
	
	var exporter_script = mt_ie.exporters_list.keys()[ btn_exporter.selected ]
	var exporter = load(exporter_script).new()
	exporter_desc.text = exporter.description


func _on_btn_force_locales_toggled(toggled_on: bool) -> void:
	panel_locales.visible = toggled_on


func _on_btn_back_pressed() -> void:
	panel_output.hide()
	panel_sheets.hide()
	panel_options.show()


func _on_btn_export_pressed() -> void:
	export()


func _on_btn_manage_sheets_pressed() -> void:
	refresh_export_sheet_list()
	panel_options.hide()
	panel_sheets.show()
	panel_output.hide()


func _on_sheets_to_export_btn_ok_pressed() -> void:
	update_exported_sheets(true)
	panel_options.show()
	panel_sheets.hide()
	panel_output.hide()
