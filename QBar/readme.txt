QBar - Quest Item Button Bar
----------------------------
Ever been questing and had to find all those usable quest items in your bags all the time, then this addon is for you. No longer will you have to keep your bags open to do daily bombing quests!

This addon will automatically create a dynamic buttonbar for all those usable quest items, it also checks if your equipped gear for usable quest items.
As using items is a secure function, QBar is not able to update the bar or the set keybinding when in combat. This will only be changed outside of combat.

You may ask, why use this over the buildin quest item buttons? Well, the buildin buttons will only show items you receive when you accept the quest,
any usable quest items you loot during a quest will not be shown, QBar will however. QBar will also show items which starts a quest, so you wont miss them in between all the cluttered loot.
The default buttons also goes away once you complete the quest, but the item is not actually removed until you turn the quest in, and you may want to use the item even after the quest is complete.

If you do not wish to show a certain item on QBar, you can ignore it by holding down Shift and clicking on it.

Button Facade Support
---------------------
Officially there is no support for button facade, but someone has been kind enough to code one for QBar. You can find it here:
http://www.wowinterface.com/downloads/info14644-QBarButtonFacadeFanUpdate.html

Command Line Parameters
-----------------------

/qb toggle
Toggles QBar being enabled or not.

/qb scale <value>
Sets the scale of the buttons, default is 1.

/qb size <value>
Sets the unit size of the buttons, default is 36.

/qb padding <value>
Configures the padding between the buttons, default is 1.

/qb tips
Determines if item tips are shown when you move your mouse over the buttons.

/qb vertical
Toggles between horizontal and vertical button bar.

/qb mirror
Changes the anchor direction, top/bottom or left/right, depending on the vertical setting.

/qb lock
Toggles the button frame being locked, use this command to move the buttons around.

/qb reset
Resets the QBar frame to the middle of the screen in case it was pushed off screen.

/qb add <itemlink>
Adds a custom item to the bar. To remove an item again, simply shift click it, as when you're ignoring an item.

/qb clearignore
Clears the ignore list, and shows all items again. You can shift click an item to ignore it.

/qb clearuser
Clears the user list from items, added using the add command.

/qb bind
Use this command to set the key binding for the last item used, this is pretty vital for all the dailies.

Lacking Features, Problems & Ideas
----------------------------------
- Manage the update of keybinding, no need to unbind and rebind if it stays the same as before.