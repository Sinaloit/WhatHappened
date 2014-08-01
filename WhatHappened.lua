-----------------------------------------------------------------------------------------------
-- Client Lua Script for WTF
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ChatSystemLib"
require "ICCommLib"
require "GroupLib"

-----------------------------------------------------------------------------------------------
-- Upvalues
-----------------------------------------------------------------------------------------------
local MAJOR, MINOR = "WhatHappened-1.0", 1

local error, floor, ipairs, pairs, tostring = error, math.floor, ipairs, pairs, tostring
local strformat = string.format

-- Wildstar APIs
local Apollo, ApolloColor, ApolloTimer, ICCommLib = Apollo, ApolloColor, ApolloTimer, ICCommLib
local GameLib, XmlDoc = GameLib, XmlDoc
local Event_FireGenericEvent, Print = Event_FireGenericEvent, Print
 
-----------------------------------------------------------------------------------------------
-- WTF Module Definition
-----------------------------------------------------------------------------------------------
local WhatHappened = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("WhatHappened", false, {"ChatLog"})

-----------------------------------------------------------------------------------------------
-- Locals
-----------------------------------------------------------------------------------------------
-- Packages/Addons
local GeminiColor, tChatLog
local strChatAddon = "ChatLog"

-- Array to contain death logs
local tDeathInfos = {}
-- Queue for keeping track of Combat events
local tCombatQueue

-- Array of colors, populated through saved variables
local tColors = {
    crWhite = ApolloColor.new("white")
}

-- ApolloTimer handle
local atChatTimer
-- Local function, declared later
local GenerateLog

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local ktDamageTypeToName = {
    [GameLib.CodeEnumDamageType.Fall]      = Apollo.GetString("DamageType_Fall"),
    [GameLib.CodeEnumDamageType.Magic]     = Apollo.GetString("DamageType_Magic"),
    [GameLib.CodeEnumDamageType.Physical]  = Apollo.GetString("DamageType_Physical"),
    [GameLib.CodeEnumDamageType.Suffocate] = Apollo.GetString("DamageType_Suffocate"),
    [GameLib.CodeEnumDamageType.Tech]      = Apollo.GetString("DamageType_Tech"),
}

local tDBDefaults = {
    profile = {
        strFontName  = "Nameplates",
        nNumMessages = 20,
        bAttach      = true,
        bRaidLeader  = false,
        ICChannel    = "testing",
        color = {
            Attacker = "ffffffff",
            Damage   = "ffffffff",
            Ability  = "ffffffff",
        }
    }
}

-----------------------------------------------------------------------------------------------
-- Standard Queue
-----------------------------------------------------------------------------------------------
local Queue = {}
function Queue.new()
    return {first = 0, last = -1}
end

function Queue.PushLeft(queue, value)
    local first = queue.first - 1
    queue.first = first
    queue[first] = value
end

function Queue.PushRight(queue, value)
    local last = queue.last + 1
    queue.last = last
    queue[last] = value
end

function Queue.PopLeft(queue)
    local first = queue.first
    if first > queue.last then error("queue is empty") end
    local value = queue[first]
    queue[first] = nil        -- to allow garbage collection
    queue.first = first + 1
    return value
end

function Queue.PopRight(queue)
    local last = queue.last
    if queue.first > last then error("queue is empty") end
    local value = queue[last]
    queue[last] = nil         -- to allow garbage collection
    queue.last = last - 1
    return value
end

function Queue.Size(queue)
    return queue.last - queue.first + 1
end

-----------------------------------------------------------------------------------------------
-- Startup
-----------------------------------------------------------------------------------------------
function WhatHappened:OnInitialize()
    self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, tDBDefaults, true)
    GeminiColor = Apollo.GetPackage("GeminiColor").tPackage

    -- Slash commands
    Apollo.RegisterSlashCommand("wh", "OnWhatHappenedOn", self)
    Apollo.RegisterSlashCommand("wtf", "OnWhatHappenedOn", self)

    --Combat Event Handlers
    Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
    Apollo.RegisterEventHandler("CombatLogDeath", "OnDeath", self)
    Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)

    -- Configuration Event Handlers
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
    Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)

    -- Load XML
    self.xml = XmlDoc.CreateFromFile("WhatHappened.xml")
end

function WhatHappened:OnEnable()

    tCombatQueue = Queue.new()
    self.wndWhat = Apollo.LoadForm(self.xml, "WhatWindow", nil, self)

    -- Colors Setup
    local wndColorList = self.wndWhat:FindChild("OptionsSubForm:ColorsList")
    for strColorName, strColorHex in pairs(self.db.profile.color) do
        tColors["cr" .. strColorName] = ApolloColor.new(strColorHex)
        local wndColor = Apollo.LoadForm(self.xml, "ColorItem", wndColorList, self)
        wndColor:SetText(strColorName)
        wndColor:FindChild("ColorSwatch"):SetBGColor(strColorHex)
    end
    wndColorList:ArrangeChildrenVert(0)

    -- Setup ICComm
    if self.db.profile.ICChannel and self.db.profile.ICChannel ~= "" then
        self.ICCommChannel = ICCommLib.JoinChannel(self.db.profile.ICChannel, "OnMsgRecieved", self)
    end
    self.wndWhat:FindChild("OptionsSubForm:ChannelSettings:ChannelInput"):SetText(self.db.profile.ICChannel or "")
    self.wndWhat:FindChild("OptionsSubForm:ChannelSettings:LeaderBtn"):SetCheck(self.db.profile.bRaidLeader)

    -- Set Current NumMessages
    self.wndWhat:FindChild("OptionsSubForm:CombatHistory:HistoryCount"):SetText(self.db.profile.nNumMessages)
    self.wndWhat:FindChild("OptionsSubForm:CombatHistory:SliderContainer:SliderBar"):SetValue(self.db.profile.nNumMessages)

    -- Pre populate WhoSelection
    local strName = GameLib.GetPlayerUnit():GetName()
    self:AddDeathInfo(strName)
    self.wndWhat:FindChild("WhoButton:WhoText"):SetText(strName)

    -- Get reference to ChatLog addon, or its replacement
    tChatLog = Apollo.GetAddon(strChatAddon)
end

function WhatHappened:OnDependencyError(strDep, strError)
    if strDep == "ChatLog" then
        local tReplaced = Apollo.GetReplacement(strDep)
        for nIdx, strReplacementName in ipairs(tReplaced) do
            if Apollo.GetAddonInfo(strReplacementName).bRunning == 1 then
                strChatAddon = strReplacementName
                return true
            end
        end
    end
    return false
end

-----------------------------------------------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------------------------------------------
-- Define general functions here
function WhatHappened:OnWhatHappenedOn(strCommand, strParam)
    if strParam == "reset" then
        self.db:ResetProfile()
        return
    end
end

-----------------------------------------------------------------------------------------------
-- Event Handlers and Timers
-----------------------------------------------------------------------------------------------

function WhatHappened:OnInterfaceMenuListHasLoaded()
    Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "WhatHappened", {"OnWhatHappenedOn", "", "Crafting_CircuitSprites:sprCircuit_HandStopIcon"})
end

function WhatHappened:OnWindowManagementReady()
    -- ChatLog does all its setup when it hears this event.. so we need to wait a little bit for that to finish
    if self.db.profile.bAttach then
        atChatTimer = ApolloTimer.Create(0.1, false, "OnChatTimer", self)
    end
end

function WhatHappened:OnChatTimer()
    if tChatLog and tChatLog.tChatWindows then
        tChatLog.tChatWindows[1]:AttachTab(self.wndWhat)
    end
end

function WhatHappened:OnCombatLogDamage(tEventArgs)
    local unitMe = GameLib.GetPlayerUnit()
    -- Self inflicted damage doesn't count!
    if tEventArgs.unitCaster == unitMe then return end
    -- We're only tracking damage to ourselves
    if tEventArgs.unitTarget ~= unitMe then return end
    -- We don't care about extra damage when we're dead either
    if unitMe:IsDead() then return end

    tEventArgs.strCasterName = tEventArgs.unitCaster:GetName()
    tEventArgs.unitCaster = nil

    Queue.PushRight(tCombatQueue, tEventArgs)
    if Queue.Size(tCombatQueue) > self.db.profile.nNumMessages then
        Queue.PopLeft(tCombatQueue)
    end
end

function WhatHappened:OnDeath()
    local tMessage = {}
    local strName = GameLib.GetPlayerUnit():GetName()
    tDeathInfos[strName] = {}
    local tDeathInfo = tDeathInfos[strName]
    while Queue.Size(tCombatQueue) > 0 do
        local tEventArgs = Queue.PopLeft(tCombatQueue)
        tDeathInfo[#tDeathInfo + 1] = tEventArgs

        if self.ICCommChannel then
            tMessage[#tMessage + 1] = tEventArgs
        end
    end
    self.wndWhat:FindChild("WhoButton:WhoText"):SetText(strName)
    GenerateLog(self, strName)
    if self.ICCommChannel then
        tMessage._MAJOR = MAJOR
        tMessage._MINOR = MINOR
        self.ICCommChannel:SendMessage(tMessage)
    end
end

function WhatHappened:OnEnteredCombat(unitId, bInCombat)
    if bInCombat or unitId ~= GameLib.GetPlayerUnit() then return end
    -- We left combat, clear out the queue
    tCombatQueue = Queue.new()
end

---------------------------------------------------------------------------------------------------
-- Who Functions
---------------------------------------------------------------------------------------------------
function WhatHappened:AddDeathInfo(strName)
    -- Clear out info if already existant
    if tDeathInfos[strName] then
        tDeathInfos[strName] = {}
        return tDeathInfos[strName]
    end

    tDeathInfos[strName] = {}
    local wndWhoList = self.wndWhat:FindChild("PlayerWindow:PlayerMenuContent")
    local wndWhoEntry = Apollo.LoadForm(self.xml, "WhoEntry", wndWhoList, self)
    wndWhoEntry:FindChild("NameText"):SetText(strName)
    wndWhoEntry:SetData(strName)
    wndWhoList:ArrangeChildrenVert(0)

    return tDeathInfos[strName]
end

function WhatHappened:OnWhoSelect(wndHandler, wndControl, eMouseButton)
    local wndParent = wndControl:GetParent()
    local wndMenu = wndParent:FindChild("PlayerWindow")

    if wndHandler:IsChecked() then
        wndMenu:Invoke()
    else
        wndMenu:Close()
    end
end

function WhatHappened:OnWhoEntryClick(wndHandler, wndControl, eMouseButton)
    local strName = wndControl:GetData()
    self.wndWhat:FindChild("WhoButton:WhoText"):SetText(strName)
    GenerateLog(self, strName)
    self.wndWhat:FindChild("WhoButton"):SetCheck(false)
    wndControl:GetParent():GetParent():Close() -- Ancestor Chain: Btn->PlayerMenuContent->PlayerWindow
end

---------------------------------------------------------------------------------------------------
-- Log Display
---------------------------------------------------------------------------------------------------
function GenerateLog(self, strName)
    local tDeathInfo = tDeathInfos[strName]
    if not tDeathInfo then return end

    local wndWhatLog = self.wndWhat:FindChild("WhatLog")
    wndWhatLog:DestroyChildren()

    for nIdx, tEventArgs in ipairs(tDeathInfo) do
        local wndWhatLine = Apollo.LoadForm(self.xml, "WhatLine", wndWhatLog, self)
        local xml = XmlDoc.new()
        if tEventArgs.unitCaster == nil then
            return end
        xml:AddLine(tEventArgs.strCasterName, tColors.crAttacker, self.db.profile.strFontName, "Left")
        xml:AppendText(": ", tColors.crWhite, self.db.profile.strFontName, "Left")
        xml:AppendText(tEventArgs.splCallingSpell:GetName(), tColors.crAbility, self.db.profile.strFontName, "Left")
        xml:AppendText(" for ", tColors.crWhite, self.db.profile.strFontName, "Left")
        xml:AppendText(tEventArgs.nDamageAmount .. " " .. ktDamageTypeToName[tEventArgs.eDamageType] or "Unknown", tColors.crDamage, self.db.profile.strFontName, "Left")
        xml:AppendText(" Damage", tColors.crWhite, self.db.profile.strFontName, "Left")
        if tEventArgs.nOverkill > 0 then
            xml:AppendText(", Overkill: ", tColors.crWhite, self.db.profile.strFontName, "Left")
            xml:AppendText(tostring(tEventArgs.nOverkill), tColors.crDamage, self.db.profile.strFontName, "Left")
        end
        wndWhatLine:SetDoc(xml)
        wndWhatLine:SetHeightToContentHeight()
    end
    wndWhatLog:ArrangeChildrenVert(0)
end

---------------------------------------------------------------------------------------------------
-- ICCommLib Functions
---------------------------------------------------------------------------------------------------
function WhatHappened:OnMsgRecieved(channel, tMsg, strSender)
    if not self.bRaidLeader then return end
    if tMsg._MAJOR ~= MAJOR then
        -- Major version changes are non-compatible
        error(strformat("Incompatible version from: %s, [%s:%s]", strSender, tMsg._MAJOR, tMsg._MINOR))
    elseif tMsg._MINOR ~= MINOR then
        -- No other versions right now, but any translations needed would go here
    end

    local tDeathInfo = self:AddDeathInfo(strSender)

    for nIdx, tEventArgs in ipairs(tMsg) do
        tDeathInfo[#tDeathInfo + 1] = tEventArgs
    end
end

---------------------------------------------------------------------------------------------------
-- WhatWindow Options Functions
---------------------------------------------------------------------------------------------------
function WhatHappened:OnOptionsToggle(wndHandler, wndControl, eMouseButton)
    self.wndWhat:FindChild("OptionsSubForm"):Show(wndControl:IsChecked())
end

function WhatHappened:OnLeaderToggle(wndHandler, wndControl, eMouseButton)
    self.db.profile.bRaidLeader = wndControl:IsChecked()
end

function WhatHappened:OnChannelChange(wndHandler, wndControl, strText)
    if not strText or strText == "" then
        self.db.profile.ICChannel = ""
        self.ICCommChannel = nil
        return
    end

    -- If we se it to the same, don't do anything
    if self.db.profile.ICChannel == strText then return end

    self.db.profile.ICChannel = strText
    self.ICCommChannel = ICCommLib.JoinChannel(strText, "OnMsgRecieved", self)
end

function WhatHappened:OnHistorySliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
    local wndCount = self.wndWhat:FindChild("OptionsSubForm:CombatHistory:HistoryCount")
    local nNewVal = floor(fNewValue)
    wndCount:SetText(nNewVal)
    self.db.profile.nNumMessages = nNewVal
end

function WhatHappened:OnColorUpdate(strColor, wndControl)
    wndControl:FindChild("ColorSwatch"):SetBGColor(strColor)
    local strColorName = wndControl:GetText()
    self.db.profile.color[strColorName] = strColor
    tColors["cr" .. strColorName] = ApolloColor.new(strColor)
end

function WhatHappened:OnColorItemClick(wndHandler, wndControl, eMouseButton)
    local tColorOpts = {
        callback = "OnColorUpdate",
        bCustomColor = true,
        bAlpha = false,
        strInitialColor = self.db.profile.color[wndControl:GetText()]
    }
    GeminiColor:ShowColorPicker(self, tColorOpts, wndControl)
end