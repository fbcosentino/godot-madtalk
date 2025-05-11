@tool
extends Resource
class_name DialogNodeOptionData

enum AutodisableModes {
	NEVER,
	RESET_ON_SHEET_RUN,
	ALWAYS
}

enum InactiveMode {
	DISABLED,
	HIDDEN
}

## Text shown in the button, default locale
@export var text: String = ""

## Text shown in the button, other locales
@export var text_locales: Dictionary = {}

## To what sequence id this option is connected 
@export var connected_to_id: int = -1
# Holds the GraphNode port index for this item
var port_index : int = -1

## If option visibility is conditional
@export var is_conditional: bool = false

## Variable name
@export var condition_variable: String = ""

## Condition operator ("=", "!=", ">", "<", ">=", "<=")
## This version keeps it as string for code simplicity
@export var condition_operator: String = "="

## Variable value - if the string is a valid number, value is the number itself
## otherwise (if it's a text String) it's the variable name to compare to
@export var condition_value: String = ""

## If the option auto-disables itself after selected
@export var autodisable_mode := AutodisableModes.NEVER

## How the option is handled when it's not active
@export var inactive_mode := InactiveMode.DISABLED

func get_localized_text() -> String:
	var locale = MadTalkGlobals.current_locale
	
	if locale == "":
		return text
	
	elif (locale in text_locales):
		return text_locales[locale]
	
	else:
		return text
