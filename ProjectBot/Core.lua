local addonName, ns = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

local ProjectBot = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceHook-3.0")
local guildName = GetGuildInfo("player")

StaticPopupDialogs["PROJECTBOT_EXPORT"] = {
    text = "String to import in to Discord Bot.",
    button1 = ACCEPT,
    OnAccept = function(self, configID)
    end,
    timeout = 0,
    OnShow = function (self, data)
		self:SetWidth(650)
		self.editBox:SetWidth(500)
		self.editBox:SetText(PROJECTENCODED)
		self.editBox:SetAutoFocus(true)
		self.editBox:SetCursorPosition(0)
		self.editBox:HighlightText()
	end,
    hasEditBox = true,
    whileDead = true,
    hideOnEscape = true,
}

local function requestUpdate()
	local requestSent = openRaidLib.RequestKeystoneDataFromGuild()
	return requestSent
end

SLASH_KEYSCODE1 = "/keyscode"
SLASH_KEYSCODE2 = "/keycode"
SlashCmdList["KEYSCODE"] = function(msg)
	requestUpdate()
	--C_Timer.After(2.5, function() PROJECTENCODED = ProjectBot:Encode(PROJECTDB[guildName]['keystones']) end)
	PROJECTENCODED = ProjectBot:Encode(PROJECTDB[guildName]['keystones'])
	local dialog = StaticPopup_Show("PROJECTBOT_EXPORT")
end 

SLASH_KEYUPDATE1 = "/keyupdate"
SlashCmdList["KEYUPDATE"] = function(msg)
	local requestSent = requestUpdate()
end 

function ProjectBot:OnInitialize()		
	PROJECTDB = PROJECTDB or {}

	if (openRaidLib) then
		openRaidLib.RegisterCallback(ProjectBot, "KeystoneUpdate", "OnKeystoneUpdate")

		local requestSent = requestUpdate()
	end

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(this, event, ...)
        ProjectBot[event](ProjectBot, ...)
    end)
end

function ProjectBot:Encode(data)
	local serialized = LibSerialize:Serialize(data)
	local compressed = LibDeflate:CompressDeflate(serialized)
	local encoded = LibDeflate:EncodeForPrint(compressed)
	return encoded
end

function ProjectBot:OnEnable()
    --initialize Saved Variables and other start up tasks
end

function ProjectBot:OnAddonLoaded(event, addonName)
    -- Check if the addon that was loaded is Details
    --if addonName == "Details" then
	--	local keystoneInfoFrame = _G["DetailsKeystoneInfoFrame"]
	--	keystoneInfoFrame:HookScript("OnShow", function(self)
	--		local dialog = StaticPopup_Show("PROJECTBOT_EXPORT")
	--	end)
    --    myFrame:UnregisterEvent("ADDON_LOADED")
    --end
end

function ProjectBot:OnKeystoneUpdate(unitName, keystoneInfo, allKeystoneInfo)

	local guildUsers = {}
	local realmName = GetRealmName()
	--create a string to use into the gsub call when removing the realm name from the player name, by default all player names returned from GetGuildRosterInfo() has PlayerName-RealmName format
	local realmNameGsub = "%-.*"

	if (guildName) then
			-- This is ripped straight from Details!
		local keystoneData = openRaidLib.GetAllKeystonesInfo()
		
		PROJECTDB[guildName] = PROJECTDB[guildName] or {}

		local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers()

		for i = 1, totalMembers do
			local fullName, rank, rankIndex, level, class, zone, note, officernote, online, isAway, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
			if (fullName) then
				fullName = fullName:gsub(realmNameGsub, "")
				if (online) then
					guildUsers[fullName] = true
				end
			else
				break
			end
		end
		
		if (keystoneData) then
			local unitsAdded = {}
			local isOnline = true
			PROJECTDB[guildName]['keystones'] = PROJECTDB[guildName]['keystones'] or {}
			for unitName, keystoneInfo in pairs(keystoneData) do

				local mapName = C_ChallengeMode.GetMapUIInfo(keystoneInfo.mythicPlusMapID) or ""

				local isInMyParty = UnitInParty(unitName) and (string.byte(unitName, 1) + string.byte(unitName, 2)) or 0
				local isGuildMember = guildName and guildUsers[unitName] and true

				if (keystoneInfo.level > 0 and isGuildMember) then
					local keystoneTable = { }
					keystoneTable.unitName = unitName
					keystoneTable.rating = 	keystoneInfo.rating
					keystoneTable.level =	keystoneInfo.level
					keystoneTable.mapName = mapName
					keystoneTable.date = time()

					PROJECTDB[guildName]['keystones'][unitName] = keystoneTable
				end
			end
		end

		-- Calculate the timestamp for the most recent Tuesday (see previous example)
		local currentWeekday = tonumber(date("%w"))
		local daysSinceTuesday = currentWeekday - 2
		if daysSinceTuesday < 0 then
			daysSinceTuesday = daysSinceTuesday + 7
		end
		local weeklyReset = time() - (86400 * daysSinceTuesday)

		local keysToDelete = {}  -- Store the keys of the items to delete
		local db = PROJECTDB[guildName]['keystones']

		for unitName, keystoneTable in pairs(db) do
			if keystoneTable.date < weeklyReset  then
				table.insert(keysToDelete, unitName)
			end
		end

		for _, key in ipairs(keysToDelete) do
			table.remove(db, key)
		end
	end
end