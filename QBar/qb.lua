-- ***** 3.1 INFO ******
--Quest Log Functions
--* NEW - GetQuestLogSpecialItemCooldown
--* NEW - GetQuestLogSpecialItemInfo
--* NEW - IsQuestLogSpecialItemInRange
--* NEW - UseQuestLogSpecialItem

-- ****** Some 3.x patch *******
-- GetContainerItemQuestInfo

local _G = getfenv(0);

-- Addon
local modName = ...;
local qb = CreateFrame("Frame",modName,UIParent);

-- Global Chat Message Function
function AzMsg(msg) DEFAULT_CHAT_FRAME:AddMessage(tostring(msg):gsub("|1","|cffffff80"):gsub("|2","|cffffffff"),0.5,0.75,1.0); end

-- Constants
local UPDATE_DELAY = 0.25;
local ITEMID_PATTERN = "item:(%d+)";
local QUEST_TOKEN = (	-- Obtain the localization of the "Quest" type for items -- [7.0.3/Legion] API Removed: GetAuctionItemClasses()
	GetItemClassInfo and GetItemClassInfo(LE_ITEM_CLASS_QUESTITEM or 12)
	or LOOT_JOURNAL_LEGENDARIES_SOURCE_QUEST
	or "Quest"
);	
local slots = {
	"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
	"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
	"MainHandSlot", "SecondaryHandSlot",
};
local IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

-- Config
local cfg;
local defConfig = {
	enabled = true,
	showTips = true,
	vertical = false,
	mirrored = false,
	btnSize = 36,
	scale = 1,
	padding = 1,
};

-- These items are not marked as being quest items, but we want to include them anyway
local qItems = {
	23818,	-- Stillpine Furbolg Language Primer
	23792,	-- Tree Disguise Kit
	24084,	-- Draenei Banner
	24278,	-- Flare Gun
	5456,	-- Divining Scroll (item has no Use: text, even though you can use it)

	11582,	-- Fel Salve
	12922,	-- Empty Canteen
	11914,  -- Cursed Ooze Jar
	11948,	-- Tainted Ooze Jar
	28038,	-- Seaforium PU-36 Explosive Nether Modulator
	28132,	-- Area 52 Special
	23361,	-- Cleansing Vial
	25465,	-- Stormcrow Amulet
	24355,	-- Ironvine Seeds
	25552,	-- Warmaul Ogre Banner
	25555,	-- Kil'sorrow Banner
	25658,	-- Damp Woolen Blanket
	25853,	-- Pack of Incendiary Bombs (Old Hillsbrad)
	24501,	-- Gordawg's Boulder

	33634,	-- Orehammer's Precision Bombs, quest from Howling Fjord
	49278,	-- Goblin Rocket Pack (ICC - Lootship)

	33096,	-- Complimentary Brewfest Sampler (Brew Fest)
	32971,	-- Water Bucket (Hallow's End)
	46861,	-- Bouquet of Orange Marigolds (Day of the Dead)
	21713,	-- Elune's Candle (Lunar Festival)

	56909,	-- Earthen Ring Unbinding Totem (Cata event)
	60501, 	-- Stormstone, Deepholm Quest

--	45067,	-- Egg Basket -- Az: offhand item, but I wanted it on my bar for a hotkey
};

--------------------------------------------------------------------------------------------------------
--                                                Main                                                --
--------------------------------------------------------------------------------------------------------

qb:SetMovable(true);
qb:SetToplevel(true);
qb:SetFrameStrata("MEDIUM");

local function OnMouseUp(self,button)
	self:StopMovingOrSizing();
	cfg.left = self:GetLeft();
	cfg.bottom = self:GetBottom();
end

local function OnUpdate(self,elapsed)
	self.updateTime = (self.updateTime + elapsed);
	if (self.updateTime > UPDATE_DELAY) then
		self:SetScript("OnUpdate",nil);
		self:UpdateButtons();
	end
end

qb:SetScript("OnMouseDown",qb.StartMoving);
qb:SetScript("OnMouseUp",OnMouseUp);
qb:EnableMouse(nil);

qb.tip = CreateFrame("GameTooltip",modName.."Tip",nil,"GameTooltipTemplate");
qb.tip:SetOwner(UIParent,"ANCHOR_NONE");

qb.items = {};

--------------------------------------------------------------------------------------------------------
--                                             Local Funcs                                            --
--------------------------------------------------------------------------------------------------------

local backDrop = { bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 3, right = 3, top = 3, bottom = 3 } };

-- Bindings Frame
local function OpenBindingFrame()
	local bindFrame = CreateFrame("Frame",nil,UIParent);
	bindFrame:SetWidth(200);
	bindFrame:SetHeight(60);
	bindFrame:SetPoint("CENTER");
	bindFrame:SetFrameStrata("DIALOG");
	bindFrame:EnableKeyboard(1);
	bindFrame:SetBackdrop(backDrop);
	bindFrame:SetBackdropColor(0.1,0.22,0.35,1);
	bindFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);

	bindFrame:SetScript("OnKeyDown",function(self,key)
		-- Check Key
		if (key == "ESCAPE") then
			if (cfg.bindKey) then
				SetBinding(cfg.bindKey);
				cfg.bindKey = nil;
				qb:UpdateBinding();
			end
			AzMsg("|2"..modName.."|r: Binding has been cleared.");
			self:Hide();
			return;
		elseif (key:match("^.SHIFT") or key:match("^.CTRL") or key:match("^.ALT")) then
			return;
		end
		-- Prefix Modifier Key
		if (IsShiftKeyDown()) then
			key = "SHIFT-"..key;
		end
		if (IsControlKeyDown()) then
			key = "CTRL-"..key;
		end
		if (IsAltKeyDown()) then
			key = "ALT-"..key;
		end
		-- Validate
		local activeBind = GetBindingAction(key);
		if (key ~= cfg.bindKey) and (activeBind ~= "") and (not activeBind:match(modName.."%d+:")) then
			AzMsg("|2Invalid|r: The hotkey |1"..key.."|r is already bound to |1"..activeBind.."|r.");
			return;
		end
		-- Clear Old Binding
		if (cfg.bindKey) then
			SetBinding(cfg.bindKey);
		end
		-- Set New Hotkey
		cfg.bindKey = key;
		AzMsg("|2"..modName.."|r: The hotkey has been set to |1"..key.."|r.");
		qb:UpdateBinding(1);
		self:Hide();
	end);

	bindFrame.hint = bindFrame:CreateFontString(nil,"ARTWORK","GameFontNormal");
	bindFrame.hint:SetPoint("CENTER");
	bindFrame.hint:SetText("Press the Desired Hotkey...\nEscape to Clear Binding");

	-- Change This Function
	OpenBindingFrame = function() bindFrame:Show(); end
end

-- Lock Frame
function qb:SetLockedStatus(lock)
	if (lock) then
		self:EnableMouse(nil);
		self:SetBackdrop(nil);
	else
		self:EnableMouse(1);
		self:SetBackdrop(backDrop);
		self:SetBackdropColor(0.1,0.22,0.35,1);
		self:SetBackdropBorderColor(0.1,0.1,0.1,1);
		self:SetWidth(cfg.btnSize + 24);
		self:SetHeight(cfg.btnSize + 24);
	end
end

-- SetEnabled
function qb:SetEnabledStatus()
	if (cfg.enabled) then
		self:RegisterEvent("BAG_UPDATE");
		self:RegisterEvent("UNIT_INVENTORY_CHANGED");
		self:RegisterEvent("QUEST_ACCEPTED");			-- Needed for items that starts a quest, when we accept it, update to remove the icon
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
		self:RegisterEvent("PLAYER_REGEN_ENABLED");
		self:RegisterEvent("UPDATE_BINDINGS");
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA");	-- Should work better than PLAYER_ENTERING_WORLD
		self:Show();
		self:RequestUpdate();
	else
		self:UnregisterAllEvents();
		self:Hide();
	end
end

if not IS_RETAIL then
	function GetContainerItemQuestInfo()
		return nil
	end
end

--------------------------------------------------------------------------------------------------------
--                                                Items                                               --
--------------------------------------------------------------------------------------------------------

local anchors = { "ANCHOR_BOTTOMLEFT", "ANCHOR_BOTTOMRIGHT", "ANCHOR_RIGHT", "ANCHOR_LEFT" };

-- Hide GTT
local function HideGTT()
	GameTooltip:Hide();
end

-- Button Scripts
local function Button_OnEnter(self)
	if (cfg.showTips) then
		local x, y = (UIParent:GetWidth() / 2), (UIParent:GetHeight() / 2);
		local left, bottom = self:GetLeft(), self:GetBottom();
		local quadrant = (left > x and bottom > y and 1) or (left < x and bottom > y and 2) or (left < x and bottom < y and 3) or (left > x and bottom < y and 4);
		GameTooltip:SetOwner(self,anchors[quadrant]);
		local bag, slot = self:GetAttribute("bag"), self:GetAttribute("slot");
		if (bag) then
			GameTooltip:SetBagItem(bag,slot);
		else
			GameTooltip:SetInventoryItem("player",slot);
		end
	end
end

-- OnClick
local function Button_OnClick(self,button)
	-- Handle Modified Click
	if (HandleModifiedItemClick(self.link)) then
		return;
	-- Ignore
	elseif (IsShiftKeyDown()) then
		if (cfg.userList[self.itemId]) then
			cfg.userList[self.itemId] = nil;
		else
			cfg.ignoreList[self.itemId] = true;
		end
		qb:RequestUpdate();
	-- Set Hotkey
	elseif (self.itemId ~= cfg.lastItem) then
		cfg.lastItem = self.itemId;
		qb:UpdateBinding(1);
	end
end

--local function Button_OnUpdate(self,elapsed)
--	if (ItemHasRange(self.link)) and (IsItemInRange(self.link,"target")) then
--		self.icon:SetVertexColor(1,1,1);
--	else
--		self.icon:SetVertexColor(0.8,0.1,0.1);
--	end
--end

-- Make Loot Button
local function CreateItemButton()
	local b = CreateFrame("Button",modName..(#qb.items + 1),qb,"SecureActionButtonTemplate");
	b:SetWidth(cfg.btnSize);
	b:SetHeight(cfg.btnSize);
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square");
	b:RegisterForClicks("LeftButtonUp","RightButtonUp");
--	b:SetScript("OnUpdate",Button_OnUpdate);
	b:SetScript("OnEnter",Button_OnEnter);
	b:SetScript("OnLeave",HideGTT);
	b:HookScript("OnClick",Button_OnClick);
	b:SetAttribute("type*","item");

	b.icon = b:CreateTexture(nil,"ARTWORK");
	b.icon:SetAllPoints();

	b.count = b:CreateFontString(nil,"ARTWORK");
	b.count:SetFont(GameFontNormal:GetFont(),14,"OUTLINE");
	b.count:SetTextColor(1,1,1);
	b.count:SetPoint("BOTTOMRIGHT",b.icon,-3,3);

	b.cooldown = CreateFrame("Cooldown",nil,b,"CooldownFrameTemplate");
	b.cooldown:SetAllPoints();

	b.bind = b:CreateFontString(nil,"ARTWORK","NumberFontNormalSmallGray");
	b.bind:SetPoint("TOPLEFT",b.icon,3,-3);
	b.bind:SetPoint("TOPRIGHT",b.icon,-3,-3);
	b.bind:SetJustifyH("RIGHT");

	if (#qb.items == 0) then
		b:SetPoint("TOPLEFT",qb,12,-12);
	end

	qb.items[#qb.items + 1] = b;
	return b;
end

-- Add Button
local function AddButton(index,bag,slot,link,itemId,count)
	local btn = qb.items[index] or CreateItemButton();

	local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(link);
	btn.icon:SetTexture(itemTexture);
	btn.count:SetText(count and count > 1 and count or "");

	btn.link = link;
	btn.itemId = itemId;

	btn:SetAttribute("bag",bag);
	btn:SetAttribute("slot",slot);

	if (index > 1) then
		btn:ClearAllPoints();
		if (cfg.vertical) then
			if (cfg.mirrored) then
				btn:SetPoint("BOTTOM",qb.items[index - 1],"TOP",0,cfg.padding);
			else
				btn:SetPoint("TOP",qb.items[index - 1],"BOTTOM",0,cfg.padding * -1);
			end
		else
			if (cfg.mirrored) then
				btn:SetPoint("RIGHT",qb.items[index - 1],"LEFT",cfg.padding * -1,0);
			else
				btn:SetPoint("LEFT",qb.items[index - 1],"RIGHT",cfg.padding,0);
			end
		end
	end

	btn:Show();
end

-- Check Item -- Az: Some items which starts a quest, are not marked as "Quest" in itemType or itemSubType. Ex: item:17008
local function CheckItemTooltip(link,itemId)
	local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(link);
	-- Include predefinded items
	for _, id in ipairs(qItems) do
		if (itemId == id) then
			return 1;
		end
	end
	-- Scan Tip -- Az: any reason we cant just check for more or equal to 4 lines, or would some quest items fail that check?
	qb.tip:ClearLines();
	qb.tip:SetHyperlink(link);
	local numLines = qb.tip:NumLines();
	local line2 = (_G[modName.."TipTextLeft2"]:GetText() or "");
	if (numLines >= 3) and (itemType == QUEST_TOKEN or itemSubType == QUEST_TOKEN or line2 == ITEM_BIND_QUEST or line2 == GetZoneText()) then
		for i = 3, numLines do
			local text = _G[modName.."TipTextLeft"..i]:GetText() or "";
			if (text:find("^"..ITEM_SPELL_TRIGGER_ONUSE)) then
				return 1;
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                               Update                                               --
--------------------------------------------------------------------------------------------------------

-- Request a Button Update
function qb:RequestUpdate()
	self.updateTime = 0;
	self:SetScript("OnUpdate",OnUpdate);
end

-- Update Buttons
function qb:UpdateButtons()
	-- Check if we are locked by combat
	if (InCombatLockdown()) then
		return;
	end
	-- locals
	local index = 1;
	-- Inventory
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag,slot);
			local itemId = link and tonumber(link:match(ITEMID_PATTERN));
			if (link) and (itemId) and (not cfg.ignoreList[itemId]) then
				local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bag,slot);
				if (questId and not isActive) or (cfg.userList[itemId]) or (CheckItemTooltip(link,itemId)) then
					local _, count = GetContainerItemInfo(bag,slot);
					AddButton(index,bag,slot,link,itemId,count);
					index = (index + 1);
				end
			end
		end
	end
	-- Equipped Items
	for _, slotName in ipairs(slots) do
		local slotId = GetInventorySlotInfo(slotName);
		local link = GetInventoryItemLink("player",slotId);
		local itemId = link and tonumber(link:match(ITEMID_PATTERN));
		if (link) and (itemId) and (not cfg.ignoreList[itemId]) and (cfg.userList[itemId] or CheckItemTooltip(link,itemId)) then
			AddButton(index,nil,slotId,link,itemId);
			index = (index + 1);
		end
	end
	-- Set Shown Items
	self.shownItems = (index - 1);
	for i = index, #self.items do
		self.items[i]:Hide();
	end
	-- Update Misc
	self:UpdateBinding(1);
	self:UpdateCooldowns();
end

-- Update Cooldowns
function qb:UpdateCooldowns()
	for i = 1, self.shownItems do
		local bag, slot = self.items[i]:GetAttribute("bag"), self.items[i]:GetAttribute("slot");
		if (bag) then
			CooldownFrame_Set(self.items[i].cooldown,GetContainerItemCooldown(bag,slot));
		else
			CooldownFrame_Set(self.items[i].cooldown,GetInventoryItemCooldown("player",slot));
		end
	end
end

-- Update Bind Text
function qb:UpdateBinding(reBind)
	for i = 1, self.shownItems do
		if (not InCombatLockdown() and reBind and cfg.bindKey) and (self.shownItems == 1 or cfg.lastItem == self.items[i].itemId) then
			SetBindingClick(cfg.bindKey,modName..i);
		end
		self.items[i].bind:SetText(GetBindingText(GetBindingKey("CLICK "..modName..i..":LeftButton"),"",1));
	end
end

--------------------------------------------------------------------------------------------------------
--                                               Events                                               --
--------------------------------------------------------------------------------------------------------

qb:SetScript("OnEvent",function(self,event,...) if (self[event]) then self[event](self,event,...); else self:RequestUpdate(); end end);
qb:RegisterEvent("ADDON_LOADED");

-- Variables Loaded [One-Time-Event]
function qb:ADDON_LOADED(event,addon)
	if (addon ~= modName) then
		return;
	end

	-- cfg
	if (not QBar_Config) then
		QBar_Config = {};
	end
	cfg = setmetatable(QBar_Config,{ __index = defConfig });
	self.cfg = cfg;
	if (not cfg.ignoreList) then
		cfg.ignoreList = {};
	end
	if (not cfg.userList) then
		cfg.userList = {};
	end

	-- Misc
	self:SetWidth(cfg.btnSize + 24);
	self:SetHeight(cfg.btnSize + 24);
	if (cfg.left and cfg.bottom) then
		self:SetPoint("BOTTOMLEFT",cfg.left,cfg.bottom);
	else
		self:SetPoint("CENTER");
	end
	self.shownItems = 0;
	self:SetEnabledStatus();
	self:SetScale(cfg.scale);

	-- Clear
	self:UnregisterEvent(event);
	self[event] = nil;
end

-- Update Cooldowns
function qb:ACTIONBAR_UPDATE_COOLDOWN(event)
	if (self.shownItems > 0) then
		self:UpdateCooldowns();
	end
end

-- Bindings Update
function qb:UPDATE_BINDINGS(event)
	self:UpdateBinding();
end

-- Inventory Changed
function qb:UNIT_INVENTORY_CHANGED(event,unit)
	if (unit == "player") then
		self:RequestUpdate();
	end
end

--------------------------------------------------------------------------------------------------------
--                                            Command Line                                            --
--------------------------------------------------------------------------------------------------------

_G["SLASH_"..modName.."1"] = "/qb";
_G["SLASH_"..modName.."2"] = "/qbar";
SlashCmdList[modName] = function(cmd)
	-- Extract Parameters
	local param1, param2 = cmd:match("^([^%s]+)%s*(.*)$");
	param1 = (param1 and param1:lower() or cmd:lower());
	-- Enabled
	if (param1 == "toggle") then
		if (InCombatLockdown()) then
			AzMsg("|2"..modName.."|r Cannot toggle in combat");
		else
			cfg.enabled = not cfg.enabled;
			qb:SetEnabledStatus();
			AzMsg("|2"..modName.."|r has now been |1"..(cfg.enabled and "enabled" or "disabled").."|r.");
		end
	-- Scale
	elseif (param1 == "scale") then
		if (param2 ~= "") and (type(tonumber(param2)) == "number") then
			cfg.scale = tonumber(param2);
			qb:SetScale(cfg.scale);
			AzMsg("|2"..modName.."|r Button Scale set to |1"..cfg.scale.."|r.");
		end
	-- Size
	elseif (param1 == "size") then
		if (param2 ~= "") and (type(tonumber(param2)) == "number") then
			cfg.btnSize = tonumber(param2);
			for _, btn in ipairs(qb.items) do
				btn:SetWidth(cfg.btnSize);
				btn:SetHeight(cfg.btnSize);
			end
			qb:SetWidth(cfg.btnSize + 24);
			qb:SetHeight(cfg.btnSize + 24);
			AzMsg("|2"..modName.."|r Button Size set to |1"..cfg.btnSize.."|r.");
		end
	-- Padding
	elseif (param1 == "padding") then
		if (param2 ~= "") and (type(tonumber(param2)) == "number") then
			cfg.padding = tonumber(param2);
			qb:RequestUpdate();
			AzMsg("|2"..modName.."|r Button Padding set to |1"..cfg.padding.."|r.");
		end
	-- Tips
	elseif (param1 == "tips") then
		cfg.showTips = not cfg.showTips;
		AzMsg("|2"..modName.."|r Item tips |1"..(cfg.showTips and "enabled" or "disabled").."|r.");
	-- Vertical
	elseif (param1 == "vertical") then
		cfg.vertical = not cfg.vertical;
		qb:RequestUpdate();
		AzMsg("|2"..modName.."|r Vertical alignment |1"..(cfg.vertical and "enabled" or "disabled").."|r.");
	-- Mirrored
	elseif (param1 == "mirror") then
		cfg.mirrored = not cfg.mirrored;
		qb:RequestUpdate();
		AzMsg("|2"..modName.."|r Mirrored anchor |1"..(cfg.mirrored and "enabled" or "disabled").."|r.");
	-- Lock
	elseif (param1 == "lock") then
		qb:SetLockedStatus(qb:IsMouseEnabled());
		AzMsg("|2"..modName.."|r Button frame is now |1"..(qb:IsMouseEnabled() and "unlocked" or "locked").."|r.");
	-- Reset
	elseif (param1 == "reset") then
		qb:ClearAllPoints();
		qb:SetPoint("CENTER");
		cfg.left, cfg.bottom = qb:GetLeft(), qb:GetBottom();
	-- Bind
	elseif (param1 == "bind") then
		OpenBindingFrame();
	-- Add
	elseif (param1 == "add") then
		if (param2 and param2 ~= "") then
			local itemId = tonumber(param2) or tonumber(param2:match(ITEMID_PATTERN));
			if (type(itemId) == "number") then
				cfg.userList[itemId] = true;
				cfg.ignoreList[itemId] = nil;
				qb:RequestUpdate();
				local _, link = GetItemInfo(itemId);
				if (link) then
					AzMsg("|2"..modName.."|r Added "..link.." to user list.");
				else
					AzMsg("|2"..modName.."|r Invalid Item - Failed to Query Info on Item.");
				end
			else
				AzMsg("|2"..modName.."|r Invalid Input - Not valid link or itemID.");
			end
		else
			AzMsg("|2"..modName.."|r Invalid Input - Use: /qb add <itemlink>");
		end
	-- Clear Ignore
	elseif (param1 == "clearignore") then
		wipe(cfg.ignoreList);
		qb:RequestUpdate();
		AzMsg("|2"..modName.."|r Ignore List Cleared.");
	-- Clear User
	elseif (param1 == "clearuser") then
		wipe(cfg.userList);
		qb:RequestUpdate();
		AzMsg("|2"..modName.."|r User List Cleared.");
	-- Invalid or No Command
	else
		UpdateAddOnMemoryUsage();
		AzMsg(format("----- |2%s|r |1%s|r ----- |1%.2f |2kb|r -----",modName,GetAddOnMetadata(modName,"Version"),GetAddOnMemoryUsage(modName)));
		AzMsg("The following |2parameters|r are valid for this addon:");
		AzMsg(" |2toggle|r = Toggles the mod being on or off");
		AzMsg(" |2scale <value>|r = Sets the scale of the buttons");
		AzMsg(" |2size <value>|r = Sets the unit size of the buttons");
		AzMsg(" |2padding <value>|r = Space padding between the buttons");
		AzMsg(" |2tips|r = Toggles the showing of item tips when you mouse over buttons");
		AzMsg(" |2vertical|r = Sets whether or not the buttons anchor vertical or horizontal");
		AzMsg(" |2mirror|r = Mirror the anchor direction, top/bottom or left/right depending on the vertical setting");
		AzMsg(" |2lock|r = Toggles the button frame being locked, use this command to move the buttons around");
		AzMsg(" |2reset|r = Resets the position of QBar in case it has gotten off screen");
		AzMsg(" |2add <itemlink>|r = Adds a button for the specified item");
		AzMsg(" |2clearignore|r = Show all items again, by clearing the ignore list");
		AzMsg(" |2clearuser|r = Clears the user list from items, added using the add command");
		AzMsg(" |2bind|r = Set a key binding for the last item used");
	end
end