--[[
Interface: 1.4.1.0 b5334

Copyright (C) GtX (Andy), 2019

Author: GtX | Andy
Date: 07.04.2019
Version: 1.0.0.0

History:
V 1.0.0.0 @ 07.04.2019 - Release Version

Contact:
GtX_Andy@protonmail.com

Important:
Not to be added to any mods / maps or modified from its current release form.
No changes are to be made to this script without permission from GtX | Andy

Darf nicht zu Mods / Maps hinzugefügt oder von der aktuellen Release-Form geändert werden.
An diesem Skript dürfen ohne Genehmigung von GtX | Andy keine Änderungen vorgenommen werden
]]

EasyDevControlsGeneralFrame = {}
local EasyDevControlsGeneralFrame_mt = Class(EasyDevControlsGeneralFrame, TabbedMenuFrameElement)

EasyDevControlsGeneralFrame.L10N_SYMBOL = {}

EasyDevControlsGeneralFrame.CONTROLS = {
    GENERAL_CONTAINER = "generalContainer",
    HELP_BOX_TEXT = "generalHelpBoxText",
    HELP_BOX = "generalHelpBox",
    SET_CHEAT_MONEY = "setCheatMoney",
    SET_DRAW_GUI_HELPER = "setDrawGuiHelper",
    BUTTON_CLEAN_I3D_CACHE = "buttonCleanI3DCache",
    SET_FOV = "setFOV",
    BUTTON_UPDATE_TIP_COL = "buttonUpdateTipCollisions",
    SET_SHOW_TIP_COL = "setShowTipCollisions",
    SET_TIP_FILLTYPE_CHANGE = "setTipFillTypeChange",
    SET_TIP_FILLTYPE_AMOUNT = "setTipFillTypeAmount",
    BUTTON_TIP_FILL_TYPE = "buttonTipFillType",
    BUTTON_CLEAR_TIP_AREA = "buttonClearTipArea",
    TELEPORT_TEXT = "teleportText",
    SET_TELEPORT_FIELD = "setTeleportField",
    SET_TELEPORT_XZ = "setTeleportXZ",
    BUTTON_TELEPORT_CONFIRM = "buttonTeleportConfirm",
    SET_SELECT_CHEAT_SILO = "setSelectCheatSilo",
    SET_CHEAT_SILO_AMOUNT = "setCheatSiloAmount",
    BUTTON_CHEAT_SILO = "buttonCheatSilo",
    SET_CHANGE_BALE = "setChangeBale",
    BUTTON_ADD_BALE = "buttonAddBale",
    SET_CHANGE_PALLET = "setChangePallet",
    BUTTON_ADD_PALLET = "buttonAddPallet",
    SET_CHANGE_LOG = "setChangeLog",
    BUTTON_ADD_LOG = "buttonAddLog",
    SET_DEBUG_FIELD_STATUS = "setDebugFieldStatus",
    SET_NETWORK_DEBUG = "setNetworkDebug",
    SET_SHOW_NETWORK_TRAFFIC = "setShowNetworkTraffic",
    SET_NETWORK_SHOW_ACTIVE_OBJECTS = "setNetworkShowActiveObjects"
}

EasyDevControlsGeneralFrame.GUI_HELPER_STEPS = {
    "Off", "0.05", "0.1", "0.15", "0.2", "0.25",
    "0.3", "0.35", "0.4", "0.45", "0.5",
    "0.55", "0.6", "0.65", "0.7","0.75",
    "0.8", "0.85", "0.9", "0.95", "1"
}

EasyDevControlsGeneralFrame.VALUE_TO_HELPER_STEPS = {
    ["0.00"] = 1, ["0.05"] = 2, ["0.10"] = 3, ["0.15"] = 4, ["0.20"] = 5, ["0.25"] = 6,
    ["0.30"] = 7, ["0.35"] = 8, ["0.40"] = 9, ["0.45"] = 10, ["0.50"] = 11,
    ["0.55"] = 12, ["0.60"] = 13, ["0.65"] = 14, ["0.70"] = 15, ["0.75"] = 16,
    ["0.80"] = 17, ["0.85"] = 18, ["0.90"] = 19, ["0.95"] = 20, ["1.00"] = 21
}

EasyDevControlsGeneralFrame.FIELD_STATUS_SIZE = {
    0, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
}

EasyDevControlsGeneralFrame.BALES = {
    [1] = {width = 1.2, height = 0.9, length = 2.4, fillTypeName = "STRAW", l10n = "fillType_straw"},
    [2] = {width = 1.2, height = 0.9, length = 2.4, fillTypeName = "DRYGRASS_WINDROW", l10n = "fillType_dryGrass"},
    [3] = {width = 1.2, height = 0.9, length = 2.4, fillTypeName = "GRASS_WINDROW", l10n = "fillType_grass"},
    [4] = {width = 1.2, height = 0.9, length = 2.4, fillTypeName = "SILAGE", l10n = "fillType_silage"},
    [5] = {width = 1.12, diameter = 1.3, length = 2.4, fillTypeName = "STRAW", l10n = "fillType_straw"},
    [6] = {width = 1.12, diameter = 1.3, length = 2.4, fillTypeName = "DRYGRASS_WINDROW", l10n = "fillType_dryGrass"},
    [7] = {width = 1.12, diameter = 1.3, length = 2.4, fillTypeName = "GRASS_WINDROW", l10n = "fillType_grass"},
    [8] = {width = 1.12, diameter = 1.3, length = 2.4, fillTypeName = "SILAGE", l10n = "fillType_silage"},
    [9] = {width = 2.44, height = 2.44, length = 4.88, fillTypeName = "COTTON", l10n = "fillType_cotton"}
}

EasyDevControlsGeneralFrame.PALLETS = {
    [1] = {name = "WOOL", l10n = "fillType_wool"},
    [2] = {name = "LIQUID_FERTILIZER", l10n = "fillType_liquidFertilizer"},
    [3] = {name = "TREE_SAPLINGS", l10n = "fillType_treeSaplings"},
    [4] = {name = "FERTILIZER", l10n = "fillType_fertilizer"},
    [5] = {name = "PIGFOOD", l10n = "fillType_pigFood"},
    [6] = {name = "EGG", l10n = "fillType_egg"},
    [7] = {name = "POPLAR", l10n = "fillType_poplar"},
    [8] = {name = "HERBICIDE", l10n = "fillType_herbicide"},
    [9] = {name = "SEEDS", l10n = "fillType_seeds"},
    [10] = {name = "LIME", l10n = "fillType_lime"}
}

EasyDevControlsGeneralFrame.LOG_LENGTHS = {
    "1.0 Meter", "2.0 Meters", "3.0 Meters", "4.0 Meters",
    "5.0 Meters", "6.0 Meters", "7.0 Meters", "8.0 Meters"
}

EasyDevControlsGeneralFrame.CHEAT_SILO = {
    0, 1000, 10000, 20000, 30000, 40000, 50000, 60000,
    70000, 80000, 90000, 100000, 200000, 500000
}

EasyDevControlsGeneralFrame.TIP_TO_GROUND = {
    0,
    1000,
    10000,
    20000,
    30000,
    40000,
    50000,
    60000,
    70000,
    80000,
    90000,
    100000
}

EasyDevControlsGeneralFrame.MAX_MONEY = 999999999

function EasyDevControlsGeneralFrame:new()
    local self = TabbedMenuFrameElement:new(nil, EasyDevControlsGeneralFrame_mt)

    self.l10n = g_i18n
    self.printToLog = false

    self.allowCommandStatePrint = true
    self.lastCheatMoneyAmount = ""

    self.fillTypeTitles = {}
    self.selectedIndexToFillTypeName = {}
    self.cheatFillTypeSelectionToName = {}

    self.cheatSiloAmountIndex = 1

    self.pileFillTypeIndex = nil
    self.pileVolumeToTip = 0

    self.currentBaleIndex = 1
    self.currentPalletIndex = 1
    self.currentLogIndex = 1

    self.fieldStatusTexts = {}

    self:registerControls(EasyDevControlsGeneralFrame.CONTROLS)

    return self
end

function EasyDevControlsGeneralFrame:initialize(l10n, printToLog)
    self.l10n = l10n
    self.printToLog = printToLog

    local offText = l10n:getText("ui_off")
    for id, size in pairs (EasyDevControlsGeneralFrame.FIELD_STATUS_SIZE) do
        self.fieldStatusTexts[id] = tostring(size) .. " m"
    end
    self.fieldStatusTexts[1] = offText

    EasyDevControlsGeneralFrame.GUI_HELPER_STEPS[1] = offText
end

function EasyDevControlsGeneralFrame:onFrameOpen()
    EasyDevControlsGeneralFrame:superClass().onFrameOpen(self)

    local notServer = not g_currentMission:getIsServer()

    local disableCommand = true
    if g_currentMission:getIsServer() or g_currentMission.isMasterUser then
        disableCommand = false
    end

    self.lastCheatMoneyAmount = ""
    self.setCheatMoney:setText(self.lastCheatMoneyAmount)
    self.setCheatMoney:setDisabled(disableCommand)

    self.setDrawGuiHelper:setTexts(EasyDevControlsGeneralFrame.GUI_HELPER_STEPS)

    local currentStep = 1
    if g_drawGuiHelper then
        local stepValue = tonumber(string.format("%1.2f", MathUtil.clamp(g_guiHelperSteps, 0, 1)))
        local mod = stepValue % 0.05
        if mod >= 0.02 then
            stepValue = stepValue + (0.05 - mod)
        elseif mod < 0.02 then
            stepValue = stepValue - mod
        end

        currentStep = EasyDevControlsGeneralFrame.VALUE_TO_HELPER_STEPS[string.format("%1.2f", stepValue)] or 1
    end

    self.setDrawGuiHelper:setState(currentStep, false)

    local disableClean = next(g_i3DManager.sharedI3DFiles) == nil
    self.buttonCleanI3DCache:setDisabled(disableClean)

    self.lastFovValue = ""

    self.buttonUpdateTipCollisions:setDisabled(notServer)
    self.setShowTipCollisions:setIsChecked(g_showTipCollisions)
    self.setShowTipCollisions:setDisabled(notServer)

    if g_currentMission:getIsServer() then
        if #self.selectedIndexToFillTypeName == 0 then
            local i = 1
            local fillTypes = g_fillTypeManager:getFillTypes()
            for _, fillType in pairs (fillTypes) do
                if fillType.name ~= "TARP" and DensityMapHeightUtil.getCanTipToGround(fillType.index) then
                    self.fillTypeTitles[i] = fillType.title
                    self.selectedIndexToFillTypeName[i] = fillType.name
                    i = i + 1
                end
            end
        end

        self.setTipFillTypeChange:setTexts(self.fillTypeTitles)
        self.setTipFillTypeChange:setState(1, true)
    else
        self.setTipFillTypeChange:setTexts({"Server Only!"})
    end

    self.setTipFillTypeAmount:setTexts(EasyDevControlsGeneralFrame.TIP_TO_GROUND)
    self.setTipFillTypeAmount:setState(1, true)

    self.setTipFillTypeChange:setDisabled(notServer)
    self.setTipFillTypeAmount:setDisabled(notServer)
    self.buttonTipFillType:setDisabled(true)

    self.buttonClearTipArea:setDisabled(notServer)

    if self.fields == nil then
        self.fields = {}
        for i, _ in ipairs (g_fieldManager.fields) do
            self.fields[i] = "Field " .. tostring(i)
        end

        table.insert(self.fields, "X / Z")
        self.numFieldsEntries = #self.fields
    end

    if g_currentMission.controlledVehicle ~= nil then
        self.teleportText:setText(self.l10n:getText("EDC_teleportVehicles"))
    else
        self.teleportText:setText(self.l10n:getText("EDC_teleportPlayer"))
    end

    self.setTeleportField:setTexts(self.fields)
    self.setTeleportField:setState(self.numFieldsEntries, true)
    self.setTeleportField:setDisabled(notServer)

    self.lastTeleportXZ = ""
    self.teleportSpaceUsed = nil
    self.setTeleportXZ:setText(self.lastTeleportXZ)
    self.setTeleportXZ:setDisabled(notServer)

    self.buttonTeleportConfirm:setDisabled(notServer)

    local baleTexts = {}
    for id, bale in ipairs (EasyDevControlsGeneralFrame.BALES) do
        local text = self.l10n:getText(bale.l10n)
        if bale.diameter == nil then
            text = text .. " - Square"
        else
            text = text .. " - Round"
        end

        table.insert(baleTexts, text)
    end

    self.setChangeBale:setTexts(baleTexts)
    self.setChangeBale:setState(1, true)
    self.setChangeBale:setDisabled(notServer)
    self.buttonAddBale:setDisabled(notServer)

    local palletTexts = {}
    for id, pallet in ipairs (EasyDevControlsGeneralFrame.PALLETS) do
        local text = self.l10n:getText(pallet.l10n)
        table.insert(palletTexts, text)
    end

    self.setChangePallet:setTexts(palletTexts)
    self.setChangePallet:setState(1, true)
    self.setChangePallet:setDisabled(notServer)
    self.buttonAddPallet:setDisabled(notServer)

    self.setChangeLog:setTexts(EasyDevControlsGeneralFrame.LOG_LENGTHS)
    self.setChangeLog:setState(1, true)
    self.setChangeLog:setDisabled(notServer)
    self.buttonAddLog:setDisabled(notServer)

    local cheatFillTypes = self:getSilosToCheat(disableCommand)
    local cheatSiloActive = #cheatFillTypes > 0
    if cheatSiloActive then
        self.setSelectCheatSilo:setTexts(cheatFillTypes)
        self.setSelectCheatSilo:setState(1, true)
    else
        if disableCommand then
            self.setSelectCheatSilo:setTexts({"N/A"})
        else
            self.setSelectCheatSilo:setTexts({"No Silos!"})
        end
    end

    self.setSelectCheatSilo:setDisabled(not cheatSiloActive)
    self.setCheatSiloAmount:setTexts(EasyDevControlsGeneralFrame.CHEAT_SILO)
    self.setCheatSiloAmount:setState(1, true)
    self.setCheatSiloAmount:setDisabled(not cheatSiloActive)
    self.buttonCheatSilo:setDisabled(not cheatSiloActive)

    self.setDebugFieldStatus:setTexts(self.fieldStatusTexts)

    if g_currentMission.missionDynamicInfo.isMultiplayer then
        if g_server ~= nil then
            self.setShowNetworkTraffic:setIsChecked(g_server.showNetworkTraffic)
            self.setNetworkShowActiveObjects:setIsChecked(g_server.showActiveObjects)
            self.setNetworkDebug:setIsChecked(g_networkDebug)
        elseif g_client ~= nil then
            self.setShowNetworkTraffic:setIsChecked(g_client.showNetworkTraffic)
            self.setNetworkShowActiveObjects:setIsChecked(g_client.showActiveObjects)
            self.setNetworkDebug:setIsChecked(false)
            self.setNetworkDebug:setDisabled(true)
        end
    else
        self.setShowNetworkTraffic:setDisabled(true)
        self.setNetworkDebug:setDisabled(true)
        self.setNetworkShowActiveObjects:setDisabled(true)
    end
end

function EasyDevControlsGeneralFrame:onCheatMoneyEnterPressed()
    if self.setCheatMoney.text ~= "" then
        local valueToCheat = tonumber(self.setCheatMoney.text)
        if valueToCheat ~= nil then
            g_currentMission:consoleCommandCheatMoney(math.min(valueToCheat, EasyDevControlsGeneralFrame.MAX_MONEY))

            if valueToCheat > 0 then
                self:printCommandState(string.format(self.l10n:getText("EDC_addMoney"), self.l10n:formatMoney(math.min(valueToCheat, EasyDevControlsGeneralFrame.MAX_MONEY), 0, true, true)))
            else
                self:printCommandState(string.format(self.l10n:getText("EDC_removeMoney"), self.l10n:formatMoney(math.abs(valueToCheat), 0, true, true)))
            end
        else
            self:printCommandState(self.l10n:getText("EDC_invalidMoney"))
        end

        self.setCheatMoney:setText("")
    end

    self.lastCheatMoneyAmount = ""
end

function EasyDevControlsGeneralFrame:onCheatMoneyEscPressed()
    if self.setCheatMoney.text ~= "" then
        self.setCheatMoney:setText("")
    end
end

function EasyDevControlsGeneralFrame:onCheatMoneyTextChanged()
    local text = self.setCheatMoney.text
    if text ~= "" then
        if text == "-" or tonumber(text) ~= nil then
            self.lastCheatMoneyAmount = text
        else
            self.setCheatMoney:setText(self.lastCheatMoneyAmount)
        end
    else
        self.lastCheatMoneyAmount = ""
    end
end

function EasyDevControlsGeneralFrame:onClickDrawGuiHelper(index)
    local step = EasyDevControlsGeneralFrame.GUI_HELPER_STEPS[index]
    if step ~= nil and step ~= "0" then
        self:printCommandState(consoleCommandDrawGuiHelper(step))
    else
        if g_drawGuiHelper then
            self:printCommandState(consoleCommandDrawGuiHelper())
        end
    end
end

function EasyDevControlsGeneralFrame:onClickCleanI3DCache()
    self:printCommandState(consoleCommandCleanI3DCache())
    self.buttonCleanI3DCache:setDisabled(true)
end

function EasyDevControlsGeneralFrame:onSetFOVEnterPressed()
    if self.setFOV.text ~= "" then
        if tonumber(self.setFOV.text) ~= nil then
            self:printCommandState(g_currentMission:consoleCommandSetFOV(self.setFOV.text))
        else
            self:printCommandState("[Set FOV Angle] '" .. self.setFOV.text .. "' is not a valid FOV value!")
        end

        self.setFOV:setText("")
    end

    self.lastFovValue = ""
end

function EasyDevControlsGeneralFrame:onSetFOVEscPressed()
    if self.setFOV.text ~= "" then
        self.setFOV:setText("")
    end
end

function EasyDevControlsGeneralFrame:onSetFOVTextChanged()
    local text = self.setFOV.text
    if text ~= "" then
        local num = tonumber(text)
        if text == "-" or (num ~= nil and num >= -1) then
            self.lastFovValue = text
        else
            self.setFOV:setText(self.lastFovValue)
        end
    else
        self.lastFovValue = ""
    end
end

function EasyDevControlsGeneralFrame:onClickToggleDebugFieldStatus(index)
    if index > 1 then
        local size = EasyDevControlsGeneralFrame.FIELD_STATUS_SIZE[index]
        FSBaseMission.DEBUG_SHOW_FIELDSTATUS_SIZE = size
        FSBaseMission.DEBUG_SHOW_FIELDSTATUS = true

        self:printCommandState("Field status debug enabled at " .. tostring(size) .. " Meters")
    else
        FSBaseMission.DEBUG_SHOW_FIELDSTATUS = false
        self:printCommandState("Field status debug disabled")
    end

    -- Do it manually so I can use a 'multiTextOption'
    -- consoleCommandToggleDebugFieldStatus(meters)
end

function EasyDevControlsGeneralFrame:onClickShowTipCollisions(index)
    g_currentMission:consoleCommandShowTipCollisions(index > 1)
    self:printCommandState("Show Tip Collisions = " .. string.upper(tostring(g_showTipCollisions)))
end

function EasyDevControlsGeneralFrame:onClickUpdateTipCollisions()
    g_currentMission:consoleCommandUpdateTipCollisions()
    self.buttonUpdateTipCollisions:setDisabled(true)
    self:printCommandState("Tip Collisions have been updated.")
end

function EasyDevControlsGeneralFrame:onClickTipFillTypeChange(index)
    self.pileFillTypeName = self.selectedIndexToFillTypeName[index]
end

function EasyDevControlsGeneralFrame:onClickTipFillTypeAmount(index)
    self.pileVolumeToTip = EasyDevControlsGeneralFrame.TIP_TO_GROUND[index]
    self.buttonTipFillType:setDisabled(index == 1)
end

function EasyDevControlsGeneralFrame:onClickTipFillType()
    if g_currentMission:getIsServer() and self.pileVolumeToTip > 0 then
        if self.pileFillTypeName ~= nil then
            self:printCommandState(g_currentMission:consoleCommandTipFillType(self.pileFillTypeName, self.pileVolumeToTip))
        end
    end
end

function EasyDevControlsGeneralFrame:onClickClearTipArea()
    if g_currentMission:getIsServer() then
        self:printCommandState(g_currentMission:consoleCommandClearTipArea("20"))
    end
end

function EasyDevControlsGeneralFrame:onClickTeleportField(fieldIndex)
    self.teleportFieldIndex = fieldIndex

    local disabled = fieldIndex < self.numFieldsEntries
    self.setTeleportXZ:setDisabled(disabled)

    if self.setTeleportXZ.text ~= "" then
        self.lastTeleportXZ = ""
        self.setTeleportXZ:setText("")
    end
end

function EasyDevControlsGeneralFrame:onTeleportEnterPressed()
    self:onClickTeleportConfirm()
end

function EasyDevControlsGeneralFrame:onTeleportEscPressed()
    if self.setTeleportXZ.text ~= "" then
        self.setTeleportXZ:setText("")
        self.teleportSpaceUsed = nil
    end
end

function EasyDevControlsGeneralFrame:onTeleportTextChanged()
    local text = self.setTeleportXZ.text
    if text ~= "" then
        local newChar = text:sub(-1)
        if newChar == " " or tonumber(newChar) ~= nil then
            self.lastTeleportXZ = text
        else
            self.setTeleportXZ:setText(self.lastTeleportXZ)
        end
    else
        self.lastTeleportXZ = ""
    end
end

function EasyDevControlsGeneralFrame:onClickTeleportConfirm()
    local x, z

    if self.teleportFieldIndex < self.numFieldsEntries then
        x = tostring(self.teleportFieldIndex)
    else
        if self.setTeleportXZ.text ~= "" then
            local position = StringUtil.splitString(" ", self.setTeleportXZ.text)
            if #position >= 2 then
                x = tostring(position[1])
                z = tostring(position[2])
            else
                self:printCommandState(self.l10n:getText("EDC_invalidTeleport"))
            end
        end
    end

    if x ~= nil then
        g_currentMission:consoleCommandTeleport(x, z)
        self.lastTeleportXZ = ""
        self.setTeleportXZ:setText("")

        if z ~= nil then
            if g_currentMission.controlledVehicle ~= nil then
                self:printCommandState(string.format(self.l10n:getText("EDC_teleportPlayerVehiclesXZ"), x, z))
            else
                self:printCommandState(string.format(self.l10n:getText("EDC_teleportPlayerXZ"), x, z))
            end
        else
            if g_currentMission.controlledVehicle ~= nil then
                self:printCommandState(string.format(self.l10n:getText("EDC_teleportPlayerVehiclesField"), x))
            else
                self:printCommandState(string.format(self.l10n:getText("EDC_teleportPlayerField"), x))
            end
        end
    else
        self:printCommandState(self.l10n:getText("EDC_emptyTeleport"))
    end
end

function EasyDevControlsGeneralFrame:onClickSelectCheatSilo(index)
    if #self.cheatFillTypeSelectionToName > 0 then
        self.selectedCheatSiloName = self.cheatFillTypeSelectionToName[index]
    end
end

function EasyDevControlsGeneralFrame:onClickCheatSiloAmount(index)
    self.cheatSiloAmountIndex = index
end

function EasyDevControlsGeneralFrame:onClickCheatSilo()
    if g_currentMission:getIsServer() or g_currentMission.isMasterUser then
        local fillTypeName = self.selectedCheatSiloName
        if fillTypeName ~= nil then
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex ~= nil then
                local volumeToAdd = EasyDevControlsGeneralFrame.CHEAT_SILO[self.cheatSiloAmountIndex] or 0
                self:printCommandState(g_easyDevControls:addLevelToSilos(fillTypeIndex, volumeToAdd, g_currentMission:getFarmId()))
            end

            -- This only sets the amount not add to it also not good with my event as I can not see the code :-).
            -- self:printCommandState(g_currentMission:consoleCommandCheatSilo(fillTypeName, tostring(volumeToAdd)))
        end
    end
end

function EasyDevControlsGeneralFrame:onClickChangeBale(index)
    self.currentBaleIndex = index
end

function EasyDevControlsGeneralFrame:onClickAddBale()
    local bale = EasyDevControlsGeneralFrame.BALES[self.currentBaleIndex]
    if bale ~= nil then
        local isRound = "false"
        local typ = "Square"
        local height = bale.height
        if bale.diameter ~= nil then
            isRound = "true"
            typ = "Round"
            height = bale.diameter
        end

        local message = g_currentMission:consoleCommandAddBale(bale.fillTypeName, isRound, bale.width, height, bale.length)
        self:printCommandState("Created " .. typ .. " " .. self.l10n:getText(bale.l10n) .. " bale.")

        self.buttonCleanI3DCache:setDisabled(false)
    end
end

function EasyDevControlsGeneralFrame:onClickChangePallet(index)
    self.currentPalletIndex = index
end

function EasyDevControlsGeneralFrame:onClickAddPallet()
    local pallet = EasyDevControlsGeneralFrame.PALLETS[self.currentPalletIndex]
    if pallet ~= nil then
        g_currentMission:consoleCommandAddPallet(pallet.name)
        self:printCommandState("Created " .. self.l10n:getText(pallet.l10n) .. " pallet.")

        self.buttonCleanI3DCache:setDisabled(false)
    end
end

function EasyDevControlsGeneralFrame:onClickChangeLog(index)
    self.currentLogIndex = index
end

function EasyDevControlsGeneralFrame:onClickAddLog()
    g_currentMission:consoleCommandLoadTree(MathUtil.clamp(self.currentLogIndex, 1, 8), "TREEFIR", 6)
    self:printCommandState("Created " .. self.currentLogIndex .. " Meter 'TREEFIR' Log.")

    self.buttonCleanI3DCache:setDisabled(false)
end

function EasyDevControlsGeneralFrame:onClickToggleToggleNetworkDebug(index)
    if g_server ~= nil then
        self:printCommandState(g_server:consoleCommandToggleNetworkDebug())
    end
end

function EasyDevControlsGeneralFrame:onClickToggleShowNetworkTraffic(index)
    if g_server ~= nil then
        self:printCommandState(g_server:consoleCommandToggleShowNetworkTraffic())
    else
        self:printCommandState(g_client:consoleCommandToggleShowNetworkTraffic())
    end
end

function EasyDevControlsGeneralFrame:onClickToggleNetworkShowActiveObjects(index)
    if g_server ~= nil then
        self:printCommandState(g_server:consoleCommandToggleNetworkShowActiveObjects())
    else
        self:printCommandState(g_client:consoleCommandToggleNetworkShowActiveObjects())
    end
end

function EasyDevControlsGeneralFrame:getSilosToCheat(disableCommand)
    local cheatFillTypes = {}
    self.cheatFillTypeSelectionToName = {}

    if not disableCommand then
        local availableStorageFillTypes = {}
        local storageSystem = g_currentMission.storageSystem
        for _, storage in pairs(storageSystem.storages) do
            local canAccessStorage = g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), storage)
            if canAccessStorage then
                for _, fillTypeIndex in ipairs(storage.sortedFillTypes) do
                    if availableStorageFillTypes[fillTypeIndex] == nil then
                        availableStorageFillTypes[fillTypeIndex] = true

                        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
                        table.insert(cheatFillTypes, fillType.title)
                        table.insert(self.cheatFillTypeSelectionToName, fillType.name)
                    end
                end
            end
        end
    end

    return cheatFillTypes
end

function EasyDevControlsGeneralFrame:onResetConfirm(doReset)
    if not doReset then
        return
    end

    self.allowCommandStatePrint = false

    self.lastCheatMoneyAmount = ""
    self.setCheatMoney:setText("")

    self.setDrawGuiHelper:setState(1, true)

    self.setShowTipCollisions:setState(1, true)
    self.setTipFillTypeChange:setState(1, true)
    self.setTipFillTypeAmount:setState(1, true)

    self.setTeleportField:setState(self.numFieldsEntries, true)

    self.setChangeBale:setState(1, true)
    self.setChangePallet:setState(1, true)
    self.setChangeLog:setState(1, true)

    self.setSelectCheatSilo:setState(1, true)
    self.setCheatSiloAmount:setState(1, true)

    self.setDebugFieldStatus:setState(1, true)

    self.allowCommandStatePrint = true
    self:printCommandState(self.l10n:getText("EDC_resetPageComplete"))
end

function EasyDevControlsGeneralFrame:onToolTipBoxTextChanged(toolTipBox)
    local showText = (toolTipBox.text ~= nil and toolTipBox.text ~= "")
    self.generalHelpBox:setVisible(showText)
end

function EasyDevControlsGeneralFrame:getMainElementSize()
    return self.generalContainer.size
end

function EasyDevControlsGeneralFrame:getMainElementPosition()
    return self.generalContainer.absPosition
end

function EasyDevControlsGeneralFrame:printCommandState(text)
    if self.allowCommandStatePrint and (text ~= nil and text ~= "") then

        self.generalHelpBoxText:setText(text)
        self.generalHelpBox:setVisible(true)

        if self.printToLog then
            print("EDC - General: " .. text)
        end
    end
end
