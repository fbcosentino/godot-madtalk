# MadTalk Godot Plugin by Fernando Cosentino
# https://github.com/fbcosentino/godot-madtalk
#
# License: MIT
# (But if you can be so kind as to mention the original in your Readme in case
# you base any work on this, I would be very glad :] )

extends Node


signal dialog_acknowledged
signal text_display_completed
signal speaker_changed(previous_speaker_id, previous_speaker_variant, new_speaker_id, new_speaker_variant)
signal voice_clip_requested(speaker_id, clip_path)

signal dialog_started(sheet_name, sequence_id)
signal dialog_finished(sheet_name, sequence_id)

#warning-ignore:unused_signal
signal evaluate_custom_condition(custom_id, custom_data)
#warning-ignore:unused_signal
signal activate_custom_effect(custom_id, custom_data)

signal dialog_sequence_processed(sheet_name, sequence_id)
signal dialog_item_processed(sheet_name, sequence_id, item_index)

signal message_text_shown(speaker_id, speaker_variant, message_text, force_hiding)

signal menu_option_activated(option_id)
signal time_updated(datetime_dict)

signal dialog_aborted

# Your scene should have a Control-descendant node with all dialog controls
# inside. The top Control should be overlayed on top of all your visual elements
# so it can capture mouse events first. One way to acomplish this is to
# simply have it at the end of your scene tree child list, with "Full Rect" 
# layout and the mouse filter set to "Stop". Your scene root node can be of any
# type (doesn't have to descend from Control). It can even be a Spatial in
# a normal 3D project

# Array containing the character data, one record per character
# All items in this array must be of type MTCharacterData
export(Array, Resource) var ListOfCharacters = []

# This is the main control overlay used to show all dialog activity under
# MadTalk responsibility. Usually a Control with "Full Rect" layout and mouse
# filter set to "Stop", but other scenarios are possible at your discretion.
export(NodePath) var DialogMainControl
onready var dialog_maincontrol = get_node_or_null(DialogMainControl)

# The Control-descendant holding all the objects in the text box
# but not the menu. Menu must be able to become visible when this is hidden
# In most simple cases this can be the label itself
export(NodePath) var DialogMessageBox
onready var dialog_messagebox = get_node_or_null(DialogMessageBox)

# The Label or RichTextLabel used to display dialog messages
export(NodePath) var DialogMessageLabel
onready var dialog_messagelabel = get_node_or_null(DialogMessageLabel)

# The Label or RichTextLabel used to display the speaker name
export(NodePath) var DialogSpeakerLabel
onready var dialog_speakerlabel = get_node_or_null(DialogSpeakerLabel)

# The TextureRect for showing avatars
export(NodePath) var DialogSpeakerAvatar
onready var dialog_speakeravatar = get_node_or_null(DialogSpeakerAvatar)

# The Control-descendant holding the entire button menu, including containers,
# decorations, etc. Hiding this should be enough to leave no trace of the
# menu on screen
export(NodePath) var DialogButtonsMenu
onready var dialog_menu = get_node_or_null(DialogButtonsMenu)

# The container (usually VBoxContainer) which will hold the button instances
# directly. There must be nothing inside this node, this is the lowest
# hierarchy node in the customization/decoration branch of the scene tree, and
# buttons will be created as direct children of this node
export(NodePath) var DialogButtonsContainer
onready var dialog_buttons_container = get_node_or_null(DialogButtonsContainer)

# The PackedScene file containing the button template used to build the menu.
# Must have a signal without ambiguity for direct connection which is emitted
# only when the option is selected. Signal must have no arguments.
# Many actions sharing a same signal having different values for an argument
# (e.g. InputEvent) is not supported.
export(PackedScene) var DialogButtonSceneFile = null

# Signal name emitted by DialogButtonSceneFile when the option is confirmed
export(String) var DialogButtonTextProperty = "text"

# Signal name emitted by DialogButtonSceneFile when the option is confirmed
export(String) var DialogButtonSignalName = "pressed"

# AnimationPlayer object used for fade-in and fade-out transition animations
# if not given, animations will simply be disabled and only show() and hide() 
# will be used instead
export(NodePath) var DialogAnimationPlayer
onready var dialog_anims = get_node_or_null(DialogAnimationPlayer)

# Below are animation names taken from the AnimationPlayer specified above.
# Make sure the fade out animations have valid information in the last frame
# If a track ends before the last frame, duplicate the last keyframe at (or
# after) the last frame. Applying the updates of only the last frame must be 
# enough to reset the tracks to their faded-out states

# Animation for dialog fade in - displays the DialogMainControl node entirely
export(String) var TransitionAnimationName_DialogFadeIn = ""
# Animation for dialog fade out - hides the DialogMainControl node entirely
export(String) var TransitionAnimationName_DialogFadeOut = ""
# Animation for message box fade in - displays the DialogMessageBox node
export(String) var TransitionAnimationName_MessageBoxFadeIn = ""
# Animation for message box fade out - hides the DialogMessageBox node
export(String) var TransitionAnimationName_MessageBoxFadeOut = ""
# Animation for menu fade in - displays the DialogButtonsMenu node entirely
export(String) var TransitionAnimationName_MenuFadeIn = ""
# Animation for menu fade out - hides the DialogButtonsMenu node entirely
export(String) var TransitionAnimationName_MenuFadeOut = ""
# Animation for message showing up - e.g. characters gradually being typed
export(String) var TransitionAnimationName_TextShow = ""
# Animation for message disappearing
export(String) var TransitionAnimationName_TextHide = ""


# Automatically animate text tweening the Label's percent_visible property
export(bool) var AnimateText = true
export(float) var AnimatedTextMilisecondPerCharacter = 50.0

# AnimationPlayer used to play effect animations
export(NodePath) var EffectsAnimationPlayer
onready var effects_anims = get_node_or_null(EffectsAnimationPlayer)

# Year base is used to offset the calendar, datetime objects are referenced
# to year 0001, and developer can shift that to any year of conveniente to
# match dates to weekdays and leap years
export(int) var YearOfReference = 1970

export(NodePath) var KeyPressAudioStreamPlayer
onready var sfx_key_press = get_node_or_null(KeyPressAudioStreamPlayer)

# ==============================================================================



class DialogCursor:
	var sheet_name : String = ""
	var sequence_id : int = 0
	var item_index : int = 0
	
	func _init(sheetname, sequenceid, _itemindex):
		sheet_name = sheetname
		sequence_id = sequenceid





# Dialog data - you can customize this if you want, but leaving the default
# should work just fine
var dialog_data = preload("res://madtalk/madtalk_data.tres")


# For each sheet, the array index for each sequence ID is searched only once
# and the map is cached to avoid unnecessary lookup loops
# This variable holds the map
# Structure is:
# sheet_sequence_to_index = {
#     "sheet_name": {
#         <sequence_ID>: <index in sheet.nodes Array>,
#         ...
#     },
#     ...
# }
var sheet_sequence_to_index = {}

# Ditionary mapping character ID to MTCharacterData
var character_data = {}

# If for some reason a dialog is fired when another one is still going on, the
# new one is added to the queue. Whenever a dialog ends, the queue is checked 
# and fired if required
# Structure is:
# dialog_queue = [<list of DialogCursor items>]
var dialog_queue = []

# Flags tracking the state of dialog Control nodes
# we don't rely on properties (like `visible`) since the user might have a
# different logic to display or hide messages (including resizing UI or
# always-visible elements)
var dialog_maincontrol_active  = false
var dialog_messagebox_active   = false
var dialog_messagelabel_active = false
var dialog_menu_active         = false
var dialog_on_text_progress    = false
var last_speaker_id = "" # used to identify if speaker_id has just changed
var last_speaker_variant = ""
var last_message_item = null
var last_message_text = ""

# Stores Tween node for text animation if used
var animated_text_tween = null

# Holds the target object and method name to be called when
# evaluating custom conditions
var custom_condition_object = null
var custom_condition_method = ""

# Holds the target object and method name to be called when
# activating custom effects
var custom_effect_object = null
var custom_effect_method = ""

# Flags set when a request to abort or skip the dialog are issued
# The difference between them is: when a dialog is skipped, messages are not
# shown anymore, but all the dialog tree is still traversed, all conditions are
# checked, animations are played and effects take place. Aborting stops where it
# is. This is important since game logic can be critically based on those 
# effects. E.g. if an effect in the end of a conversation spawns a boss,
# skipping the dialog still spanws the boss, while aborting doesn't.
# Both flags are always cleared when starting a dialog.
var is_abort_requested = false
var is_skip_requested = false

# RandomNumberGenerator used for, well, random numbers
# Global is not used to avoid restricting from other uses
var rng = RandomNumberGenerator.new()

var msgparser = MessageCodeParser.new()

func debug_print(text: String) -> void:
	print("MADTALK: "+text)

func bool_as_int(value):
	return 0 if (value == 0) else 1


func _ready():
	var condition_connection_array = get_signal_connection_list("evaluate_custom_condition")
	if condition_connection_array.size() > 0:
		custom_condition_object = condition_connection_array[0]["target"]
		custom_condition_method = condition_connection_array[0]["method"]

	var effect_connection_array = get_signal_connection_list("activate_custom_effect")
	if effect_connection_array.size() > 0:
		custom_effect_object = effect_connection_array[0]["target"]
		custom_effect_method = effect_connection_array[0]["method"]
	
	MadTalkGlobals.set_game_year(YearOfReference)
	
	rng.randomize()
	
	if (dialog_anims):
		# Sanitizes the animation names ensuring we only have valid animations
		
		if not dialog_anims is AnimationPlayer:
			dialog_anims = null
			
		else:
			if not dialog_anims.has_animation(TransitionAnimationName_DialogFadeIn):
				TransitionAnimationName_DialogFadeIn = ""
			if not dialog_anims.has_animation(TransitionAnimationName_DialogFadeOut):
				TransitionAnimationName_DialogFadeOut = ""
			if not dialog_anims.has_animation(TransitionAnimationName_MenuFadeIn):
				TransitionAnimationName_MenuFadeIn = ""
			if not dialog_anims.has_animation(TransitionAnimationName_MenuFadeOut):
				TransitionAnimationName_MenuFadeOut = ""
			if not dialog_anims.has_animation(TransitionAnimationName_TextShow):
				TransitionAnimationName_TextShow = ""
			if not dialog_anims.has_animation(TransitionAnimationName_TextHide):
				TransitionAnimationName_TextHide = ""
				
			dialog_anims.connect("animation_finished", self, "_on_animation_finished")
			
			# Move animations to their respective faded-out states
			# or hide dialog main control and menu
			if TransitionAnimationName_DialogFadeOut != "":
				dialog_anims.play(TransitionAnimationName_DialogFadeOut, -1, 1.0, true)
				dialog_anims.advance(0)
			else:
				dialog_maincontrol.hide()
				
			if TransitionAnimationName_MenuFadeOut != "":
				dialog_anims.play(TransitionAnimationName_MenuFadeOut, -1, 1.0, true)
				dialog_anims.advance(0)
			else:
				if dialog_menu:
					dialog_menu.hide()

			if TransitionAnimationName_TextHide != "":
				dialog_anims.play(TransitionAnimationName_TextHide, -1, 1.0, true)
				dialog_anims.advance(0)
			
	for char_data_item in ListOfCharacters:
		character_data[char_data_item.id] = char_data_item
			
	if (not dialog_data) or (not dialog_data is DialogData):
		# Unfortunately we have an invalid database, discard and make a new one
		dialog_data = DialogData.new()
		debug_print("Dialog data invalid, using a blank one instead")
		
	if AnimateText:
		animated_text_tween = Tween.new()
		add_child(animated_text_tween)
		animated_text_tween.owner = self
		animated_text_tween.connect("tween_all_completed", self, "_on_animated_text_tween_completed")

		if dialog_messagelabel:
			dialog_messagelabel.percent_visible = 0
	
	MadTalkGlobals.is_during_dialog = false
	yield(get_tree(), "idle_frame")
	emit_signal("time_updated", MadTalkGlobals.gametime)
		

func _prepare_sheet_sequence_map(sheet_name, sequence_id) -> int:
	# Check if we need to lookup and add this sheet/sequence to map
	# Happens the first time it is accessed
	if not sheet_name in sheet_sequence_to_index:
		sheet_sequence_to_index[sheet_name] = {}
	if not sequence_id in sheet_sequence_to_index[sheet_name]:
		var found = false
		for i in range(dialog_data.sheets[sheet_name].nodes.size()):
			if dialog_data.sheets[sheet_name].nodes[i].sequence_id == sequence_id:
				sheet_sequence_to_index[sheet_name][sequence_id] = i
				found = true
				break
		if not found:
			return FAILED
			
	return OK
	


func _retrieve_sequence_data(sheet_name: String = "", sequence_id: int = 0) -> Resource:
	if not sheet_name in dialog_data.sheets:
		debug_print("Requested sheet \"%s\" which doesn't exist" % sheet_name)
		return null
	var sheet_data = dialog_data.sheets[sheet_name]

	if (not sheet_name in sheet_sequence_to_index) or (not sequence_id in sheet_sequence_to_index[sheet_name]):
		debug_print("Sequence ID %s not mapped in sheet \"%s\" when it should" % [sequence_id, sheet_name])
		return null
	var sequence_index = sheet_sequence_to_index[sheet_name][sequence_id]

	if sequence_index >= sheet_data.nodes.size():
		debug_print("Sequence index %s out of node range in sheet \"%s\" when it should" % [sequence_index, sheet_name])
		return null
	return sheet_data.nodes[sequence_index]

func _retrieve_item_data(sequence_data, item_index: int = 0) -> Resource:
	if not sequence_data:
		return null
		
	if item_index >= sequence_data.items.size():
		return null
	return sequence_data.items[item_index]



func _anim_dialog_main_visible(show: bool = true) -> void:
	# Must be coroutine - must have a `yield` in every possible path
	
	if show:
		# Show main dialog interface if not yet visible
		if not dialog_maincontrol_active:
			dialog_maincontrol_active = true
			if TransitionAnimationName_DialogFadeIn != "":
				dialog_anims.play(TransitionAnimationName_DialogFadeIn)
				yield(dialog_anims, "animation_finished")
			else:
				if dialog_maincontrol:
					dialog_maincontrol.show()
				yield(get_tree(), "idle_frame")
		else:
			yield(get_tree(), "idle_frame")
	
	else:
		# Hide dialog box
		if dialog_maincontrol_active:
			if TransitionAnimationName_DialogFadeOut != "":
				dialog_anims.play(TransitionAnimationName_DialogFadeOut)
				yield(dialog_anims, "animation_finished")
			else:
				if dialog_maincontrol:
					dialog_maincontrol.hide()
				yield(get_tree(), "idle_frame")
			
			dialog_maincontrol_active = false
		else:
			yield(get_tree(), "idle_frame")

func _anim_dialog_messagebox_visible(show: bool = true) -> void:
	# Must be coroutine - must have a `yield` in every possible path
	
	if show:
		# Show message box
		if not dialog_messagebox_active:
			dialog_messagebox_active = true
			if TransitionAnimationName_MessageBoxFadeIn != "":
				dialog_anims.play(TransitionAnimationName_MessageBoxFadeIn)
				yield(dialog_anims, "animation_finished")
			else:
				if dialog_messagebox:
					dialog_messagebox.show()
				yield(get_tree(), "idle_frame")
		else:
			yield(get_tree(), "idle_frame")
	
	else:
		# Hide message box
		if dialog_messagebox_active:
			if TransitionAnimationName_MessageBoxFadeOut != "":
				dialog_anims.play(TransitionAnimationName_MessageBoxFadeOut)
				yield(dialog_anims, "animation_finished")
			else:
				if dialog_messagebox:
					dialog_messagebox.hide()
				yield(get_tree(), "idle_frame")
			
			dialog_messagebox_active = false
		else:
			yield(get_tree(), "idle_frame")


func _anim_dialog_text_visible(show: bool = true, percent_visible_range: Array= [0.0, 1.0], skip_animation: bool = false) -> void:
	# Must be coroutine - must have a `yield` in every possible path

	if show:
		# Display animation always plays even if text is already visible
		dialog_messagelabel_active = true
		if AnimateText:
			if TransitionAnimationName_TextShow != "":
				dialog_anims.play(TransitionAnimationName_TextShow)
				# If AnimateText is used, AnimationPlayer is not expected to
				# handle text progression, so we wait the normal way
				yield(dialog_anims, "animation_finished")
			else:
				yield(get_tree(), "idle_frame")
		
			if not skip_animation:

				if dialog_messagelabel:
					dialog_on_text_progress = true
					dialog_messagelabel.percent_visible = percent_visible_range[0]
					# Tween text progression
					animated_text_tween.remove_all()
					animated_text_tween.interpolate_property(
						dialog_messagelabel, "percent_visible", 
						percent_visible_range[0], percent_visible_range[1], 
						AnimatedTextMilisecondPerCharacter * dialog_messagelabel.text.length() * 0.001, 
						Tween.TRANS_LINEAR)
					animated_text_tween.start()
					if sfx_key_press:
						sfx_key_press.play()
					yield(self, "text_display_completed") # both user interaction or animation_finished are routed here
					if sfx_key_press:
						sfx_key_press.stop()
					dialog_on_text_progress = false
			
			else:
				if dialog_messagelabel:
					dialog_messagelabel.percent_visible = 1.0
				
			
		else:
			if TransitionAnimationName_TextShow != "":
				if not skip_animation:
					dialog_on_text_progress = true
					dialog_anims.play(TransitionAnimationName_TextShow)
					yield(self, "text_display_completed") # both user interaction or animation_finished are routed here
					dialog_on_text_progress = false
				else:
					dialog_anims.assigned_animation = TransitionAnimationName_TextShow
					dialog_anims.seek(0)
					dialog_anims.advance(dialog_anims.current_animation_length)
			else:
				yield(get_tree(), "idle_frame")
			
		
	else:
		if dialog_messagelabel_active:
			if TransitionAnimationName_TextHide != "":
				dialog_anims.play(TransitionAnimationName_TextHide)
				yield(dialog_anims, "animation_finished")
			dialog_messagelabel.percent_visible = 0
			yield(get_tree(), "idle_frame")
			dialog_messagelabel_active = false
		
		else:
			yield(get_tree(), "idle_frame")


func _anim_dialog_menu_visible(show: bool = true) -> void:
	# Must be coroutine - must have a `yield` in every possible path

	if show:
		# Menu is always regenerated when shown
		# So animation is also always played
		dialog_menu_active = true
		if TransitionAnimationName_MenuFadeIn != "":
			dialog_anims.play(TransitionAnimationName_MenuFadeIn)
			yield(dialog_anims, "animation_finished")
		else:
			if dialog_menu:
				dialog_menu.show()
			yield(get_tree(), "idle_frame")
		
	else:
		if dialog_menu_active:
			if TransitionAnimationName_MenuFadeOut != "":
				dialog_anims.play(TransitionAnimationName_MenuFadeOut)
				yield(dialog_anims, "animation_finished")
			else:
				if dialog_menu:
					dialog_menu.hide()
				yield(get_tree(), "idle_frame")
			
			dialog_menu_active = false
		else:
			yield(get_tree(), "idle_frame")


func _assemble_button(id: int, text: String, parent_node: Node) -> Node:
	var new_btn = DialogButtonSceneFile.instance() if DialogButtonSceneFile else Button.new()
	
	parent_node.add_child(new_btn)
	new_btn.set(DialogButtonTextProperty, text)
	# _on_menu_button_pressed() is used to multiplex all button signals into one
	new_btn.connect(DialogButtonSignalName, self, "_on_menu_button_pressed", [id])
	
	return new_btn
	
	
func _assemble_menu(options: Array) -> int:
	# options = [<list of DialogNodeOptionData>]
	# Fields:
	#     DialogNodeOptionData.text            : String = ""
	#     DialogNodeOptionData.connected_to_id : int    = -1

	if not dialog_buttons_container:
		debug_print("Menu button container not set")
		return 0
		
	# Remove any previous buttons
	var old_buttons = dialog_buttons_container.get_children()
	for btn in old_buttons:
		dialog_buttons_container.remove_child(btn)
		btn.queue_free()
		
	# Add new buttons
	var count = 0
	for option_item in options:
		var _new_btn = _assemble_button(option_item.connected_to_id, option_item.text, dialog_buttons_container)
		count += 1
		
	return count
	
func _check_option_condition(var_name: String, operator: String, given_value: String) -> bool:
	var result = false
	var var_value = MadTalkGlobals.get_variable(var_name, 0)
	
	var value = given_value.to_float() if given_value.is_valid_float() else MadTalkGlobals.get_variable(given_value, 0)
	
	match operator:
		"=":
			result = (var_value == value)
		"!=":
			result = (var_value != value)
		">":
			result = (var_value > value)
		">=":
			result = (var_value >= value)
		"<":
			result = (var_value < value)
		"<=":
			result = (var_value <= value)
		_:
			result = false
	
	return result
	
func set_variable(variable_name: String, value) -> void:
	MadTalkGlobals.set_variable(variable_name, value)

func get_variable(variable_name: String):
	return MadTalkGlobals.get_variable(variable_name)

func start_dialog(sheet_name: String, sequence_id : int = 0) -> void:
	if MadTalkGlobals.is_during_dialog:
		dialog_queue.append( DialogCursor.new(sheet_name, sequence_id, 0) )
		return

	# Start processing dialog. This flag will cause any other calls to be queued
	# Other in-game effects might also read this flag (such as pausing enemies)
	MadTalkGlobals.is_during_dialog = true
	# `yield` statements from now on are safe, even nested into method calls
	# -----------------------------------------------------
	
	is_abort_requested = false
	is_skip_requested = false
	
	emit_signal("dialog_started", sheet_name, sequence_id)
	
	# The "dialog_started" signal can be used to prevent some dialogs by
	# skipping or aborting dialogs before they start
	# This is useful when player repeats a level from a checkpoint, you still
	# need the effects, but not the text, so skip still calls the method below
	if (not is_abort_requested):
		var result = run_dialog_sequence(sheet_name, sequence_id)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")

	MadTalkGlobals.is_during_cinematic = true
	
	# Hide menu if needed
	if dialog_menu_active:
		yield(_anim_dialog_menu_visible(false), "completed")

	# Hide text if needed
	if dialog_messagelabel_active:
		yield(_anim_dialog_text_visible(false), "completed")
		
	# hide message box if needed
	if dialog_messagebox_active:
		yield(_anim_dialog_messagebox_visible(false), "completed")
	
	# Hide dialog if needed
	if dialog_maincontrol_active:
		yield(_anim_dialog_main_visible(false), "completed")
	
	MadTalkGlobals.is_during_cinematic = false
	

	# -----------------------------------------------------
	# Stop processing dialog. Next calls will run immediately. 
	# There must be no `yield` statements from now on to the end of the method
	MadTalkGlobals.is_during_dialog = false
	
	# If something is queued, process it before anything else calls this again
	if dialog_queue.size() > 0:
		var dialog_cursor = dialog_queue.pop_front()
		if dialog_cursor:
			start_dialog(dialog_cursor.sheet_name, dialog_cursor.sequence_id)


func run_dialog_sequence(sheet_name: String, sequence_id : int = 0) -> void:
	# Asking to run an invalid dialog fails silently
	if not sheet_name in dialog_data.sheets:
		yield(get_tree(), "idle_frame")
		debug_print("Sheet \"%s\" not found" % sheet_name)
		return
	
	# Make sure we have the node mapped
	if _prepare_sheet_sequence_map(sheet_name, sequence_id) == FAILED:
		yield(get_tree(), "idle_frame")
		debug_print("Mapping sheet \"%s\", sequence %s failed" % [sheet_name, str(sequence_id)])
		return
		
	var result = run_dialog_item(sheet_name, sequence_id)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	
	emit_signal("dialog_sequence_processed", sheet_name, sequence_id)
	


func run_dialog_item(sheet_name: String = "", sequence_id: int = 0, item_index: int = 0) -> void:

	var sequence_data : DialogNodeData = _retrieve_sequence_data(sheet_name, sequence_id)
	var dialog_item : DialogNodeItemData = _retrieve_item_data(sequence_data, item_index)
	var should_run_next_item = true
	
	if is_abort_requested:
		emit_signal("dialog_aborted")
	
	elif sequence_data: # Sanity check
		
		if dialog_item:
			# We still have an item to process inside this sequence
			
			match dialog_item.item_type:
				DialogNodeItemData.ItemTypes.Message:
					# dialog_item.message_speaker_id : String
					# dialog_item.message_text       : String
					
					# We show the message here, but we don't hide, since the
					# player might want to re-read the last message when a set
					# of options is presented in the end of the sequence
					
					# Skipping a dialog before a message is shown prevents the
					# messages from showing up. But if this sequence has a menu
					# we have to show the last message, so we still assing all
					# the values, we just don't play the show animations or
					# wait for confirmation
					
					MadTalkGlobals.is_during_cinematic = true

					# If text still on screen, hide text
					yield(_anim_dialog_text_visible(false), "completed")
						
					# if speaker has changed, we hide dialog to show again
					if (dialog_item.message_speaker_id != last_speaker_id) or (dialog_item.message_speaker_variant != last_speaker_variant):
						yield(_anim_dialog_messagebox_visible(false), "completed")
						emit_signal("speaker_changed", last_speaker_id, last_speaker_variant, dialog_item.message_speaker_id, dialog_item.message_speaker_variant)
					
					MadTalkGlobals.is_during_cinematic = false
						
					# Modify values
					var speaker_name = character_data[dialog_item.message_speaker_id].name \
						if (dialog_item.message_speaker_id in character_data) \
							else dialog_item.message_speaker_id
					
					if dialog_speakerlabel:
						if (dialog_speakerlabel is RichTextLabel) and (dialog_speakerlabel.bbcode_enabled):
							dialog_speakerlabel.bbcode_text = speaker_name
						else:
							dialog_speakerlabel.text = speaker_name
					
					var dialog_message_data = msgparser.process(dialog_item.message_text, MadTalkGlobals.variables)
					var dialog_message_text = dialog_message_data[0]
					var dialog_message_anim_pause_percentages = dialog_message_data[1]
					
					dialog_message_text = dialog_message_text.replace("$time", MadTalkGlobals.gametime["time"])
					dialog_message_text = dialog_message_text.replace("$date_inv", MadTalkGlobals.gametime["date_inv"])
					dialog_message_text = dialog_message_text.replace("$date", MadTalkGlobals.gametime["date"])
					dialog_message_text = dialog_message_text.replace("$weekday", MTDefs.WeekdayNames[MadTalkGlobals.gametime["weekday"]] )
					dialog_message_text = dialog_message_text.replace("$wday", MTDefs.WeekdayNamesShort[MadTalkGlobals.gametime["weekday"]] )

					if dialog_messagelabel:
						if (dialog_messagelabel is RichTextLabel) and (dialog_messagelabel.bbcode_enabled):
							dialog_messagelabel.bbcode_text = dialog_message_text
						else:
							dialog_messagelabel.text = dialog_message_text
							
					if dialog_speakeravatar:
						if (dialog_item.message_speaker_id in character_data):
							# are we using a valid variant?
							var char_variants = character_data[dialog_item.message_speaker_id].variants
							if (dialog_item.message_speaker_variant != "") and (dialog_item.message_speaker_variant in char_variants) \
									and (char_variants[dialog_item.message_speaker_variant] is Texture):
								dialog_speakeravatar.texture = char_variants[dialog_item.message_speaker_variant]
							# Otherwise use default avatar
							else:
								dialog_speakeravatar.texture = character_data[dialog_item.message_speaker_id].avatar
						else:
							dialog_speakeravatar.texture = null
					
					
					if not is_skip_requested:
					
						MadTalkGlobals.is_during_cinematic = true
					
						emit_signal("message_text_shown", 
							dialog_item.message_speaker_id,
							dialog_item.message_speaker_variant,
							dialog_message_text,
							dialog_item.message_hide_on_end
						)
					
						# Show main dialog interface if not yet visible
						yield(_anim_dialog_main_visible(true), "completed")
						
						# Show message box if not visible yet
						yield(_anim_dialog_messagebox_visible(true), "completed")
						
						# Request voice clip to be played
						# Signal is emitted even when clip path is blank, so the
						# previous audio can be stopped if this is desired
						emit_signal("voice_clip_requested", dialog_item.message_speaker_id, dialog_item.message_voice_clip)

						MadTalkGlobals.is_during_cinematic = false
						
						var previous_percent_visible = 0.0
						
						# If there are no pauses, we will have
						# dialog_message_anim_pause_percentages = [1.0]

						# If skip was requested after we enter this match case,
						# we just don't wait for user confirmation to dismiss
					
						for percent_visible in dialog_message_anim_pause_percentages: 
							# If skip was requested between pauses, process here
							if is_skip_requested or is_abort_requested:
								break
							
							# Show text
							yield(_anim_dialog_text_visible(true, 
								[previous_percent_visible, percent_visible]
							), "completed") # Handles animation skip internally

							if dialog_messagelabel:
								dialog_messagelabel.percent_visible = percent_visible
							previous_percent_visible = percent_visible
							
							# Confirmation to dismiss the message
							if (not is_skip_requested) and  (not is_abort_requested):
								yield(self, "dialog_acknowledged")
						
						
					if (dialog_item.message_hide_on_end != 0) or is_skip_requested:
						# We hide this message box as explicitly requested
						MadTalkGlobals.is_during_cinematic = true
						yield(_anim_dialog_text_visible(false), "completed")
						yield(_anim_dialog_messagebox_visible(false), "completed")
						MadTalkGlobals.is_during_cinematic = false
					
					# Else: we do not hide the message straight away as next step
					# could be showing options. We hide when we leave the sequence
					last_speaker_id = dialog_item.message_speaker_id
					last_speaker_variant = dialog_item.message_speaker_variant
					last_message_item = dialog_item
					last_message_text = dialog_message_text
				
			
				
				DialogNodeItemData.ItemTypes.Condition:
					# dialog_item.condition_type   : MTDefs.ConditionTypes
					# dialog_item.condition_values : Array
					# dialog_item.connected_to_id  : int = -1
					
					# Test the condition
					var result = evaluate_condition(dialog_item.condition_type, dialog_item.condition_values)
					if result is GDScriptFunctionState:
						result = yield(result, "completed")
					
					if not result:
						# Condition failed, we have to branch out of this sequence
						should_run_next_item = false
						
						# If something is connected, we jump
						# If nothing is connected, this simply means aboting
						if dialog_item.connected_to_id > -1:
							yield(run_dialog_sequence(sheet_name, dialog_item.connected_to_id), "completed")
				
				
				
				DialogNodeItemData.ItemTypes.Effect:
					# dialog_item.effect_type   : MTDefs.EffectTypes
					# dialog_item.effect_values : Array
					
					# "Change sheet" effect is an exception and is implemented
					# directly in this block since it is scope-dependant
					if dialog_item.effect_type == MTDefs.EffectTypes.ChangeSheet:
						var new_sheet_name = dialog_item.effect_values[0]
						var new_sequence_id = dialog_item.effect_values[1]
						
						# Jump to sheet if valid, aborting dialog otherwise
						should_run_next_item = false
						if new_sheet_name in dialog_data.sheets:
							yield(run_dialog_sequence(new_sheet_name, new_sequence_id), "completed")
							
					# Animation and custom effects are also exception since 
					# involves pausing the sequence until it finishes
					elif dialog_item.effect_type == MTDefs.EffectTypes.WaitAnim:
						var anim_name = dialog_item.effect_values[0]
						# Animation must exist and not be loop
						if effects_anims and (effects_anims.has_animation(anim_name)) and (
							not effects_anims.get_animation(anim_name).loop
						):
							effects_anims.play(anim_name)
							MadTalkGlobals.is_during_cinematic = true
							yield(effects_anims, "animation_finished")
							MadTalkGlobals.is_during_cinematic = false
							
					elif dialog_item.effect_type == MTDefs.EffectTypes.Custom:
						if custom_effect_object and (custom_effect_method != ""):
							var custom_id = dialog_item.effect_values[0]
							var custom_data_array = MadTalkGlobals.split_string_autodetect_rn(dialog_item.effect_values[1])
							
							#emit_signal("activate_custom_effect", custom_id, custom_data_array)
							var result = custom_effect_object.call(custom_effect_method, custom_id, custom_data_array)
							if result is GDScriptFunctionState:
								result = yield(result, "completed")
						
					else:
						# All other effects have global scope and are
						# implemented in a separate method
						activate_effect(dialog_item.effect_type, dialog_item.effect_values)

				_:
					debug_print("Invalid item type for item %s in sequence ID %s at sheet \"%s\"" % [item_index, sequence_id, sheet_name])
					

			emit_signal("dialog_item_processed", sheet_name, sequence_id, item_index)

			# We don't check if item_index is the last one, since the first
			# invalid index will be properly handled in following call
			# causing the sequence to be gracefully concluded (see below)
			if should_run_next_item:
				yield(run_dialog_item(sheet_name, sequence_id, item_index + 1), "completed")
		
		
		else: # All items processed
			
			# Running an item_index higher than last valid one means we 
			# finished the item list and have to process the end of sequence
			# This means showing options or routing to the "continue" ID 
			
			# Even if we have options, some of them can be conditional, and
			# it might be the case all of them are and no item is left to
			# be shown at the menu. So we have to buffer a list
			var options_to_show = []
			
			for option_item in sequence_data.options:
				if (not option_item.is_conditional) or _check_option_condition(
					option_item.condition_variable, 
					option_item.condition_operator, 
					option_item.condition_value
				):
					options_to_show.append(option_item)
			
			# Process options and build menu only with remaining items
			if options_to_show.size() > 0:
				# When there are menu options, "continue" is not used
				
				# If we skipped dialog, there are no visible messages. We show
				# last one back
				print("last_message_item finally is: %s" % str(last_message_item))
				if is_skip_requested and (last_message_item.message_hide_on_end == 0):
					
						MadTalkGlobals.is_during_cinematic = true
					
						emit_signal("message_text_shown", 
							last_message_item.message_speaker_id,
							last_message_item.message_speaker_variant,
							last_message_text,
							last_message_item.message_hide_on_end
						)
					
						# Show main dialog interface if not yet visible
						yield(_anim_dialog_main_visible(true), "completed")
						
						# Show message box if not visible yet
						yield(_anim_dialog_messagebox_visible(true), "completed")
						
						# We do not play voice
						
						MadTalkGlobals.is_during_cinematic = false
						
						# Show text
						yield(_anim_dialog_text_visible(true, [0, 1], true), "completed") # skips to end
					
						
				MadTalkGlobals.is_during_cinematic = true
				
				# Make sure menu is not visible
				if dialog_menu_active:
					yield(_anim_dialog_menu_visible(false), "completed")
				# Regenerate buttons
				var __= _assemble_menu(options_to_show)
				# Show menu
				yield(_anim_dialog_menu_visible(true), "completed")
				
				MadTalkGlobals.is_during_cinematic = false
				
				# There is always at least one optiong there otherwise we
				# would not be into this `if`
				dialog_buttons_container.get_child(0).grab_focus()
				
				# Wait for an option
				# Selecting an option is mandatory and dialog halts until then
				var option_id = yield(self, "menu_option_activated")
				
				# Hide menu
				MadTalkGlobals.is_during_cinematic = true
				yield(_anim_dialog_menu_visible(false), "completed")
				MadTalkGlobals.is_during_cinematic = false
				
				if option_id > -1:
					# jumping to another sequence might also be same speaker 
					# so we don't hide anything yet
					yield(run_dialog_sequence(sheet_name, option_id), "completed")
				else:
					last_speaker_id = ""
					last_speaker_variant = ""
					emit_signal("dialog_finished", sheet_name, sequence_id)


			elif sequence_data.continue_sequence_id > -1:
				# "continue" ID might also be same speaker so we don't hide anything yet
				yield(run_dialog_sequence(sheet_name, sequence_data.continue_sequence_id), "completed")
				
			else:
				last_speaker_id = ""
				last_speaker_variant = ""
				emit_signal("dialog_finished", sheet_name, sequence_id)

	else:
		debug_print("Invalid sequence \"%s\" in sheet \"%s\"" % [sequence_id, sheet_name])
	

	yield(get_tree(), "idle_frame") # Forces this to be coroutine in any case
	
	
	
func evaluate_condition(condition_type, condition_values):
	# Returns true if condition is met, false otherwise
	# May or may not morph into coroutine, caller must check with:
	#     if result is GDScriptFunctionState:
	#	      result = yield(result, "completed")
	
	match condition_type:
		MTDefs.ConditionTypes.Random:
			var random_value = rng.randf_range(0.0, 100.0)
			return (random_value < condition_values[0])
		
		MTDefs.ConditionTypes.VarBool:
			var var_value = bool_as_int(MadTalkGlobals.get_variable(condition_values[0], 0))
			var expected_value = bool_as_int(condition_values[1])
			return (var_value == expected_value)
			
		MTDefs.ConditionTypes.VarAtLeast:
			var var_value = float(MadTalkGlobals.get_variable(condition_values[0], 0.0))
			return (var_value >= float(condition_values[1]))

		MTDefs.ConditionTypes.VarUnder:
			var var_value = float(MadTalkGlobals.get_variable(condition_values[0], 0.0))
			return (var_value < float(condition_values[1]))

		MTDefs.ConditionTypes.VarString:
			var var_value = str(MadTalkGlobals.get_variable(condition_values[0], ""))
			return (var_value == str(condition_values[1]))
		
		MTDefs.ConditionTypes.Time:
			var min_time = MadTalkGlobals.split_time(condition_values[0])
			var target_min_time_float = MadTalkGlobals.time_to_float(min_time[0], min_time[1])

			var max_time = MadTalkGlobals.split_time(condition_values[1])
			var target_max_time_float = MadTalkGlobals.time_to_float(max_time[0], max_time[1])

			var curr_time_float = MadTalkGlobals.time_to_float(
				MadTalkGlobals.gametime["hour"], 
				MadTalkGlobals.gametime["minute"]
			)
			
			# Normal range - e.g. 6:00-18:00
			if target_min_time_float < target_max_time_float:
				return (curr_time_float >= target_min_time_float) and (curr_time_float <= target_max_time_float)
			# Inverted range - e.g. 18:00-6:00
			else:
				return (curr_time_float >= target_min_time_float) or (curr_time_float <= target_max_time_float)
		
		MTDefs.ConditionTypes.DayOfWeek:
			var target_min_day = condition_values[0]
			var target_max_day = condition_values[1]
			var curr_day = MadTalkGlobals.gametime["weekday"]

			# Normal range - e.g. Mon-Fri
			if target_min_day < target_max_day:
				return (curr_day >= target_min_day) and (curr_day <= target_max_day)
			# Inverted range - e.g. Sat-Sun
			else:
				return (curr_day >= target_min_day) or (curr_day <= target_max_day)
		
		MTDefs.ConditionTypes.DayOfMonth:
			var target_min_day = condition_values[0]
			var target_max_day = condition_values[1]
			var curr_day = MadTalkGlobals.gametime["day"]

			# Normal range - e.g. 14 - 21
			if target_min_day < target_max_day:
				return (curr_day >= target_min_day) and (curr_day <= target_max_day)
			# Inverted range - e.g. 25 - 14
			else:
				return (curr_day >= target_min_day) or (curr_day <= target_max_day)

		MTDefs.ConditionTypes.Date:
			var target_min_day_month = MadTalkGlobals.split_date(condition_values[0])
			var target_min_intdate = MadTalkGlobals.date_to_int(target_min_day_month[0], target_min_day_month[1], 1)
			
			var target_max_day_month = MadTalkGlobals.split_date(condition_values[1])
			var target_max_intdate = MadTalkGlobals.date_to_int(target_max_day_month[0], target_max_day_month[1], 1)

			var curr_intdate = MadTalkGlobals.date_to_int(MadTalkGlobals.gametime["day"], MadTalkGlobals.gametime["month"], 1)

			# Normal range - e.g. 15/02 - 25/03
			if target_min_intdate < target_max_intdate:
				return (curr_intdate >= target_min_intdate) and (curr_intdate <= target_max_intdate)
			# Inverted range - e.g. 25/12 - 28/02
			else:
				return (curr_intdate >= target_min_intdate) or (curr_intdate <= target_max_intdate)

		MTDefs.ConditionTypes.ElapsedFromVar:
			var delta_time = float(condition_values[0])
			var target_time = MadTalkGlobals.get_variable(condition_values[1], 0)
			var delta_currently_elapsed = MadTalkGlobals.time - target_time
			
			return (delta_currently_elapsed >= delta_time)

		MTDefs.ConditionTypes.Custom:
			if (not custom_condition_object) or (custom_condition_method == "") or (not custom_condition_method in custom_condition_object):
				return false
			
			var custom_id = condition_values[0]
			var custom_data_array = MadTalkGlobals.split_string_autodetect_rn(condition_values[1])
					
			var result = custom_condition_object.call(custom_condition_method, custom_id, custom_data_array)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
			
			if (result is int) or (result is float):
				return (result != 0)
				
			elif result is bool:
				return result
				
			else:
				return false

		_:
			return false
	

func activate_effect(effect_type, effect_values):
	match effect_type:
		MTDefs.EffectTypes.ChangeSheet:
			# This effect is an exception and is not implemented here
			pass
		
		MTDefs.EffectTypes.SetVariable:
			MadTalkGlobals.set_variable(effect_values[0], float(effect_values[1]))
		
		MTDefs.EffectTypes.AddVariable:
			var old_value = float(MadTalkGlobals.get_variable(effect_values[0]))
			MadTalkGlobals.set_variable(effect_values[0], old_value + float(effect_values[1]))
		
		MTDefs.EffectTypes.RandomizeVariable:
			var range_min = float(effect_values[1])
			var range_max = float(effect_values[2])
			MadTalkGlobals.set_variable(effect_values[0], 
				rng.randf_range(range_min, range_max)
			)
		
		MTDefs.EffectTypes.StampTime:
			MadTalkGlobals.set_variable(effect_values[0], MadTalkGlobals.time)
			
		MTDefs.EffectTypes.SpendMinutes:
			MadTalkGlobals.time += int(round(float(effect_values[0]) * 60))  # value * 60s
			MadTalkGlobals.update_gametime_dict()
			emit_signal("time_updated", MadTalkGlobals.gametime)

		MTDefs.EffectTypes.SpendDays:
			MadTalkGlobals.time += int(round(float(effect_values[0]) * 24*60*60)) # value * 24h * 60m * 60s
			MadTalkGlobals.update_gametime_dict()
			emit_signal("time_updated", MadTalkGlobals.gametime)

		MTDefs.EffectTypes.SkipToTime:
			MadTalkGlobals.time = MadTalkGlobals.next_time_at_time(effect_values[0])
			MadTalkGlobals.update_gametime_dict()
			emit_signal("time_updated", MadTalkGlobals.gametime)

		MTDefs.EffectTypes.SkipToWeekDay:
			MadTalkGlobals.time = MadTalkGlobals.next_time_at_weekday(effect_values[0])
			MadTalkGlobals.update_gametime_dict()
			emit_signal("time_updated", MadTalkGlobals.gametime)
		
		MTDefs.EffectTypes.Custom:
			# This effect is an exception and is not implemented here
			pass


func dialog_acknowledge():
	# Called externally by UI to confirm a dialog message and progress dialog
	if dialog_on_text_progress:
		# This happened during text progression
		if AnimateText:
			animated_text_tween.remove_all()
			#dialog_messagelabel.percent_visible = 1.0 # moved to run_dialog_item()
		
		else:
			if (dialog_anims.current_animation == TransitionAnimationName_TextShow) and dialog_anims.is_playing():
				dialog_anims.advance(dialog_anims.current_animation_length - dialog_anims.current_animation_position)
		
		emit_signal("text_display_completed")
	elif not MadTalkGlobals.is_during_cinematic:
		emit_signal("dialog_acknowledged")
		
func dialog_abort():
	is_abort_requested = true
	dialog_acknowledge()
	
func dialog_skip():
	is_skip_requested = true
	dialog_acknowledge()
		
func change_scene(scene_path: String) -> void:
	# Convenience method giving access to get_tree().change_scene()
	# as a node method in the scene tree
	var __= get_tree().change_scene(scene_path)

func _on_animation_finished(anim_name):
	if anim_name == TransitionAnimationName_TextShow:
		emit_signal("text_display_completed")
		
func _on_animated_text_tween_completed():
	emit_signal("text_display_completed")
	

func _on_menu_button_pressed(id):
	emit_signal("menu_option_activated", id)

