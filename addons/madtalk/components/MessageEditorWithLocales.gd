@tool
extends ReferenceRect

signal tab_changed

const DEFAULT_TAB_TITLE = "Default"

@onready var locale_bar := $LocaleBar
@onready var message_edit := $MessageEdit
@onready var panel_new_locale := $PanelNewLocale
@onready var locale_edit := $PanelNewLocale/LocaleEdit


var messages_locales := {}
var current_locale := ""

var is_updating_tabs := false

func setup(default_message: String, locale_messages: Dictionary):
	is_updating_tabs = true
	
	messages_locales.clear()
	messages_locales[""] = default_message
	
	var locale_list: Array = locale_messages.keys()
	
	for locale in locale_list:
		messages_locales[locale] = locale_messages[locale]
	
	locale_list.sort()
	
	locale_bar.clear_tabs()
	locale_bar.add_tab(DEFAULT_TAB_TITLE)
	for tab_name in locale_list:
		locale_bar.add_tab(tab_name)
	locale_bar.current_tab = 0
	
	current_locale = ""
	load_text_from_locale(current_locale)
	
	is_updating_tabs = false


func load_text_from_locale(locale: String):
	if locale in messages_locales:
		message_edit.text = messages_locales[locale]
	else:
		message_edit.text = ""


func store_text_into_locale(locale: String, text: String):
	messages_locales[locale] = text


func finalize_editor():
	store_text_into_locale(current_locale, message_edit.text)
	
	var locale_list = messages_locales.keys()
	for locale in locale_list:
		if messages_locales[locale] == "":
			messages_locales.erase(locale)


func _on_locale_bar_tab_changed(tab: int) -> void:
	if is_updating_tabs:
		return
	
	store_text_into_locale(current_locale, message_edit.text)
	current_locale = locale_bar.get_tab_title(tab)
	if current_locale == DEFAULT_TAB_TITLE:
		current_locale = ""
	load_text_from_locale(current_locale)
	
	tab_changed.emit()


func _on_btn_locale_new_pressed() -> void:
	locale_edit.text = ""
	panel_new_locale.show()


func _on_btn_locale_new_cancel_pressed() -> void:
	panel_new_locale.hide()


func _on_btn_locale_new_confirm_pressed() -> void:
	var new_locale = locale_edit.text
	if not new_locale in messages_locales:
		messages_locales[new_locale] = ""
		locale_bar.add_tab(new_locale)
	panel_new_locale.hide()


func get_default_locale_message() -> String:
	return messages_locales[""] if "" in messages_locales else ""


func get_locale_messages_without_default() -> Dictionary:
	var result := {}
	for locale in messages_locales:
		if locale != "":
			result[locale] = messages_locales[locale]
	return result
