@tool
extends ReferenceRect

signal tab_changed
signal voice_clip_dialog_requested

const DEFAULT_TAB_TITLE = "Default"

@onready var locale_bar := $LocaleBar
@onready var message_edit := $MessageEdit
@onready var voiceclip_edit := $VoiceEdit
@onready var panel_new_locale := $PanelNewLocale
@onready var locale_edit := $PanelNewLocale/LocaleEdit


var messages_locales := {}
var voiceclips_locales := {}
var current_locale := ""

var is_updating_tabs := false

func setup(default_message: String, locale_messages: Dictionary, default_voiceclip: String, locales_voiceclips: Dictionary):
	is_updating_tabs = true
	
	messages_locales.clear()
	messages_locales[""] = default_message
	voiceclips_locales.clear()
	voiceclips_locales[""] = default_voiceclip
	
	var locale_list: Array = locale_messages.keys()
	for locale in locales_voiceclips:
		if not locale in locale_list:
			locale_list.append(locale)
	
	for locale in locale_list:
		messages_locales[locale] = locale_messages[locale] if locale in locale_messages else ""
		voiceclips_locales[locale] = locales_voiceclips[locale] if locale in locales_voiceclips else ""
	
	locale_list.sort()
	
	locale_bar.clear_tabs()
	locale_bar.add_tab(DEFAULT_TAB_TITLE)
	for tab_name in locale_list:
		if tab_name != "":
			locale_bar.add_tab(tab_name)
	locale_bar.current_tab = 0
	
	current_locale = ""
	load_data_from_locale(current_locale)
	
	is_updating_tabs = false


func load_data_from_locale(locale: String):
	if locale in messages_locales:
		message_edit.text = messages_locales[locale]
	else:
		message_edit.text = ""
	
	if locale in voiceclips_locales:
		voiceclip_edit.text = voiceclips_locales[locale]
	else:
		voiceclip_edit.text = ""


func store_data_into_locale(locale: String, text: String, voiceclip: String):
	messages_locales[locale] = text
	voiceclips_locales[locale] = voiceclip


func finalize_editor():
	store_data_into_locale(current_locale, message_edit.text, voiceclip_edit.text)
	
	var locale_list = messages_locales.keys()
	for locale in locale_list:
		if messages_locales[locale] == "":
			messages_locales.erase(locale)
	
	locale_list = voiceclips_locales.keys()
	for locale in locale_list:
		if voiceclips_locales[locale] == "":
			voiceclips_locales.erase(locale)


func _on_locale_bar_tab_changed(tab: int) -> void:
	if is_updating_tabs:
		return
	
	store_data_into_locale(current_locale, message_edit.text, voiceclip_edit.text)
	current_locale = locale_bar.get_tab_title(tab)
	if current_locale == DEFAULT_TAB_TITLE:
		current_locale = ""
	load_data_from_locale(current_locale)
	
	tab_changed.emit()


func _on_btn_locale_new_pressed() -> void:
	locale_edit.text = ""
	panel_new_locale.show()


func _on_btn_locale_new_cancel_pressed() -> void:
	panel_new_locale.hide()


func _on_btn_locale_new_confirm_pressed() -> void:
	var new_locale = locale_edit.text
	if (not new_locale in messages_locales) and (not new_locale in voiceclips_locales):
		locale_bar.add_tab(new_locale)
	if (not new_locale in messages_locales):
		messages_locales[new_locale] = ""
	if (not new_locale in voiceclips_locales):
		voiceclips_locales[new_locale] = ""
	panel_new_locale.hide()


func get_default_locale_message() -> String:
	return messages_locales[""] if "" in messages_locales else ""


func get_default_locale_voiceclip() -> String:
	return voiceclips_locales[""] if "" in voiceclips_locales else ""


func get_locale_messages_without_default() -> Dictionary:
	var result := {}
	for locale in messages_locales:
		if locale != "":
			result[locale] = messages_locales[locale]
	return result


func get_locale_voiceclips_without_default() -> Dictionary:
	var result := {}
	for locale in voiceclips_locales:
		if locale != "":
			result[locale] = voiceclips_locales[locale]
	return result


func set_voice_clip(clip_path: String):
	voiceclip_edit.text = clip_path


func _on_btn_select_clip_pressed() -> void:
	voice_clip_dialog_requested.emit()
