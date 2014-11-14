
local Accomplishment = CreateFrame("Frame", "AccomplishmentFrame", UIParent)

local playerLanguage = GetDefaultLanguage("player")
local playerName = UnitName("player")
local registry = {}
local db, numShown
local timer = false


Accomplishment:Hide()
Accomplishment:SetWidth(180)
Accomplishment:SetHeight(260)
Accomplishment:SetPoint("CENTER", UIParent, "CENTER")
Accomplishment:EnableMouse()
Accomplishment:SetMovable(true)
Accomplishment:SetFrameStrata("FULLSCREEN_DIALOG")
Accomplishment:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
Accomplishment:SetBackdropColor(0, 0, 0, 1)
Accomplishment:SetToplevel(true)
Accomplishment:SetScript("OnDragStart", function(self) self:StartMoving() end)
Accomplishment:SetScript("OnMouseDown", function(self) self:StartMoving() end)
Accomplishment:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() self:SetUserPlaced(true) end)
Accomplishment:RegisterForDrag("LeftButton")

local BG = Accomplishment:CreateTexture(nil, "OVERLAY")
BG:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
BG:SetPoint("CENTER", Accomplishment, "TOP", 0, -20)
BG:SetWidth(275)
BG:SetHeight(70)

local Title = Accomplishment:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("CENTER", Accomplishment, "TOP", 0, -7)
Title:SetText("Accomplishment")


local function close()
	for key in pairs(registry) do registry[key] = nil end
	for i=1, 20 do _G["AccomplishmentButton"..i]:Hide() end

	Accomplishment:Hide()
end


local CB = CreateFrame("Button", nil, Accomplishment, "UIPanelButtonTemplate")
CB:SetPoint("BOTTOMLEFT", Accomplishment, "BOTTOM", 0, 12)
CB:SetHeight(20)
CB:SetWidth(70)
CB:SetText("Close")
CB:SetScript("OnClick", close)

local AB = CreateFrame("Button", nil, Accomplishment, "UIPanelButtonTemplate")
AB:SetPoint("BOTTOMRIGHT", Accomplishment, "BOTTOM", 0, 12)
AB:SetHeight(20)
AB:SetWidth(70)
AB:SetText("All")
AB:SetScript("OnClick", function()
	Accomplishment:Throttle()
	close()
end)


local function updateDisplay()
	for i=1, 20 do _G["AccomplishmentButton"..i]:Hide() end

	local i = 0
	for name, channel in pairs(registry) do
		i = i +1

		local butt = _G["AccomplishmentButton"..i]

		butt.type = channel or "SAY"
		butt.text:SetText(name)
		butt:Show()

		if i == db.numToShow then break end -- bail out if we've used all the available buttons
	end

	numShown = i

	if numShown >= 1 then
		if numShown > 1 then AB:Enable()
		else AB:Disable() end

		Accomplishment:SetHeight((20*numShown) +60)
		Accomplishment:Show()
	else
		Accomplishment:Hide()
	end
end

local function buttOnClick(self, button)
	local name = self.text:GetText()

	if button == "LeftButton" then
		Accomplishment:Congratulate(name, self.type)
	else
		registry[name] = nil
	end

	self.type = nil
	self:Hide()

	updateDisplay()
end

local function OnEvent(self, event, _, name)
	name = Ambiguate(name, "none")
	if name == playerName then return end -- we don't want to congratulate ourselves

	local channel
	if db.whisper then channel = "WHISPER"
	else
		if event:find("_GUILD_") then channel = "GUILD" else channel = "SAY" end
	end

	registry[name] = channel

	if db.autoGrats then
		Accomplishment:Congratulate(name, channel, true)
		return
	end

	updateDisplay()
end


function Accomplishment:OnEnable()
	self:UnregisterEvent("PLAYER_LOGIN")

	db = LibStub("AceDB-3.0"):New("AccomplishmentDB", {
		profile = {
			guildieGrats = true, strangerGrats = false, whisper = false,
			autoGrats = false, message = "Congratulations %s!", numToShow = 5
		}
	}, "Default").profile

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Accomplishment", {
		name = "Accomplishment",
		desc = "Allows for easy congratulations for when someone earns an Achievement.",
		type = "group",
		get = function(key) return db[key.arg] end,
		set = function(key, value) db[key.arg] = value end,
		args = {
			guildieGrats = {
				name = "Congratulate Guildies",
				desc = "Congratulate members of your guild when they earn Achievements.",
				type = "toggle", order = 1, arg = "guildieGrats",
				set = function(_, value)
					db.guildieGrats = value

					if value then self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
					else self:UnregisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT") end
				end,
			},
			strangerGrats = {
				name = "Congratulate Strangers",
				desc = "Congratulate the random players around you when they earn Achievements.",
				type = "toggle", order = 2, arg = "strangerGrats",
				set = function(_, value)
					db.strangerGrats = value

					if value then self:RegisterEvent("CHAT_MSG_ACHIEVEMENT")
					else self:UnregisterEvent("CHAT_MSG_ACHIEVEMENT") end
				end,
			},
			whisper = {
				name = "Whisper User",
				desc = "Send a congratulatory whisper to the user. Will use /say or /guild if disabled.",
				type = "toggle", order = 3, arg = "whisper",
			},
			autoGrats = {
				name = "Automatically Congratulate",
				desc = "Automatically congratulate those who earn Achievements instead of clicking on a button.",
				type = "toggle", order = 4, arg = "autoGrats",
			},
			numToShow = {
				name = "Number of People",
				desc = "Choose the maximum number of people to display in the window. This will take effect the next time the window opens.",
				type = "range", order = 5, arg = "numToShow",
				min = 1, max = 20, step = 1,
			},
			message = {
				name = "Congratulatory Message",
				desc = "Choose what to say to the user. Use '%s' where you want the user's name to be.",
				type = "input", width = "full", order = 6, arg = "message",
			},
		},
	})

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Accomplishment", "Accomplishment")

	for i=1, 20 do
		local butt = CreateFrame("Button", "AccomplishmentButton"..i, self) -- I'm a mature adult, honest!
		butt:Hide()
		butt:SetWidth(150)
		butt:SetHeight(20)
		butt:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		butt:SetPoint("TOP", self, "TOP", 0, (-20*i) -5)
		butt:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		butt:SetScript("OnClick", buttOnClick)

		local text = butt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		butt.text = text
		text:SetPoint("CENTER", butt, "CENTER")
	end

	if db.guildieGrats then self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT") end
	if db.strangerGrats then self:RegisterEvent("CHAT_MSG_ACHIEVEMENT") end

	self:SetScript("OnEvent", OnEvent)
end


-- /script Accomplishment:Congratulate("Syl", "SAY")
-- /script Accomplishment:Congratulate("Syl", "SAY") Accomplishment:Congratulate("Syl2", "SAY")
-- /script Accomplishment:Congratulate("Syl", "SAY") Accomplishment:Congratulate("Syl2", "SAY") Accomplishment:Congratulate("Syl3", "SAY")
function Accomplishment:Congratulate(name, channel, auto)
	if auto then
		if not timer then
			C_Timer.After(3, Accomplishment.Throttle)
			timer = true
		end
	else
		local message = db.message:format(name)

		if channel == "WHISPER" then
			SendChatMessage(message, channel, playerLanguage, name)
		else
			SendChatMessage(message, channel)
		end

		registry[name] = nil
		updateDisplay()
	end
end

local channels = {}
function Accomplishment:Throttle()
	timer = false
	wipe(channels)

	for k, v in pairs(registry) do
		channels[v] = channels[v] or {}

		local c = channels[v]
		c[#c+1] = k
	end

	local channel, names = next(channels)
	if not channel then return end

	channels[channel] = nil

	if #names > db.numToShow then
		local message = db.message:format("guys")

		if channel ~= "WHISPER" then
			SendChatMessage(message, channel)
		end
	elseif #names > 1 and #names <= db.numToShow then
		SendChatMessage(db.message:format(table.concat(names, ", ")), channel)
	else
		for _, name in pairs(names) do
			local message = db.message:format(name)

			if channel == "WHISPER" then
				SendChatMessage(message, channel, playerLanguage, name)
			else
				SendChatMessage(message, channel)
			end
		end
	end

	for _, v in pairs(names) do registry[v] = nil end

	if next(channels) then
		C_Timer.After(3, Accomplishment.Throttle)
		timer = true
	end
end


Accomplishment:RegisterEvent("PLAYER_LOGIN")
Accomplishment:SetScript("OnEvent", Accomplishment.OnEnable)
