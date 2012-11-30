
local Thaumaturge = CreateFrame('Frame')

local function Reforge(self, id)
	ReforgeItem(id)
end

local info = {}
function Thaumaturge:initialize()
	table.wipe(info)

	local currentID = GetReforgeItemInfo()
	local sources = {GetSourceReforgeStats()}
	for source = 1, #sources, 3 do
		local sourceName = sources[source]
		local sourceValue = sources[source + 2]

		local destinations = {GetDestinationReforgeStats(sources[source + 1], sourceValue)}
		for destination = 1, #destinations, 4 do
			local destinationName = destinations[destination]
			local destinationValue = destinations[destination + 2]
			local newID = destinations[destination + 3]

			info.text = string.format('|cffff0000-%d %s|r > |cff00ff00+%d %s|r', sourceValue, sourceName, destinationValue, destinationName)
			info.checked = currentID == newID
			info.notCheckable = currentID ~= newID
			info.arg1 = newID
			info.func = Reforge
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

local function ClearReforge()
	CloseDropDownMenus()
	SetReforgeFromCursorItem()
	ClearCursor()
end

local function OnEnterHook(self)
	CloseDropDownMenus()

	local hasItem = GameTooltip:SetInventoryItem('player', self:GetID())
	if(not hasItem) then
		return ClearReforge()
	end

	local name, link, _, level = GetItemInfo(GetInventoryItemLink('player', self:GetID()))
	if(level < 200) then
		return ClearReforge()
	end

	local _, _, currentName = GetReforgeItemInfo()
	if(currentName ~= name) then
		PickupInventoryItem(self:GetID())
		SetReforgeFromCursorItem()

		if(GetReforgeItemInfo()) then
			ToggleDropDownMenu(1, nil, Thaumaturge, self, 40, 40)
		end
	end
end

local origEnter = PaperDollItemSlotButton_OnEnter
local origLeave = UIDropDownMenu_OnHide

local function OnLeaveHook(...)
	origLeave(...)
	ClearReforge()
end

function Thaumaturge:FORGE_MASTER_OPENED()
	if(not PaperDollFrame:IsVisible()) then
		ToggleCharacter('PaperDollFrame')
	end

	SetPortraitToTexture(CharacterFramePortrait, [=[Interface\Reforging\Reforge-Portrait]=])

	PaperDollItemSlotButton_OnEnter = OnEnterHook
	UIDropDownMenu_OnHide = OnLeaveHook
end

function Thaumaturge:FORGE_MASTER_CLOSED()
	CharacterFrame_UpdatePortrait()

	PaperDollItemSlotButton_OnEnter = origEnter
	UIDropDownMenu_OnHide = origLeave
end

function Thaumaturge:PLAYER_LOGIN()
	self:RegisterEvent('FORGE_MASTER_OPENED')
	self:RegisterEvent('FORGE_MASTER_CLOSED')
	self:RegisterEvent('ADDON_LOADED')

	self.displayMode = 'MENU'

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
