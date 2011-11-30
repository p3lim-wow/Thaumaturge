local addonName = ...
local Thaumaturge = CreateFrame('Frame', addonName)

local function PreForge(self, id)
	ReforgeItem(id)
end

local info = {}
local function InitDropdown()
	wipe(info)

	local currentID = GetReforgeItemInfo()
	local sources = {GetSourceReforgeStats()}
	for i = 1, #sources, 3 do
		local srcName = sources[i]
		local srcValue = sources[i + 2]

		local destinations = {GetDestinationReforgeStats(sources[i + 1], srcValue)}
		for j = 1, #destinations, 4 do
			local destName = destinations[j]
			local destValue = destinations[j + 2]
			local id = destinations[j + 3]

			info.text = string.format('|cffff0000-%d %s|r > |cff00ff00+%d %s|r', srcValue, srcName, destValue, destName)
			info.checked = currentID == id
			info.notCheckable = currentID ~= id
			info.arg1 = id
			info.func = PreForge
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info)
		end
	end

	if(currentID ~= 0) then
		info.text = REFORGE_RESTORE
		info.notCheckable = 1
		info.func = ReforgingFrame_RestoreClick
		UIDropDownMenu_AddButton(info)
	end
end

local currentItem
local function ClearAll()
	CloseDropDownMenus()
	SetReforgeFromCursorItem()
	ClearCursor()
	currentItem = nil
end

local reforgable = {
	ITEM_MOD_CRIT_RATING_SHORT = true,
	ITEM_MOD_DODGE_RATING_SHORT = true,
	ITEM_MOD_EXPERTISE_RATING_SHORT = true,
	ITEM_MOD_HASTE_RATING_SHORT = true,
	ITEM_MOD_HIT_RATING_SHORT = true,
	ITEM_MOD_MASTERY_RATING_SHORT = true
}

local currentStats = {}
local function ReforgeHook(self)
	local hasItem = GameTooltip:SetInventoryItem('player', self:GetID())
	if(not hasItem) then
		return ClearAll()
	end

	local name, link, _, level = GetItemInfo(GetInventoryItemLink('player', self:GetID()))
	if(level < 200) then
		return ClearAll()
	end

	local _, _, reforging = GetReforgeItemInfo()
	if(name == reforging or link == currentItem) then return end

	wipe(currentStats)
	GetItemStats(link, currentStats)

	for stat, value in pairs(currentStats) do
		if(reforgable[stat] and value > 0) then
			PickupInventoryItem(self:GetID())
			SetReforgeFromCursorItem()

			currentItem = link
			return ToggleDropDownMenu(1, nil, Thaumaturge, self, 40, 40)
		end
	end

	ClearAll()
end

local origSize
local origEnter = PaperDollItemSlotButton_OnEnter
local origLeave = UIDropDownMenu_OnHide
function Thaumaturge:FORGE_MASTER_OPENED()
	if(not PaperDollFrame:IsVisible()) then
		ToggleCharacter('PaperDollFrame')
	end

	PaperDollItemSlotButton_OnEnter = ReforgeHook
	UIDropDownMenu_OnHide = function(...)
		origLeave(...)
		ClearAll()
	end

	self:RegisterEvent('FORGE_MASTER_ITEM_CHANGED')
end

function Thaumaturge:FORGE_MASTER_ITEM_CHANGED()
	ClearAll()
end

function Thaumaturge:FORGE_MASTER_CLOSED()
	PaperDollItemSlotButton_OnEnter = origEnter
	UIDropDownMenu_OnHide = origLeave
end

function Thaumaturge:PLAYER_LOGIN()
	self:RegisterEvent('FORGE_MASTER_OPENED')
	self:RegisterEvent('FORGE_MASTER_CLOSED')
	self:RegisterEvent('ADDON_LOADED')

	self.displayMode = 'MENU'
	self.initialize = InitDropdown

	PaperDollFrame:HookScript('OnHide', function()
		if(ReforgingFrame and ReforgingFrame:IsShown()) then
			CloseReforge()
		end
	end)
end

function Thaumaturge:ADDON_LOADED(addon)
	if(addon == 'Blizzard_ReforgingUI') then
		UIPanelWindows.ReforgingFrame = nil
	end
end

Thaumaturge:RegisterEvent('PLAYER_LOGIN')
Thaumaturge:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)
