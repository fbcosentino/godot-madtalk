extends RefCounted

const name := "Text"

const description := """[b]Text Exporter[/b]

This exporter generates a pure text output, containing [b]only messages[/b]. (It doesn't include conditions, effects, etc.)

The main purpose of this exporter is to send dialog lines to translators, who fill the empty lines, which are then imported back into MadTalk.

The generated text will have the following syntax:
[color=#ffff77]
[Sheet: <sheet name goes here>]
	Sheet description goes here

[Sequence: <internal code goes here, don't touch it>]

<internal code> speaker id: Message contents go here
{locale1}: Translation to locale1 goes here
{locale2}: Translation to locale2 goes here
...

<more code> another speaker id(variant): Another essage contents go here

<more code> speaker id: -=-=-
This is a multiline message.
it can contain as many lines as required. It will continue until the multiline marker is found, as below.
-=-=-

[Sequence: <another sequence internal code>]
<more code> yet another speaker id: Yet nother essage contents go here
[/color]

Locale versions are always optional, and don't have to be consistent. They only show up if the message contains one, or if the locale is forced (to generate blank lines for translators).
A real example:

[color=#ffff77]
[Sheet: mary_meets_peter]
	Dialog when Mary meets Peter, on level 3 

[Sequence: ix5f6]

<jvHg7> mary: Who are you?
{pt}: Quem é você?
{jp}: 誰ですか?

<9x86f> peter(scared): Don't shoot! I'm a friend!

<g145a> peter(relieved): My name is Peter. I'm the innkeeper.
{pt}: Eu sou Pedro, o dono da estalagem.

[Sequence: xkj87]

<qe53y> mary: -=-=-
I'm leaving now. See you!

[lb]i[rb](Honestly, I hope I never come back!)[lb]/i[rb]
-=-=-
[/color]

When forcing a locale, the existing text for locales will only include the forced ones, and if the message doesn't have them, blank lines will be included. You can force several locales on the same export.
Example, forcing locale "pt" on the previous example will export as below:

[color=#ffff77]
[Sheet: mary_meets_peter]
	Dialog when Mary meets Peter, on level 3 

[Sequence: ix5f6]

<jvHg7> mary: Who are you?
{pt}: Quem é você?

<9x86f> peter(scared): Don't shoot! I'm a friend!
{pt}: 

<g145a> peter(relieved): My name is Peter. I'm the innkeeper.
{pt}: Eu sou Pedro, o dono da estalagem.

[Sequence: xkj87]

<qe53y> mary: -=-=-
I'm leaving now. See you!

[lb]i[rb](Honestly, I hope I never come back!)[lb]/i[rb]
-=-=-
{pt}: 
[/color]

"""

const MULTILINE_MARKER := "-=-=-"

func multiline_message(input: String) -> String:
	var result := input
	if "\n" in result:
		result = MULTILINE_MARKER + "\n" + result + "\n" + MULTILINE_MARKER
	return result


func export(sheet_data: DialogSheetData, force_locales := []) -> String:
	var result := "[Sheet: %s]\n" % sheet_data.sheet_id
	result += "	%s\n\n" % sheet_data.sheet_description
	
	var all_locales: bool = (force_locales == [])
	
	for dialog_node: DialogNodeData in sheet_data.nodes:
		result += "[Sequence: %s]\n\n" % dialog_node.resource_scene_unique_id 
		
		for dialog_item: DialogNodeItemData in dialog_node.items:
			if dialog_item.item_type == DialogNodeItemData.ItemTypes.Message:
				var speaker: String = dialog_item.message_speaker_id
				if dialog_item.message_speaker_variant != "":
					speaker = "%s(%s)" % [speaker, dialog_item.message_speaker_variant]
				
				result += "<%s> %s: %s\n" % [dialog_item.resource_scene_unique_id, speaker, multiline_message(dialog_item.message_text)]
				for locale in dialog_item.message_text_locales:
					if all_locales or (locale in force_locales):
						result += ("{%s}: " % locale) + multiline_message(dialog_item.message_text_locales[locale]) + "\n"
				
				for locale in force_locales:
					if not locale in dialog_item.message_text_locales:
						result += ("{%s}: \n" % locale)
							
				
				result += "\n"
	
	return result
