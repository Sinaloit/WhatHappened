--
-- Created by IntelliJ IDEA.
-- User: Gaming
-- Date: 7/26/2014
-- Time: 9:20 PM
-- To change this template use File | Settings | File Templates.
--


require "Window"
require "ICCommLib"
require "GroupLib"

local WhatHappened = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("WhatHappened", false)
local GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage

local tCombatHistory = {first = 0, last = -1}
local PushCount = 0
local Push, Pop
--Windows
local wndMain
local wndConfig
local wndRaidLeader
local wndMainInst
local wndConfigInst
local wndRaidLeaderInst
local wndPlayerNameClickable

local tWhatHappenedFormDef = {
    AnchorOffsets = { 73, 221, 688, 470 },
    RelativeToClient = true,
    Font = "CRB_Interface14_O",
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Template = "Holo_Background_General",
    Name = "WhatHappenedForm",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Moveable = true,
    Escapable = true,
    UseTemplateBG = true,
    NoClip = true,
    Children = {
        {
            AnchorOffsets = { 516, 200, 585, 224 },
            Class = "Button",
            Base = "CRB_UIKitSprites:btn_square_LARGE_Red",
            Font = "DefaultButton",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "btnClose",
            TextId = "CRB_Close",
            Events = {
                ButtonSignal = "OnClose",
            },
        },
        {
            AnchorOffsets = { 0, 24, 490, 235 },
            Class = "MLWindow",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "Holo_ScrollList",
            Name = "CombatText",
            Border = true,
            VScroll = true,
            UseTemplateBG = true,
            UseParentOpacity = true,
        },
        {
            AnchorOffsets = { -10, -9, 498, 26 },
            Class = "EditBox",
            RelativeToClient = true,
            Font = "CRB_Interface14_BBO",
            Text = "WTF Happened!!",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Title",
            DT_VCENTER = true,
            DT_CENTER = true,
            ReadOnly = true,
            SizeToFit = false,
            Password = false,
            IgnoreMouse = true,
        },
        {
            AnchorOffsets = { 519, 39, 585, 56 },
            Class = "Button",
            Base = "CRB_Basekit:kitBtn_ScrollHolo_HorzBarLarge",
            Font = "CRB_Interface9_BBO",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "btnConfig",
            Template = "Tooltip",
            Text = "Config",
            UseTemplateBG = true,
            Picture = true,
            Events = {
                ButtonSignal = "OnConfig",
            },
        },
    },
}
local tConfigFormDef = {
    AnchorOffsets = { 264, 111, 522, 331 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Template = "Holo_Background_General",
    Name = "ConfigForm",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Moveable = true,
    Escapable = true,
    Overlapped = true,
    UseTemplateBG = true,
    Children = {
        {
            AnchorOffsets = { -8, -1, 248, 23 },
            RelativeToClient = true,
            Font = "CRB_Interface12_BBO",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Window",
            TextId = "CRB_Configure",
            DT_CENTER = true,
            DT_VCENTER = true,
        },
        {
            AnchorOffsets = { 5, 33, 82, 50 },
            Class = "EditBox",
            RelativeToClient = true,
            Text = "Raid Channel",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "EditBox",
            ReadOnly = true,
            SizeToFit = true,
        },
        {
            AnchorOffsets = { 78, 26, 223, 55 },
            Class = "EditBox",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "GreyBevInnerFrame",
            Name = "RaidChannel",
            Border = true,
            UseTemplateBG = true,
            DefaultTarget = false,
            DT_CENTER = true,
            DT_VCENTER = true,
        },
        {
            AnchorOffsets = { 61, 153, 182, 194 },
            Class = "Button",
            Base = "BK3:btnHolo_Blue_Small",
            Font = "DefaultButton",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "btnSave",
            TextId = "CRB_Save",
            Border = true,
            UseWindowTextColor = false,
            UseTemplateBG = true,
            Picture = true,
            RelativeToClient = true,
            Events = {
                ButtonSignal = "OnConfigSave",
            },
        },
        {
            AnchorOffsets = { 52, 101, 212, 130 },
            Class = "Button",
            Base = "CRB_Basekit:kitBtn_Radio_Small",
            Font = "DefaultButton",
            ButtonType = "Check",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "chkRaidLeader",
            DrawAsCheckbox = true,
            Template = "CRB_Default",
            UseWindowTextColor = true,
            Text = "Raid Leader Mode",
            UseTemplateBG = true,
            GlobalRadioGroup = "",
        },
        {
            AnchorOffsets = { 2, 58, 234, 102 },
            RelativeToClient = true,
            Text = "Raid Leader Mode - You will recieve reports from others in the same channel.",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Window1",
            DT_CENTER = true,
            DT_WORDBREAK = true,
        },
        {
            AnchorOffsets = { 52, 133, 192, 162 },
            Class = "Button",
            Base = "CRB_Basekit:kitBtn_Radio_Small",
            Font = "DefaultButton",
            ButtonType = "Check",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "chkShowOnDeath",
            DrawAsCheckbox = true,
            Template = "CRB_Default",
            UseWindowTextColor = true,
            Text = "Show On Death",
            UseTemplateBG = true,
            GlobalRadioGroup = "",
        },
    },
}
local tRaidLeaderFormDef = {
    AnchorOffsets = { 93, 90, 685, 337 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Template = "Holo_Background_Datachron",
    Name = "RaidLeaderForm",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Moveable = true,
    Overlapped = true,
    Children = {
        {
            AnchorOffsets = { 10, 35, 154, 234 },
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "CRB_HologramFramedThin",
            Name = "RecipientList",
            Border = true,
            IgnoreMouse = true,
            UseTemplateBG = true,
        },
        {
            AnchorOffsets = { 10, 10, 152, 32 },
            RelativeToClient = true,
            Font = "CRB_Interface11_BBO",
            Text = "Recipient List",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "lblRecipientList",
            DT_CENTER = true,
            DT_VCENTER = true,
        },
        {
            AnchorOffsets = { 158, 35, 511, 235 },
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "CRB_HologramFramedThin",
            Name = "PlayerCombatText",
            Border = true,
            IgnoreMouse = true,
            Picture = true,
            UseTemplateBG = true,
        },
        {
            AnchorOffsets = { 176, 10, 503, 36 },
            RelativeToClient = true,
            Font = "CRB_Interface11_BBO",
            Text = "WTF, Where you thinking??",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "lblWtf",
            DT_CENTER = true,
            DT_VCENTER = true,
        },
        {
            AnchorOffsets = { 519, 39, 585, 56 },
            Class = "Button",
            Base = "CRB_Basekit:kitBtn_ScrollHolo_HorzBarLarge",
            Font = "CRB_Interface9_BBO",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "btnConfig",
            Template = "Tooltip",
            Text = "Config",
            UseTemplateBG = true,
            Picture = true,
            Events = {
                ButtonSignal = "OnConfig",
            },
        },
        {
            AnchorOffsets = { 516, 200, 585, 224 },
            Class = "Button",
            Base = "CRB_UIKitSprites:btn_square_LARGE_Red",
            Font = "DefaultButton",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "btnClose",
            TextId = "CRB_Close",
            Events = {
                ButtonSignal = "OnClose",
            },
        },
    },
}
local tPlayerNameClickable ={
    AnchorOffsets = { 3, 2, 123, 25 },
    RelativeToClient = true,
    Font = "CRB_Interface10_BBO",
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "PlayerNameClickable",
    TextId = "CRB_Player_Name",
    DT_CENTER = true,
    DT_VCENTER = true,
    Events = {
        MouseButtonUp = "OnClickGetReport",
    },

}

function WhatHappened:OnInitialize()

    self.SavedData = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self,  self.defaults, true)

    wndMain                 = GeminiGUI:Create(tWhatHappenedFormDef)
    wndConfig               = GeminiGUI:Create(tConfigFormDef)
    wndRaidLeader           = GeminiGUI:Create(tRaidLeaderFormDef)
    wndPlayerNameClickable  = GeminiGUI:Create(tPlayerNameClickable)


    Apollo.RegisterSlashCommand("wh", "OnWhatHappenedOn", self)
    Apollo.RegisterSlashCommand("wtf", "OnWhatHappenedOn", self)

    --Event Handlers
    Apollo.RegisterEventHandler("CombatLogDamage", "FilterByID", self)
    Apollo.RegisterEventHandler("CombatLogDeath", "OnDeath", self)
    Apollo.RegisterEventHandler("Group_Join", "OnGroupJoin", self)
    Apollo.RegisterEventHandler("Group_Left", "OnGroupLeft", self)
    Apollo.RegisterEventHandler("Group_Disbanded", "OnGroupLeft", self)
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
end

function WhatHappened:OnEnable()
    if self.SavedData.profile.ICChannel then
        self.ICCommChannel = ICCommLib.JoinChannel(self.SavedData.profile.ICChannel, "OnMsgRecieved", self)
        Print("Joined Raid Channel " .. self.SavedData.profile.ICChannel)
    end
end

function WhatHappened:OnInterfaceMenuListHasLoaded()
    --Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "WhatHappened", {"OnWhatHappenedOn", "WhatHappened", "Crafting_CircuitSprites:sprCircuit_HandStopIcon"})
end

function WhatHappened:OnWhatHappenedOn()
    if self.SavedData.profile.RaidLeaderMode == true then
        wndRaidLeaderInst = wndRaidLeader:GetInstance(self)
    else
        wndMainInst = wndMain:GetInstance(self)
    end
end

function WhatHappened:FilterByID(tEventArgs)
    Event_FireGenericEvent("SendVarToRover", "tEventArgs", tEventArgs, 0)
    local PlayerId = GameLib.GetPlayerUnit():GetId()
    self.tTypeMapping =
    {
        [GameLib.CodeEnumDamageType.Physical] 	= Apollo.GetString("DamageType_Physical"),
        [GameLib.CodeEnumDamageType.Magic] 		= Apollo.GetString("DamageType_Magic"),
        [GameLib.CodeEnumDamageType.Fall] 		= Apollo.GetString("DamageType_Fall"),
        [GameLib.CodeEnumDamageType.Suffocate] 	= Apollo.GetString("DamageType_Suffocate"),
        ["Unknown"] 							= Apollo.GetString("CombatLog_SpellUnknown"),
        ["UnknownDamageType"] 					= Apollo.GetString("CombatLog_SpellUnknown"),
    }

    if tEventArgs.unitCaster and tEventArgs.unitCaster ~= nil or GameLib.GetPlayerUnit():IsDead() ~= true then
            self.AttackerName = tEventArgs.unitCaster:GetName()

            if tEventArgs.unitCaster:GetId() ~= PlayerId then
                local strResult
                local strOverkill = 0

                if tEventArgs.nOverkill > 0 then
                    strOverkill = tEventArgs.nOverkill
                end

                local strDamageType = Apollo.GetString("CombatLog_UnknownDamageType")
                if tEventArgs.eDamageType then
                    strDamageType = self.tTypeMapping[tEventArgs.eDamageType]
                    if strDamageType == nil then
                        strDamageType = "Unknown"
                    end
                end


                if PushCount <= 20 then
                    strResult = self.AttackerName .."'s " ..  tEventArgs.splCallingSpell:GetName() .. " Has Hit For "
                            .. tEventArgs.nDamageAmount .. " As " .. strDamageType .. " Damage"

                    if strOverkill ~= 0 then
                        strResult = strResult ..", OverKill Amount" .. strOverkill
                    end

                    table.insert(tCombatHistory, strResult)
                    PushCount = PushCount + 1
                else
                    table.remove(tCombatHistory, 1)

                    strResult = self.AttackerName .."'s " ..  tEventArgs.splCallingSpell:GetName() .. " Has Hit For "
                            .. tEventArgs.nDamageAmount .. " As " .. strDamageType .. " Damage"

                    if strOverkill ~= 0 then
                        strResult = strResult ..", OverKill Amount" .. strOverkill
                    end
                    table.insert(tCombatHistory, strResult)
                end
            end
        end
end

function WhatHappened:OnClose()
    if wndRaidLeaderInst ~= nil and wndRaidLeaderInst:IsVisible() ==true then
        wndRaidLeaderInst:Close()
    else
        wndMainInst:Close() -- hide the window
    end
end

function WhatHappened:OnConfig()
    if not wndConfigInst then
        wndConfigInst = wndConfig:GetInstance(self,"TooltipStratum")
    else
        wndConfigInst:Show(true)
    end

    local checkbox = wndConfigInst:FindChild("chkRaidLeader")
    local ShowCheckbox = wndConfigInst:FindChild("chkShowOnDeath")

    if self.SavedData.profile.ICChannel ~= nil then
        wndConfigInst:FindChild("RaidChannel"):SetText(self.SavedData.profile.ICChannel)
    end
    if self.SavedData.profile.RaidLeaderMode == true then
        checkbox:SetCheck(self.SavedData.profile.RaidLeaderMode)
    end
    if self.SavedData.profile.ShowOnDeath == true then
        ShowCheckbox:SetCheck(self.SavedData.profile.ShowOnDeath)
    end
end

function WhatHappened:OnConfigSave()
    local RaidChannelInput = wndConfigInst:FindChild("RaidChannel"):GetText()
    local checkbox = wndConfigInst:FindChild("chkRaidLeader")
    local ShowCheckbox = wndConfigInst:FindChild("chkShowOnDeath")

    if RaidChannelInput == "" then
        RaidChannelInput = nil
    end

    --Get Settings
    self.SavedData.profile.ICChannel        = RaidChannelInput
    self.SavedData.profile.RaidLeaderMode   = checkbox:IsChecked()
    self.SavedData.profile.ShowOnDeath      = ShowCheckbox:IsChecked()

    --Join/leave ICCommLib Channel
    if self.SavedData.profile.ICChannel ~= nil then
        self.ICCommChannel = ICCommLib.JoinChannel(self.SavedData.profile.ICChannel, "OnMsgRecieved", self)
        Print("Joined Raid Channel " .. self.SavedData.profile.ICChannel)
    elseif self.SavedData.profile.ICChannel == nil then
        Print("You have left the Raid Channel, You will not recieve messages!")
    end

    wndConfigInst:Close()
end

function WhatHappened:OnDeath()
    local CurrentLine
    local CurrentRaidLine
    local strOutput = ""
    local strRaidOutput = ""

    if self.SavedData.profile.ShowOnDeath == true then
        wndMainInst = wndMain:GetInstance(self)
    end

    for k,v in ipairs(tCombatHistory) do
        CurrentLine = v --tCombatHistory[k]

        if type(CurrentLine) == "string" and CurrentLine ~= nil then
            strOutput = strOutput .. CurrentLine .. "\n"
        end
    end

    local CombatText = wndMainInst:FindChild("CombatText")
    CombatText:SetAML(strOutput)

    if self.SavedData.profile.ICChannel ~= nil then
        self.ICCommChannel:SendMessage({Msg = strOutput})
    end

    PushCount = 0
end

function WhatHappened:OnMsgRecieved(channel, tMsg, strSender)
    Event_FireGenericEvent("SendVarToRover","channel", channel)
    Event_FireGenericEvent("SendVarToRover","tMsg", tMsg)
    Event_FireGenericEvent("SendVarToRover","sender", strSender)
    if wndRaidLeaderInst then
        self.wndPlayerList = wndRaidLeaderInst:FindChild("RecipientList")

        tPlayerNameClickable:AddEvent("OnClicked", "OnClicked")
        local PlayerLabel = self.wndPlayerList:AddChild(wndPlayerNameClickable)
        PlayerLabel:SetText(strSender)
        self.wndPlayerList:ArrangeVert()
    end
end

function WhatHappened:SetDefaults()
    self.defaults =
    {
        profile =
        {
            RaidLeaderMode  = false,
            ICChannel       = "testing",
            ShowOnDeath     = false
        }
    }
    Print("WhatHappened has been Reset to Defaults!")
end