tool
extends Resource
class_name DialogNodeItemData

# This resource is variant and is shared across all node item types
# Properties which are not applicable are just ignored

enum ItemTypes {
	Message,            # Basic item, displays a dialog message
	Condition,          # Condition to branch out
	Effect              # Effect causing a change to some in-game state
}

# Type of item (message, condition or effect)
export(ItemTypes) var item_type = ItemTypes.Message
# To what sequence id this item is connected (only valid for condition)
export(int) var connected_to_id = -1
# Holds the GraphNode port index for this item
var port_index : int = -1

# ==============================================================================
# USED BY TYPE: MESSAGE

export(String) var message_speaker_id = ""
export(String) var message_speaker_variant = ""
export(String) var message_voice_clip = ""
export(String, MULTILINE) var message_text = ""
export(int) var message_hide_on_end = 0

# ==============================================================================
# USED BY TYPE: CONDITION

export(MTDefs.ConditionTypes) var condition_type = MTDefs.ConditionTypes.Random
export(Array) var condition_values = []

# ==============================================================================
# USED BY TYPE: EFFECT

export(MTDefs.EffectTypes) var effect_type = MTDefs.EffectTypes.ChangeSheet
export(Array) var effect_values = []

