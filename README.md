# MadTalk - A Feature-Rich Dialog System for Godot

_After a 3-year anniversary this plugin is finally getting a decent README lol_

_(This branch is the Godot 3.x version. It_ **is** _ported to Godot 4.x - will be in the branch `4.x` - but I'm still ironing out some rough things here and there, so some things in the editor UI on 4.x are janky - the runtime works fine though)_

&nbsp;

MadTalk is the dialog plugin behind almost all Mad Parrot games with dialogs, and some others. It's feature rich, genre and layout agnostic, focused on visual editing, beginner friendly (as possible) while remaining powerful enough for advanced users, can be used in any type of game and coupling it to game code or not is entirely your option. You can use it just to show some messages, or if you want you can go all the way into using it as a framework.

![](docs/showcase.png)

You can check a feature showcase in the [example project](https://madparrot.itch.io/madtalk-example-project) _(be aware that project is more than 2 years old, so if it feels outdated it's because it is)_.

If you want to play a game using MadTalk to see it in real life, one example is [Ciara and the Witch's Cauldron](https://subvertissement.itch.io/ciara-and-the-witchs-cauldron).

Other dialog plugins are made to be very generic and neutral, which is good in itself, but might be daunting (or even confusing) for beginners. MadTalk on the [otter hand](docs/otter_hand.png) is not afraid of getting specific, and thrives in its unique set of features (some which are specifically helpful for some game genres) putting it aside from average dialog systems around. The strong points are:

&nbsp;

### Compact Visual Editor 
  
  * Editor uses visual nodes (dialog diagrams don't look like Scratch software)
  * Visualizing diagrams is very compact, screen space used is clean and neat due to the _sequence_ model: all blocks of dialog have a main path, and everything which doesn't branch from main path is a _sequence_, shown in the same node as a stack (visually similar to blender modifier stack)
  * Layouts are not cluttered with lines all around, only uses lines for actual branching between sequences (no separate nodes for `if`s, setting variables, etc)
  * Dialog sequences are organised in sheets, which are exactly what it says on the tin. Any point of any dialog can jump to any point of any other sheet without needing lines
  * Editing messages includes a panel for real time _bbcode_ visualization
  * Nearly all options and features anywhere in the plugin include a question mark button with a help popup explaining what that is and how to use it, so you don't need lots of documentation browsing to know how to use things
  
![](docs/img_01.png)

![](docs/img_02.png)

![](docs/img_07.png)

  
&nbsp;
  
### Offloads Game Logic (if you want)

  * Conditions and effects allow you to control the dialogs from within the dialogs, making designing it more intuitive (compared to code scattered around the project)
  * The dialog diagrams double as a form of visual scripting, so depending on the type of game (e.g. visual novels) you can bring a lot (or even all!) of game logic into it for free and reduce the coding effort
  * All of the above is optional, and MadTalk will not get in the way of your code if you prefer to do everything by hand. You can also have a middleground with best of both worlds, using custom conditions and effects triggering signals and evaluation methods to decide branching via your own code even in the middle of sequencing
  * Again, each condition and effect comes with their own question mark explaining the parameters
  
![](docs/img_08.png)

![](docs/img_04.png)

![](docs/img_05.png)
  
  
&nbsp;

### Full Feature Set for In-Game Time handling

This is the point where MadTalk excels: some games (iconic example being _Harvest Moon_ and life simulation visual novels) have an in-game time and calendar, actions spend time, and some dialog branches and game events are affected by it (e.g. something different happens if you talk to that NPC on a Saturday evening).

MadTalk has an entire subsystem to handle in-game time automatically for you:

  * A set of effects available in dialog sequences to advance time in several ways (adding time or days, moving clock/calendar to a certain time/date, stamping current in-game time into a variable)
  * A set of conditions for dialogs to branch, based on in-game time (several options for time/date range, and time spent since a timestamp from a variable)
  * In-game time controlled by MadTalk can be read and written by your code from anywhere so you don't have to rely on dialog effects at all for controlling and/or fine tuning it
  
![](docs/img_03.png)


There are more features, such as handling animations (with or without narration text), typing sounds, and some other bonbonnière. Again, you _don't have_ to use any of those features. If you want to just show some message sequences in the game UI, it will work too and will not get in your way. 

Also, as is customary in dialog plugins, you can also have ye olde conditional text inside message content as well, but they can't branch the sequences if they are inside text. They only change what is shown in the message.

![](docs/img_09.png)

----
&nbsp;


## Usage

You need four steps:

  * Obviously, install the plugin and activate it. You need the `res://addons/madtalk` folder (which contains the editor plugin) _and_ the `res://madtalk` folder (which contains the runtime interpreter and dialog data, which are part of your exported game) 
  * Create a set of `Control` nodes to show the dialog messages (examples further below)
  * Put a `Node` in the scene holding the runtime script, set the values you want and tell it which `Control` nodes to use (the ones you created above)
  * Add at least two function calls somewhere in your code called in the node mentioned above: `start_dialog("sheet id")` to fire a dialog sheet, and `dialog_acknowledge()` to progress the dialog (usually pressing space, enter, clicking mouse, etc)

After that, you can have fun doing actual dialog design in the editor, provided as an extra tab in the very top of the engine.

&nbsp;

### The MadTalk Node

Each scene which shows dialog must have a node with the MadTalk runtime. That is a node of the type `Node`, put anywhere in your scene, which will access the UI nodes, emit signals, and where you set options in the inspector. That is also where you set your character names and avatars (which is optional by the way).

Why is this node not a singleton? Because you might want to have different settings for different scenes. E.g. you might have a scene in your game which is _The Beach Episode_ where the character avatars show sunglasses and swimsuits, UI nodes have a different layout, a separate set of animations, etc. The [example project](https://madparrot.itch.io/madtalk-example-project) shows an extreme case of this, as the game has four scenes: a text game, a visual novel, a top down 2D RPG, and a 3D first person. All share the same dialog sheets, NPC IDs, etc, while being visually and mechanically completely different games. This is done on purpose to showcase the independence between the plugin and the game style.

Add a `Node` to your scene (in this readme it will be named `MadTalk`) and attach the `res://madtalk/madtalk_runtime.gd` script to it.

This will give you _a lot_ of options. Don't worry, you can ignore most of that. For a minimal setup you need to worry about only three - the bare minimum control nodes.


![](docs/madtalk_node.png)

&nbsp;

### Control Nodes

MadTalk uses `Control`-derived nodes as UI. If your game is based on a `Node2D` scene, you'll need a `CanvasLayer` to hold them (as the viewport coordinates in Controls and 2D camera are incompatible). But if your scene is based on `Control` nodes (e.g. point-and-click, visual novels, etc) or `Spatial` (all 3D games) you don't need this, just place the dialog UI nodes anywhere convenient in your tree and they'll work.

As a _bare minimum_, you need three nodes: 
  * A top dialog node, to hold _all_ dialog stuff inside. The rule is: hiding this node must make all dialog-related stuff disappear. It can be any `Control`-derived type. I like to use a `Control` aligned to `full rect` covering the viewport with mouse filter to `stop` so the player can't click on anything in the scene while the dialog is on screen - but that's a personal preference
  * A message box, similar concept as above, except this is only for messages (not including menus, standing pictures, etc - but does include name and avatar, if any). Hiding this should be enough to make all message-related things disappear. It can be any `Control`-derived node, but this node usually is the message rectangle (holding text, avatar, name labels, etc) so it's common for it to be a `Panel`, `TextureRect` or `NinePatchRect` (but doesn't _have_ to be)
  * A `RichTextLabel` to hold the actual message text (it was designed to be a `RichTextLabel` even if you don't use _BB code_, and compatibility with a common `Label` is not garanteed)
  
You can have anything else you want inside those nodes, for decoration, UI, etc. MadTalk will only touch the nodes you tell it to. Also a node being inside another (e.g. the message label inside the message box) doesn't mean they have to be _immediate_ children - you can have a very complex hierarchy there if you want. They just have to be inside of it somehow.
  
  
![](docs/bare_minimum_tree.png)

Drag and drop the nodes to the `MadTalk` node as below, and you're set.


![](docs/bare_minimum_node_exports.png)

For this bare minimum setup, the dialogs should not use menu options (as there are no nodes set for that).


Visually, this game will run very dry, while in a final game you want messages to show up and hide in a juicy way. In another section you'll see how to automatically call animations for that.

&nbsp;

#### Menus

If you want to have menu options in your dialogs, you need two more nodes:
  * A menu box, similar to the message box (and sibling to it, that is, it's also inside the top dialog node), where hiding this node hides all the menu-related stuff. Like the message box, this would normally be a `Panel`, `TextureRect` or `NinePatchRect` (but doesn't _have_ to be)
  * A container node, the type being one of the automatic layout containers (`VBoxContainer` being the most common, but could also be `HBoxContainer`, one of the flow containers, etc)

Naturally, drag them to the `MadTalk` node so it's aware of it.

![](docs/minimum_with_menu_node_exports.png)

That's it.

If this is all you do, your menus will already work and you're good to go. See next session to make your first dialog sheet.

_Optional:_ You'll notice the button shown in your menu when you run your game is the default Godot `Button`, which might not be the aesthetic you want in your game. You can have a custom button instead: prepare a nice node to your liking (one of the `Button`-derived classes, like `Button` itself or `TextureButton`), save that button as a separate scene file, and drag and drop that scene file to `MadTalk`'s `Dialog Button Scene File` property, and that one will be used for your menus instead of the default one. Again, entirely optional. Just for testing, leaving that field blank will use Godot's default button.

_Advanced: if you want to use as menu option a scene which is not even a button (something complex, even), all you have to do is create an `export` variable in there (with setter function) to set the text, and a signal emitted when the option is selected, and then set `MadTalk`'s properties `Dialog Button Text Property` and `Dialog Button Signal Name` to match those._

_If instead of all of this above you prefer to manage your menus entirely yourself in code, you can do that with custom menus, explained further down somewhere in this readme._

Now all you have to do to test the system is making some dialogs.

&nbsp;

### Designing Dialog Sheets

Dialogs are made of sheets (really like sheets of paper) which are the diagrams. Sheets contain sequences, which are the node blocks you can drag around. Each sequence has a list of items inside, which can be a:
  * Message
  * Effect
  * Condition
  * Menu option

When the dialog sequence runs, the items will run from top to bottom (except, obviously, menu options).

When you first open the dialog editor, you'll probably see this:

![](docs/editor_01.png)

The right side panel shows the current sheet, the list of existing sheets, and a button to create a new sheet (you can collapse this panel). The rest of the screen is the sheet which is currently open.

When you just create a new sheet, it comes with the first sequence. All sequences have a numeric ID (you can't change that). By default all dialogs start at the sheet's sequence ID `0`, so this one has the `START` title to remind you. On the top bar of the sequence you can create new items and set the menu options.

Sequences don't need to have any menu options, but if they do, each sequence can have only one menu and is always in the end. This is because one sequence means one path without branching out, and menus necessarily branch because there is no "default" option, so they end the sequence.

![](docs/editor_01b.png)

In the plus icon, you can create messages, conditions and effects.

After you create any of them, you can right click the item to edit, reorder it in the sequence, or remove.

![](docs/editor_02.png)

(Reordering by drag-n-drop is a planned feature.)

In the menu options icon, you can set the menu options for this sequence. If you don't have any, the menu will be replaced by a default "Continue" output, which you can connect to any other sequence to continue the dialog. If you set options, MadTalk will work the menu for you in the end of this sequence, and branch accordingly. The sequence will show one output for each of the options, for you to connect to other sequences in this sheet.

![](docs/editor_03.png)

![](docs/editor_03b.png)


You can click the tiny condition icon in the left of a menu option to set a condition which is required to show that button. If the condition is not met, the menu will show as if that button didn't exist. (Menu option conditions are limited to variable comparisons.)

![](docs/editor_04.png)

![](docs/editor_04b.png)

To create a new sequence, right click on any empty space. To connect them, just drag an output from a sequence to an input of another sequence. Connecting a sequence to itself _is valid_, but only do that if you know what you're doing.



&nbsp;

### Characters, Names and Avatars

You can put a `Label` inside your message box (not the top dialog node) to show the speaker name (the character who is saying the message), and drag that to `Dialog Speaker Label`. Similarly, you can place a `TextureRect` somewhere inside the message box to show the avatar, and drag it to `Dialog Speaker Avatar`. They don't have to be _immediate_ children of the message box node, but have to be inside of it (same applies to the message label).


So far, we don't have any characters set. _The dialogs will already work_ (even without the name label and avatar). They already work even with just the first three nodes. If you create a dialog sheet, put some messages, and fire it with `$MadTalk.start_dialog("some sheet id")` (and use input to confirm via `$MadTalk.dialog_acknowledge()`), the messages will show properly, and if you have name label and avatar nodes, the name label will show the speaker ID and the avatar will be empty. For very simple games without avatars this is fine, just use the speaker ID field as name (or not even that if you only have narrator, or another way to indicate the speaker, like dialog bubbles).

To show avatars we have to create a list of characters, in `MadTalk`'s first property. Set the number of how many characters you'll have in this scene, and for each of them create a `MTCharacterData` resource. You'll see each one of them has `ID`, `Name`, `Avatar`, and `Variants` fields.

  * `ID` is the speaker ID you type when writing the messages in the dialog editor
  * `Name` is what you want to show up in the name label
  * `Avatar` is a _default_ avatar, shown when no variant was specified in the dialog. For many games this is the only one you need
  * `Variants` are a list of different avatars for the same character. They can be emotions (happy face, sad face, etc), or could be an entire different interpretation, up to you (e.g. healthy, hurt, tired, different clothes, etc). This is a dictionary where the keys are Strings (the variant ID) and the values are the images. Using variants is _entirely optional_ and you can ignore for now

![](docs/list_of_chars.png)

When you edit a message item, there are the `Speaker ID` and `Variant` fields you use to specify who says that message (see below). They will be taken from the `MadTalk` node _where the dialog was invoked_ (where you called `start_dialog()`), so you can have different character lists in different scenes. (You could even have multiple runtime nodes in the same scene, but I never did that and see no use for it anyway... but it would work.)

![](docs/img_02.png) 


&nbsp;

### Voice Clips

Each text message can also specify a voice clip (see above), which is the `String` path for an audio file in your project. MadTalk will not _play_ it automatically, it will instead _emit a signal_ passing that as argument. All you have to do is connect that signal to a method of yours, where you load (consider preloading) that clip into an `AudioStreamPlayer` or similar and play it.

The reason why MadTalk doesn't handle audio itself internally is because you might want different ways of doing it, such as some audio bus routing. Also e.g. for a visual novel, it would be indeed an `AudioStreamPlayer`, but for a 3D game you might want to use the speaker ID to select the `AudioStreamPlayer3D` belonging to the NPC node in the 3D world, so the voice will come from that direction in the 3D sound.

&nbsp;

### Juicy Dialogs - Transition Animations

The `MadTalk` node has two property slots for `AnimationPlayer` nodes. One of them is used internally to make dialogs juicy, the other one holds animations you can call yourself from the dialog sheets via effects (will be explained later on).

If you want dialog animations, you should create an `AnimationPlayer` node (good practice to put it inside the top dialog node), possibly called `DialogTransitions` or something more to your liking, drag it to `MadTalk`'s `Dialog Animation Player` property, and create a few animations in it, to handle the transitions.

There are four pairs of animations used, each pair handles showing (fade in) and hiding (fade out):
  * `Transition Animation Name Dialog` is the name of the animation pair to show and hide the top dialog node. This normally doesn't have to be fancy. In most cases, your visible nodes will be inside the message and menu boxes, it's actually rare for something else to be visible in the dialog top node, but it's possible (like vignetes, decoration, or a background made darker or blurry, etc). I sometimes use the top dialog node as a `ColorRect` set to black with some alpha transparency, so it makes the game scenario a darker background while the dialog is going on
  * `Transition Animation Name Message Box` is the name of the animation pair showing and hiding the message box, assuming the top dialog node is visible (_don't control both in the same animation!_). This is one of the animations the players will see the most (other one being the text)
  * `Transition Animation Name Menu` is similar to above, but showing and hiding the menu box instead (again assuming the top dialog node is visible)
  * `Transition Animation Name Text` is used to gradually show the text (it can be a typing effect, or fading in, or something else, there are no requirements). This is one of the animations the players will see the most (other being the message box). You _don't need to do this manually_, see below

![](docs/anim_transitions.png)

The text animation name option is there in case you want a custom one, but you don't need to do that yourself. Instead you can use the automatic typing animation, which is handled internally with Tweens. All you have to do is enable the `Animate Text` property, and configure the speed in `Animated Text Milisecond Per Character`, and MadTalk will do all the magic for you. If you also want a typing sound playing during that animation handled automatically for you, you can put an `AudioStreamPlayer` node (maybe inside the top dialog node), set it with a typing sound effect (set to loop), and drag that node to `MadTalk`'s `Key Press Audio Stream Player` property. And done, typing animation _and_ typing sound done automagically for you.

&nbsp;

### Effect Animations

You can have a separate `AnimationPlayer` node (maybe called something like `EffectAnimations`), which you can easily invoke from the dialogs. Just drag it to the `Effects Animation Player` property. One of the dialog effects is called `Play Animation and Wait`. If you use this effect (specifying an animation name), that animation will be played from _this_ animation player, and the dialog will pause until this animation is complete.

![](docs/img_10.png)


You can, of course, play any animation from anywhere (waiting for completion or not, up to you) manually, invoked from the dialog sheets using custom effects (shown later on). But using the `Effects Animation Player` property involves no coding at all.


&nbsp;

### Year of Reference

Finally, this last property you would only touch if you are using the in-game time features and you need to fine tune the calendar. In a nutshell, the only purpose of this is to align the weekdays and leap years to your liking. The in-game time will start at 01 January of the year 1 (you can change this, of course, via code). You don't have to show "year 1" to your players, you can manually add any value to this when showing the year in the interface (so e.g. you'd add 2467 if in your game's lore the year is 2468), but internally the game starts at year 1. Which weekday is in-game 01/01/0001? Which year will be the next leap year?

MadTalk will link your in-game Year 1 to one year of the real world, and that is the reference year. So if you leave the default `1970`, means the first day of your in-game time will be a Thursday, two years before the next leap year. Because 01/01/1970 was a Thursday and the next leap year was 1972. Players will _never_ see the reference year, the number `1970` will _never_ be used for anything in your game _whatsoever_. The _only_ purpose is to define the weekdays and leap years.

So, e.g. if you want your game's January 1st to be a Sunday, and the very first year of in-game time to be a leap year, you can check the real world calendar to find when it happened (in this case, `1984`) and use that as reference year.

If you're not using the in-game time features, then don't even bother about this field.


&nbsp;

### Custom Menu

If having a sequential container with buttons (e.g. `VBoxContainer` with a list of `TextureButton`) is not how your game works, and you want to manually assemble and control your menus from code, you can use the external menu feature. It uses a signal and a method call to interface your game code with MadTalk. To use the external menu feature, simply don't assign anything to `Dialog Buttons Container`. If that field is empty, MadTalk will assume you're using custom menus.

If you're using that feature and the dialog reaches a menu, MadTalk will not handle the buttons, instead it will emit the `external_menu_requested` signal passing the list of options the menu should have (as Array of String). You do whatever you want with this information.

When your custom code decides which of the options should be selected, you call the `select_menu_option(option_index)` method, where `option_index` is the index of the option you selected, from the Array passed in the signal above.

As example, if you are using custom menu (`Dialog Buttons Container` is empty) and you run this sequence:

![](docs/editor_03b.png)

The `MadTalk` node will emit the signal `external_menu_requested` passing as argument the `Array`: 

```gdscript
["Let's walk in the park", "Let's eat a pão de queijo", "Nevermind"]
```

And if you want to continue the dialog with the player selecting "Let's eat a pão de queijo", you call:

```gdscript
$MadTalk.select_menu_option(1)     # Array indices start at 0
```


&nbsp;

### Dialog Variables

For many reasons (such as scope, avoiding spaghetti code, etc), MadTalk doesn't read your game code variables directly. Instead it has an internal `Dictionary` of dialog variables, and those are used in the effects and conditions, as well as in the message text. You can read and write them at any time from anywhere in your game code, explained further below (but changing them from outside when a dialog is already on screen might lead to Unexpected Behaviour :tm: ).

Conditions always expect variables to contain numbers (`int` or `float` are both acceptable). For now there is no condition to compare a variable to a `String`.

You can use dialog variables inside text messages in two ways: substitution and conditional text.

Substitution accepts numeric or String variables, and uses the syntax `<<variable_name>>`, example:

```
Hello, <<player_name>>!
```

Conditional text treats variables as numbers and uses the syntax `{{if variable operator value: text}}`, where `operator` is numerical comparison (`<`, `>`, `<=`, `>=`, `=`, or `!=`), example:

```
Hello{{if money >= 100: , milady}}!
```

Notice the equal operator is just one `=` (unlike `C`). Also the spaces around the operator and after `:` must be respected.

Substitution and conditional text can appear anywhere in the messages, in any quantity (just not nested). Conditional text can have substitutions. Unfortunately for now there is no `else` (it's planned, though).

You can use this for larger blocks of text as well, just be careful with spaces and new lines to avoid unnecessary blank spaces. Example:

```
Hello!
{{if money >= 100: Nice to meet, <<player_name>>.
It's great to see such a fine lady.
When I was young, my dream was to become someone as elegant as yourself,
but alas, here I am.
}}{{if money < 100: I haven't seen you before.
Are you sure your name is on the list?
You can't enter if it isn't.
}}
```

I consider improving this using GDScript evaluation for the conditions (or something similar), but it's low priority now. It's easier and more debug friendly to make separate sequences for those messages and use branching.

There are also some special variables used in substitution: `$time`, `$date`, `$date_inv`, `$weekday` and `wday`. You don't use the `<<>>` sintax for them, you just type them normally. They correspond to the fields from the in-game time dictionary, and meaning for them is explained further below in the section about signals.

&nbsp;

### Globals

MadTalk _does have_ a singleton, called `MadTalkGlobals`. It handles dialog variables and in-game time, as those are shared across all scenes. Most methods and properties are in the `MadTalk` node in your scene, but some are in the singleton.

The following properties are in the `MadTalkGlobals` singleton:

* `is_during_dialog`: 

Exactly what it says on the tin. I use this one all the time to keep NPC and enemy AI in paused state during dialogs by simply adding an `if` at the start of their `_physics_process`:

```gdscript
func _physics_process(delta):
    if MadTalkGlobals.is_during_dialog:
        return
    
    # Rest of the code starts here
    # ...
```

Just be careful to handle animations which might be ongoing for them.

&nbsp;

* `is_during_cinematic`:

Name might be a bit misleading now, I swear it made more sense in earlier versions. This is true during the juicy animations from the `Dialog Animation Player` transition animations, as well as the effect animations played via the `Play Animation and Wait` effect.


* `time`: stores the in-game time in seconds since the start of the calendar (midnight January 1st year 0001). Modifications require calling a method, explained further below


&nbsp;

### Export Vars for Dialog Sheets

You might want to have nodes in your scene with `export` variables for dialog sheets, so you can give them a sheet ID in the inspector. 

E.g. you have a bunch of generic NPCs, and when you approach them and press `E` to interact, they fire a dialog. The script is the same, but different NPCs may or may not have separate dialog sheets.

You can put an export var named `madtalk_sheet_id` (or any name starting with `madtalk_sheet_id`) and MadTalk will do some inspector magic for you, showing a `...` button helping you select the sheet among the list of sheets you have.

![](docs/insp_01.png)


&nbsp;

### Methods


For simple dialog games, you would use only two methods from the list below (to start a dialog sheet, and to acknowledge messages). For average complexity dialogs, you might also use the get and set methods for dialog variables. The remaining methods are very rarely used, if ever.

Called in the `MadTalk` node:

* `start_dialog(sheet_id: String)`: starts a new dialog, from the start sequence (ID `0`). If a dialog is already in progress, this one will be queued and start immediately when the previous one completes. If you want to start at another sequence, use the syntax below
* `start_dialog(sheet_id: String, sequence_id: int)`: same as above, but starts directly at the specified sequence ID instead of `0`. Use only if you know what you're doing, as it's easy to lose track of things 
* `dialog_acknowledge()`: if a message is still in the middle of showing text, causes the text to show entirely, immediately. Otherwise, progress the dialog to the next item
* `dialog_abort()`: interrupts the dialog, ignoring everything that would come after the current item. When I made this second version of the plugin back in mid 2020 I expected this to be useful, but 3 years and 26 published games and drafts later, and I never aborted a dialog ever
* `dialog_skip()`: when a dialog is skipped messages are not shown anymore, but unlike abort, all the dialog chain is still traversed, all conditions are checked and branched, animations are played and effects take place. This is important since game logic can be critically based on those effects, like setting variables, and also events e.g. if an effect in the end of a conversation spawns a boss, skipping the dialog still spanws the boss, while aborting doesn't
* `select_menu_option(option_index)`: when using external menu, selects the menu option by index
* `get_sheet_names()`: returns an Array of String with the IDs of all the sheets in the database

&nbsp;

Called in the `MadTalkGlobals` singleton:

* `set_variable(variable_name: String, value)`: sets the value for the dialog variable
* `get_variable(variable_name: String)`: returns the value for the dialog variable
* `export_game_data()`: returns a `Dictionary` with all the game data handled by MadTalk (dialog variables and in-game time), to be serialized for saving the game state
* `import_game_data(data: Dictionary)`: the reverse of the above, sets the dialog variables and in-game time based on a `Dictionary` previously exported by `export_game_data()`. If the data was exported _during_ a dialog, importing it will not suddenly show the dialog message where it was. There is no saved track of ongoing dialog. Avoid allowing the player to save the game in the middle of a dialog

Methods to control in-game time via code are being reviewed, as I want something very user friendly (which currently it is not). But for now, if you want to change the in-game time, you can (_carefully!!!_) modify the `time` property in the `MadTalkGlobals`, which contains the number of seconds of in-game time elapsed since the start of calendar (midnight of January 1st of year 0001). Just remember to call the `update_gametime_dict()` method afterwards, example:

```gdscript
# Moves the in-game time 45 days to the future
MadTalkGlobals.time += 45*(24*60*60) # 45 days * 24h * 60 min * 60 secs = 45 days in seconds
MadTalkGlobals.update_gametime_dict()
```



&nbsp;

### Signals


_**You don't need any signals at all**_ to use MadTalk.

&nbsp;

_All signals are optional._

&nbsp;

That said... they are a lot :sweat_smile:

![](docs/sig_01.png)

The ones you'd use the most are the five below. Please notice the first two _are not real signals_. I mean, the signals exist in the inspector and you can connect things there, but MadTalk will not _really emit_ the signals. It will, instead, read which method you connected, and then call the method in the conventional way. This is so it can wait for yields and get the return value, which signals can't. If you connect more than one method in them, only the first one of each will be used.
 
&nbsp;

* `activate_custom_effect(custom_id: String, custom_data: Array of String)`: 

When using the effect called _custom effect_, it will call the method connected to this signal, passing as argument the data you entered in the corresponding edit dialog (e.g. `custom_id`=`"teleport_player"` and `custom_data`=`["city1"]`). 

`custom_data` can have multiple items (one per line you entered in the dialog editor).

The dialog _will wait_ for the method to finish, so if you have a `yield` in the method code, the dialog will wait for that `yield` (this is not a real signal).

![](docs/img_05.png)

&nbsp;

* `evaluate_custom_condition(custom_id: String, custom_data: Array of String) -> bool`:

One of the conditions is called _custom condition_, and it will call the method connected here. If the method returns `true`, the sequence continues, while if the method returns `false`, the dialog will branch out. The arguments work the same way as `activate_custom_effect`.

The dialog will pause and wait for the return value, so if you have a `yield` in the method code, the dialog will wait for that `yield` (this is not a real signal).

Example, a custom condition in a sequence, and the method connected to the `evaluate_custom_condition` signal:

![](docs/custom_cond.png)


&nbsp;

* `speaker_changed(previous_speaker_id: String, previous_speaker_variant: String, new_speaker_id: String, new_speaker_variant: String)`:

This is probably the most powerful of MadTalk's signals, emitted when the speaker ID or variant changed between messages. The arguments are the ID and variant for the last message as well as for the current message about to be shown. 

This can be used to modify the interface to match changes in speaker, e.g. to position the dialog bubble over the head of the character, or to show and hide (or highlight or blur) standing pictures, etc.

Example 1 - highlighting standing pictures:

![](docs/example_vn1.gif)

&nbsp;

Example 2 - using variants to control message font:

![](docs/example_sm.gif)


&nbsp;

Example 3 - using speaker ID to point the camera to character:

![](docs/example_db.gif)

&nbsp;

This signal is only emitted if one of the fields has actually changed (either different speakers, or different variants for same speaker).

Example, if previous message was from speaker ID `alice`, no variant, and next message has speaker ID `bob` with variant `happy`, the signal emitted will be:

```gdscript
speaker_changed("alice", "", "bob", "happy")
``` 

&nbsp;

* `voice_clip_requested(speaker_id: String, clip_path: String)`:

As explained in the _Voice Clip_ section earlier in this readme, this signal is emitted whenever showing a message with a voice clip set. The argument `speaker_id` is the speaker ID for the message, and `clip_path` is a String containing the path to the audio file. The method connected to this signal is responsible for playing the audio.

&nbsp;

* `external_menu_requested(menu_options)`:

As explained in the _Custom menu_ section, this signal is emitted when a menu is required but there is no node set in the `Dialog Buttons Container`property in the `MadTalk` node. Argument is an `Array` of `String` containing the menu options.

&nbsp;


If the in-game time is relevant to your game, the signal below might be useful (e.g. showing clock on the UI):

* `time_updated(datetime_dict)`: emitted whenever the in-game time changes via dialog (not via code). Argument is a `Dictionary` with the fields:
  * `year`
  * `month`
  * `day`
  * `weekday` (numeric)
  * `weekday_name` (String)
  * `wday_name` - abbreviated version of `weekday_name` (String)
  * `date` - day and month, format international `dd/mm` (String)
  * `date_inv` - day and month inverted, format US `mm/dd` (String)
  * `hour`
  * `minute`
  * `second` (MadTalk doesn't work with seconds, will only be different from `00` if you modify by code)
  * `time` - hour and minute, format 24h `HH:MM` (String)

&nbsp;

Signals below are used very rarely, so if you're still getting started you can forget they exist.

* `message_text_shown(speaker_id, speaker_variant, message_text, force_hiding)`: 

Emitted when a message is about to be shown (but not yet), and the arguments are the values set in the message item. This can be used e.g. to keep a message log for the player to review past dialogs:

![](docs/example_wth.png)

You can also use this signal to bypass MadTalk's default message showing system and implement your own without having to change the plugin source.

&nbsp;

* `dialog_started(sheet_name, sequence_id)`: emitted when a dialog starts. Arguments are the sheet ID and the sequence ID where it started

* `dialog_finished(sheet_name, sequence_id)`: emitted when a dialog ends. Arguments are the last sheet ID and the sequence ID where it ended. _NOT_ emitted when dialog is aborted (perhaps it should? Feedback appreciated)

* `dialog_aborted`: _this one_ is emitted instead if dialog is aborted

&nbsp;

* `dialog_acknowledged` and `text_display_completed`: 

When `dialog_acknowledge()` is called, its behaviour depends on if the text is already fully shown or not. If the text is still being shown, `dialog_acknowledge()` will cause it to be entirely shown instantly, and in that case `text_display_completed` is emitted. Otherwise, it will cause the dialog to proceed to next item, and in that case `dialog_acknowledged` is emitted. 

If the player doesn't interact and the text is shown to the end naturally via animation or Tween, `text_display_completed` is also emitted

&nbsp;

* `dialog_sequence_processed(sheet_name, sequence_id)`: emitted when a sequence is completed. The order of the sequences is _not_ respected (as they use recursive calls) and this signal will probably be revised

* `dialog_item_processed(sheet_name, sequence_id, item_index)`: emitted when an item inside a sequence is completed. The order is _not_ necessarily respected (as they use recursive calls) and this signal will probably be revised

* `menu_option_activated(option_id)`: emitted when a menu option is selected, either via internal automatic menu, or custom menu)


&nbsp;

----

## Important Tip

If you have long streams of messages without menus or branching, don't make them a single, long sequence. Break them down into several shorter sequences. This mainly for two reasons:

* It's more performance-friendly. When sequences run the entire sequence is read, and traversing the items is an Array lookup. The shorter the Array, the better. Also the recursive call method will be replaced soon, which means previous already traversed sequences can be unloaded while the next one runs.

* Most importantly, _it will not drive you crazy_. New items are added to the bottom of the stack. If you divide a 30 items sequence into 5 sequences of 6 items, and you decide to add an effect at the beginning, you add to the first one and move it up 6 times. If you have a single sequence, you will have to move it up 30 times!

![](docs/tip_01.png)


----

&nbsp;

## Planned Features

  * Invoking lip animation via signals (WIP)
  * Change the recursive call system to something else to take it easier on the call stack
  * Locale for text messages
  * Moving sequence items via dragging

&nbsp;

----

&nbsp;

## History and Fun Facts

I'm writing the below because this plugin has some emotional value to me.

  * Early 2020 - Started working on the dialog system as soon as pandemic started, initially as part of an adventure game (abandoned). Finished first version before mid year
  
  * Mid 2020 - Decision to decouple the system from the game (which allows the game to rest in peace) and make it as a publicly available framework - was still using JSON for dialog storage then, I didn't know how to write editor plugins so the dialog editor was a Godot application I had to run and save the dialog data to a file
  
  * Somewhere 2020 - Learned how to make dialog plugins and work with resources. Kissed the JSON system good bye and revamped everything to use resources and built-in dialog editor (the message/condition/effect system was kept per the original)
  
  * Nov 2020 - [pulawskig](http://pulawskig.itch.io) made the game _Lovely Story_ for the [Godot Wild Jam #27](https://itch.io/jam/godot-wild-jam-27/rate/825625) and we discussed the dialog tools used. I decided MadTalk deserved more visibility and crushed development as if there was no tomorrow to polish the editor plugin interface with nice images and buttons, to propose presenting it in a talk in the upcoming [GodotCon Jan 2021](https://godotengine.org/article/online-godotcon-2021-schedule/)
  
  * Dec 2020 - I have ADHD, and my hyperfocus suddenly decided to turn off and I could not work on it anymore. The only thing left to do at the time before proposing was _one single bug_, which in retrospect sounds infuriating
  
  * Entirety of 2021 and 2022 - Absolutely nothing. I missed GodotCon, I didn't have a public repo, and the longer it passed that way the worse I felt, and the worse I felt the more difficult it was to pick it up again. I mean, just to say it wasn't "nothing", somewhere in 2021 I _did_ try to pick it up again, created a repo to put on github (but repo was empty), created the [example project](https://madparrot.itch.io/madtalk-example-project) in Sept 2021, but then I lost my job, moved to a different city, my HDD died before I could put anything on github, taking it all down to the bottom of the ocean. The bitbucket repo I had was still before the revamp and coupled to the abandoned game and wasn't an option. The only reason why this still exists is because the good soul of [JohnGabrielUK](https://github.com/johngabrieluk) happened to have the most recent version of the plugin added to a game for which he gave me repo access, and I could recover it from there
  
  * Jan 2023 - The ADHD gods smiled at me again and I suddenly felt _I could do this_. Interestingly enough, it was January 1st, the default first day of in-game time, when I finally added the second, revamped version of MadTalk to github. Yeeyy. The only problem was I didn't write any readme, so people would find this repo and have no interest in it whatsoever
  
  * Fall 2023 (now as I type) - There is a new GodotCon around (Nov 2023). I considered proposing to present this, but I'm still sore I couldn't finish it in 2021. Then Unity made controversial announcements causing an influx of developers into Godot, who would be searching for nice stuff in Godot asset store. This fuelled me to finally make this readme (which is the longest I ever wrote) to finally put this plugin into the asset store. The only new feature added after all this time was the voice clip, which was added for the [Warthunder Type H](https://madparrot.itch.io/warthunderth-gwj36) game, and the external menu, added for a WIP game. Everything else (including UI polish) is as of today pretty much the version made aiming the GodotCon Jan 2021. Hopefully it will be easier to work on it further on, as people can see it and give feedback
  
&nbsp;

&nbsp;


And in case you're curious to see the first version (the early 2020 one, coupled to the game and I needed to run the editor and save the JSON file):

![](docs/old_01.png)

![](docs/old_02.png)

Pretty much the same thing! 

Just... ugly.