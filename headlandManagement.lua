--
-- Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 2.0.0.0
--
-- TODO:
-- Hundegangwechsel auf dem DediServer prüfen


source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(g_currentModName)
GMSDebug:enableConsoleCommands("hlmDebug")

source(g_currentModDirectory.."gui/HeadlandManagementGui.lua")
g_gui:loadGui(g_currentModDirectory.."gui/HeadlandManagementGui.xml", "HeadlandManagementGui", HeadlandManagementGui:new())

HeadlandManagement = {}
HeadlandManagement.MOD_NAME = g_currentModName

HeadlandManagement.REDUCESPEED = 1
HeadlandManagement.CRABSTEERING = 2
HeadlandManagement.DIFFLOCK = 3
HeadlandManagement.RAISEIMPLEMENT = 4
HeadlandManagement.WAITTIME = 5
HeadlandManagement.TURNPLOW = 6
HeadlandManagement.STOPPTO = 7
HeadlandManagement.STOPGPS = 8

HeadlandManagement.isDedi = g_dedicatedServerInfo ~= nil

HeadlandManagement.BEEPSOUND = createSample("HLMBEEP")
loadSample(HeadlandManagement.BEEPSOUND, g_currentModDirectory.."sound/beep.ogg", false)

HeadlandManagement.guiIconField = createImageOverlay(g_currentModDirectory.."gui/hlm_field_normal.dds")
HeadlandManagement.guiIconFieldR = createImageOverlay(g_currentModDirectory.."gui/hlm_field_right.dds")
HeadlandManagement.guiIconFieldL = createImageOverlay(g_currentModDirectory.."gui/hlm_field_left.dds")
HeadlandManagement.guiIconStandby = createImageOverlay(g_currentModDirectory.."gui/hlm_standby.dds")
HeadlandManagement.guiIconHeadland = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_normal.dds")
HeadlandManagement.guiIconHeadlandR = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_right.dds")
HeadlandManagement.guiIconHeadlandL = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_left.dds")

-- Filteres implements
HeadlandManagement.filterList = {}
HeadlandManagement.filterList[1] = "E-DriveLaner"

-- Killbits for not yet published mods
HeadlandManagement.kbVCA = false
HeadlandManagement.kbGS = false
HeadlandManagement.kbSC = true

-- set configuration 

function addHLMconfig(xmlFile, superfunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
    local configurations, defaultConfigurationIds = superfunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
	dbgprint("addHLMconfig : Kat: "..storeItem.categoryName.." / ".."Name: "..storeItem.xmlFilename, 2)

	local category = storeItem.categoryName
	if 
		(	category == "TRACTORSS" 
		or	category == "TRACTORSM"
		or	category == "TRACTORSL"
		or	category == "HARVESTERS"
		or	category == "FORAGEHARVESTERS"
		or	category == "BEETVEHICLES"
		or	category == "POTATOVEHICLES"
		or	category == "COTTONVEHICLES"
		or	category == "SPRAYERVEHICLES"
		or	category == "SUGARCANEVEHICLES"
		or	category == "MOWERVEHICLES"
		or	category == "MISCVEHICLES"
		or 	category == "JOHNDEEREPACK"
		)
		and	configurations ~= nil

	then
		configurations["HeadlandManagement"] = {
        	{name = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_notInstalled_short"), index = 1, isDefault = true,  isSelectable = true, price = 0, dailyUpkeep = 0, desc = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_notInstalled")},
        	{name = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_installed_short"), index = 2, isDefault = false, isSelectable = true, price = 3000, dailyUpkeep = 0, desc = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_installed")}
    	}
    	dbgprint("addHLMconfig : Configuration HeadlandManagement added", 2)
    	dbgprint_r(configurations["HeadlandManagement"], 3)
	end
	
    return configurations, defaultConfigurationIds
end

-- Standards / Basics

function HeadlandManagement.prerequisitesPresent(specializations)
  return true
end

function HeadlandManagement.initSpecialization()
	dbgprint("initSpecialization : start", 2)
	if g_configurationManager.configurations["HeadlandManagement"] == nil then
		g_configurationManager:addConfigurationType("HeadlandManagement", g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_configuration"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	end
	StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, addHLMconfig)
	dbgprint("initSpecialization : Configuration initialized", 1)
	
    local schemaSavegame = Vehicle.xmlSchemaSavegame
	dbgprint("initSpecialization: starting xmlSchemaSavegame registration process")
	
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#configured", "HLM configured", false)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#beep", "Audible alert", true)
    schemaSavegame:register(XMLValueType.INT,  "vehicles.vehicle(?).HeadlandManagement#beepVol", "Audible alert volume", 5)
	
	schemaSavegame:register(XMLValueType.FLOAT,"vehicles.vehicle(?).HeadlandManagement#turnSpeed", "Speed in headlands", 5)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useSpeedControl", "Change speed in headlands", true)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useModSpeedControl", "use mod SpeedControl", false)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useCrabSteering", "Change crab steering in headlands", true)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useCrabSteeringTwoStep", "Changecrab steering over turn config", true)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useRaiseImplementF", "Raise front attachements in headlands", true)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useRaiseImplementB", "Raise back attahements in headlands", true)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useStopPTOF", "Stop front PTO in headlands", true)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useStopPTOB", "Stop back PTO in headlands", true)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#turnPlow", "Turn plow in headlands", true)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#centerPlow", "Center plow first in headlands", false)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#switchRidge", "Change ridgemarkers", true)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useGPS", "Change GPS", true)
	schemaSavegame:register(XMLValueType.INT,  "vehicles.vehicle(?).HeadlandManagement#gpsSetting", "GPS-Mode", 1)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useGuidanceSteeringTrigger", "Use headland automatic", false)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useGuidanceSteeringOffset", "Use back trigger", false)
	
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useDiffLock", "Unlock diff locks in headland", true)
	dbgprint("initSpecialization: finished xmlSchemaSavegame registration process")
end

function HeadlandManagement.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", HeadlandManagement)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", HeadlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", HeadlandManagement)
end

function HeadlandManagement:onLoad(savegame)
	dbgprint("onLoad", 2)
	local spec = self.spec_HeadlandManagement
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	spec.actionEventOn = nil
	spec.actionEventOn = nil
	
	spec.exists = false
	
	spec.timer = 0
	spec.beep = true
	spec.beepVol = 5
	
	spec.normSpeed = 20
	spec.turnSpeed = 5

	spec.actStep = 0
	spec.maxStep = 9
	
	spec.isActive = false
	spec.action = {}
	spec.action[0] =false
	
	spec.useSpeedControl = true
	spec.modSpeedControlFound = false
	spec.useModSpeedControl = false
	
	spec.useRaiseImplementF = true
	spec.useRaiseImplementB = true
	spec.implementStatusTable = {}
	spec.implementPTOTable = {}
	spec.useStopPTOF = true
	spec.useStopPTOB = true
	spec.waitTime = 0
	spec.useTurnPlow = true
	spec.useCenterPlow = true
	spec.plowRotationMaxNew = nil
	
	spec.useRidgeMarker = true
	spec.ridgeMarkerState = 0
	
	spec.crabSteeringFound = false
	spec.useCrabSteering = true
	spec.useCrabSteeringTwoStep = true
	
	spec.useGPS = true
	spec.gpsSetting = 1 -- 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right
	spec.wasGPSAutomatic = false
	spec.modGuidanceSteeringFound = false
	spec.useGuidanceSteeringTrigger = false	
	spec.useGuidanceSteeringOffset = false
	spec.guidanceSteeringOffset = 0
	spec.setServerHeadlandActDistance = -1
	spec.GSStatus = false
	spec.modVCAFound = false
	spec.vcaStatus = false
	spec.vcaDirSwitch = true
	
	spec.useDiffLock = true
	spec.diffStateF = false
	spec.diffStateB = false
end

function HeadlandManagement:onPostLoad(savegame)
	dbgprint("onPostLoad", 2)
	local spec = self.spec_HeadlandManagement
	if spec == nil then return end
	
	-- Check if vehicle supports CrabSteering
	local csSpec = self.spec_crabSteering
	spec.crabSteeringFound = csSpec ~= nil and csSpec.stateMax ~= nil and csSpec.stateMax > 0
	dbgprint("onPostLoad : CrabSteering exists: "..tostring(spec.crabSteeringFound))
	
	-- Check if Mod SpeedControl exists
	if SpeedControl ~= nil and SpeedControl.onInputAction ~= nil and not HeadlandManagement.kbSC then 
		spec.modSpeedControlFound = true 
		spec.useModSpeedControl = true
		spec.turnSpeed = 1 --SpeedControl Mode 1
		spec.normSpeed = 2 --SpeedControl Mode 2
	end
	
	-- Check if Mod GuidanceSteering exists
	spec.modGuidanceSteeringFound = self.spec_globalPositioningSystem ~= nil and not HeadlandManagement.kbGS
	
	-- Calculate front and back offset for GuidanceSteering
	local spec_at = self.spec_attacherJoints
	if spec.modGuidanceSteeringFound and spec_at ~= nil then
		local distFront, distBack = 0, 0
		for _,joint in pairs(spec_at.attacherJoints) do
			local wx, wy, wz = getWorldTranslation(joint.jointTransform)
			local lx, ly, lz = worldToLocal(self.rootNode, wx, wy, wz)
			distFront = math.max(distFront, lz)
			distBack = math.min(distBack, lz)
		end
		spec.guidanceSteeringOffset = math.ceil(math.abs(distFront)) + math.ceil(math.abs(distBack))
		dbgprint("onPostLoad : distFront:"..tostring(distFront))
		dbgprint("onPostLoad : distBack:"..tostring(distBack))
		dbgprint("onPostLoad : offset:"..tostring(spec.guidanceSteeringOffset))
	end

	-- Check if Mod VCA exists
	spec.modVCAFound = self.vcaSetState ~= nil and not HeadlandManagement.kbVCA

	-- HLM configured?
	spec.exists = self.configurations["HeadlandManagement"] == 2
	
	if savegame ~= nil then	
		dbgprint("onPostLoad : loading saved data", 2)
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".HeadlandManagement"
		spec.exists = xmlFile:getValue(key.."#configured", spec.exists)
		if spec.exists then
			spec.beep = xmlFile:getValue(key.."#beep", spec.beep)
			spec.beepVol = xmlFile:getValue(key.."#beepVol", spec.beepVol)
			spec.turnSpeed = xmlFile:getValue(key.."#turnSpeed", spec.turnSpeed)
			spec.useSpeedControl = xmlFile:getValue(key.."#useSpeedControl", spec.useSpeedControl)
			spec.useModSpeedControl = xmlFile:getValue(key.."#useModSpeedControl", spec.useModSpeedControl)
			spec.useCrabSteering = xmlFile:getValue(key.."#useCrabSteering", spec.useCrabSteering)
			spec.useCrabSteeringTwoStep = xmlFile:getValue(key.."#useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
			spec.useRaiseImplementF = xmlFile:getValue(key.."#useRaiseImplementF", spec.useRaiseImplementF)
			spec.useRaiseImplementB = xmlFile:getValue(key.."#useRaiseImplementB", spec.useRaiseImplementB)
			spec.useStopPTOF = xmlFile:getValue(key.."#useStopPTOF", spec.useStopPTOF)
			spec.useStopPTOB = xmlFile:getValue(key.."#useStopPTOB", spec.useStopPTOB)
			spec.useTurnPlow = xmlFile:getValue(key.."#turnPlow", spec.useTurnPlow)
			spec.useCenterPlow = xmlFile:getValue(key.."#centerPlow", spec.useCenterPlow)
			spec.useRidgeMarker = xmlFile:getValue(key.."#switchRidge", spec.useRidgeMarker)
			spec.useGPS = xmlFile:getValue(key.."#useGPS", spec.useGPS)
			spec.gpsSetting = xmlFile:getValue(key.."#gpsSetting", spec.gpsSetting)
			spec.useGuidanceSteeringTrigger = xmlFile:getValue(key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
			spec.useGuidanceSteeringOffset = xmlFile:getValue(key.."#useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
			spec.useDiffLock = xmlFile:getValue(key.."#useDiffLock", spec.useDiffLock)
			dbgprint("onPostLoad : Loaded whole data set", 2)
		end
		dbgprint("onPostLoad : Loaded data for "..self:getName())
	end
	
	if spec.gpsSetting == 2 and not spec.modGuidanceSteeringFound then spec.gpsSetting = 1 end
	if spec.gpsSetting > 2 and not spec.modVCAFound then spec.gpsSetting = 1 end
	
	-- HLM now configured?
	self.configurations["HeadlandManagement"] = spec.exists and 2 or 1
	dbgprint("onPostLoad : HLM exists: "..tostring(spec.exists))
	dbgprint_r(self.configurations, 4, 2)
end

function HeadlandManagement:saveToXMLFile(xmlFile, key, usedModNames)
	dbgprint("saveToXMLFile", 2)
	dbgprint("1:", 4)
	dbgprint_r(self.configurations, 4, 2)
	
	local spec = self.spec_HeadlandManagement
	spec.exists = self.configurations["HeadlandManagement"] == 2
	dbgprint("saveToXMLFile : key: "..tostring(key), 2)
		
	xmlFile:setValue(key.."#configured", spec.exists)
	if spec.exists then	
		xmlFile:setValue(key.."#beep", spec.beep)
		xmlFile:setValue(key.."#beepVol", spec.beepVol)
		xmlFile:setValue(key.."#turnSpeed", spec.turnSpeed)
		xmlFile:setValue(key.."#useSpeedControl", spec.useSpeedControl)
		xmlFile:setValue(key.."#useModSpeedControl", spec.useModSpeedControl)
		xmlFile:setValue(key.."#useCrabSteering", spec.useCrabSteering)
		xmlFile:setValue(key.."#useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
		xmlFile:setValue(key.."#useRaiseImplementF", spec.useRaiseImplementF)
		xmlFile:setValue(key.."#useRaiseImplementB", spec.useRaiseImplementB)
		xmlFile:setValue(key.."#useStopPTOF", spec.useStopPTOF)
		xmlFile:setValue(key.."#useStopPTOB", spec.useStopPTOB)
		xmlFile:setValue(key.."#turnPlow", spec.useTurnPlow)
		xmlFile:setValue(key.."#centerPlow", spec.useCenterPlow)
		xmlFile:setValue(key.."#switchRidge", spec.useRidgeMarker)
		xmlFile:setValue(key.."#useGPS", spec.useGPS)
		xmlFile:setValue(key.."#gpsSetting", spec.gpsSetting)
		xmlFile:setValue(key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
		xmlFile:setValue(key.."#useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
		xmlFile:setValue(key.."#useDiffLock", spec.useDiffLock)
		xmlFile:setValue(key.."#switchDirVCA", spec.vcaDirSwitch)
		dbgprint("saveToXMLFile : saving whole data", 2)
	end
	dbgprint("saveToXMLFile : saving data finished", 2)
end

function HeadlandManagement:onReadStream(streamId, connection)
	dbgprint("onReadStream", 3)
	local spec = self.spec_HeadlandManagement
	spec.exists = streamReadBool(streamId, connection)
	if spec.exists then
		spec.beep = streamReadBool(streamId)
		spec.beepVol = streamReadInt8(streamId)
		spec.turnSpeed = streamReadFloat32(streamId)
		spec.useSpeedControl = streamReadBool(streamId)
		spec.useModSpeedControl = streamReadBool(streamId)
		spec.useCrabSteering = streamReadBool(streamId)
		spec.useCrabSteeringTwoStep = streamReadBool(streamId)
		spec.useRaiseImplementF = streamReadBool(streamId)
		spec.useRaiseImplementB = streamReadBool(streamId)
		spec.useStopPTOF = streamReadBool(streamId)
		spec.useStopPTOB = streamReadBool(streamId)
		spec.useTurnPlow = streamReadBool(streamId)
		spec.useCenterPlow = streamReadBool(streamId)
		spec.useRidgeMarker = streamReadBool(streamId)
		spec.useGPS = streamReadBool(streamId)
		spec.gpsSetting = streamReadInt8(streamId)
		spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
		spec.useGuidanceSteeringOffset = streamReadBool(streamId)
		spec.useDiffLock = streamReadBool(streamId)
		spec.vcaDirSwitch = streamReadBool(streamId)
	end
end

function HeadlandManagement:onWriteStream(streamId, connection)
	dbgprint("onWriteStream", 3)
	local spec = self.spec_HeadlandManagement
	streamWriteBool(streamId, spec.exists)
	if spec.exists then
		streamWriteBool(streamId, spec.beep)
		streamWriteInt8(streamId, spec.beepVol)
		streamWriteFloat32(streamId, spec.turnSpeed)
		streamWriteBool(streamId, spec.useSpeedControl)
		streamWriteBool(streamId, spec.useModSpeedControl)
		streamWriteBool(streamId, spec.useCrabSteering)
		streamWriteBool(streamId, spec.useCrabSteeringTwoStep)
		streamWriteBool(streamId, spec.useRaiseImplementF)
		streamWriteBool(streamId, spec.useRaiseImplementB)
		streamWriteBool(streamId, spec.useStopPTOF)
		streamWriteBool(streamId, spec.useStopPTOB)
		streamWriteBool(streamId, spec.useTurnPlow)
		streamWriteBool(streamId, spec.useCenterPlow)
		streamWriteBool(streamId, spec.useRidgeMarker)
		streamWriteBool(streamId, spec.useGPS)
		streamWriteInt8(streamId, spec.gpsSetting)
		streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
		streamWriteBool(streamId, spec.useGuidanceSteeringOffset)
		streamWriteBool(streamId, spec.useDiffLock)
		streamWriteBool(streamId, spec.vcaDirSwitch)
	end
end
	
function HeadlandManagement:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_HeadlandManagement
		if streamReadBool(streamId) then
			dbgprint("onReadUpdateStream: receiving data...", 3)
			spec.exists = streamReadBool(streamId)
			if spec.exists then
				spec.beep = streamReadBool(streamId)
				spec.beepVol = streamReadInt8(streamId)
				spec.turnSpeed = streamReadFloat32(streamId)
				spec.useSpeedControl = streamReadBool(streamId)
				spec.useModSpeedControl = streamReadBool(streamId)
				spec.useCrabSteering = streamReadBool(streamId)
				spec.useCrabSteeringTwoStep = streamReadBool(streamId)
				spec.useRaiseImplementF = streamReadBool(streamId)
				spec.useRaiseImplementB = streamReadBool(streamId)
				spec.useStopPTOF = streamReadBool(streamId)
				spec.useStopPTOB = streamReadBool(streamId)
				spec.useTurnPlow = streamReadBool(streamId)
				spec.useCenterPlow = streamReadBool(streamId)
				spec.useRidgeMarker = streamReadBool(streamId)
				spec.useGPS = streamReadBool(streamId)
				spec.gpsSetting = streamReadInt8(streamId)
				spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
				spec.useGuidanceSteeringOffset = streamReadBool(streamId)
				spec.setServerHeadlandActDistance = streamReadFloat32(streamId)
				spec.useDiffLock = streamReadBool(streamId)
				spec.vcaDirSwitch = streamReadBool(streamId)
			end
		end
	end
end

function HeadlandManagement:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_HeadlandManagement
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			dbgprint("onWriteUpdateStream: sending data...", 3)
			streamWriteBool(streamId, spec.exists)
			if spec.exists then
				streamWriteBool(streamId, spec.beep)
				streamWriteInt8(streamId, spec.beepVol)
				streamWriteFloat32(streamId, spec.turnSpeed)
				streamWriteBool(streamId, spec.useSpeedControl)
				streamWriteBool(streamId, spec.useModSpeedControl)
				streamWriteBool(streamId, spec.useCrabSteering)
				streamWriteBool(streamId, spec.useCrabSteeringTwoStep)
				streamWriteBool(streamId, spec.useRaiseImplementF)
				streamWriteBool(streamId, spec.useRaiseImplementB)
				streamWriteBool(streamId, spec.useStopPTOF)
				streamWriteBool(streamId, spec.useStopPTOB)
				streamWriteBool(streamId, spec.useTurnPlow)
				streamWriteBool(streamId, spec.useCenterPlow)
				streamWriteBool(streamId, spec.useRidgeMarker)
				streamWriteBool(streamId, spec.useGPS)
				streamWriteInt8(streamId, spec.gpsSetting)
				streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
				streamWriteBool(streamId, spec.useGuidanceSteeringOffset)
				streamWriteFloat32(streamId, spec.setServerHeadlandActDistance)
				streamWriteBool(streamId, spec.useDiffLock)
				streamWriteBool(streamId, spec.vcaDirSwitch)
			end
		end
	end
end

-- inputBindings / inputActions
	
function HeadlandManagement:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 3)
	if self.isClient then
		local spec = self.spec_HeadlandManagement
		HeadlandManagement.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil and spec.exists then 
			_, spec.actionEventSwitch = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_TOGGLESTATE', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventSwitch, GS_PRIO_HIGH)
			
			_, spec.actionEventOn = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SWITCHON', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventOn, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOn, not spec.isActive)
			
			_, spec.actionEventOff = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SWITCHOFF', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventOff, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOff, spec.isActive)
			
			local actionEventId
			_, actionEventId = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SHOWGUI', self, HeadlandManagement.SHOWGUI, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		end		
	end
end

function HeadlandManagement:TOGGLESTATE(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("TOGGLESTATE", 3)
	local spec = self.spec_HeadlandManagement
	dbgprint_r(spec, 4)
	-- anschalten nur wenn inaktiv
	if not spec.isActive and (actionName == "HLM_SWITCHON" or actionName == "HLM_TOGGLESTATE") then
		spec.isActive = true
	-- abschalten nur wenn aktiv
	elseif spec.isActive and (actionName == "HLM_SWITCHOFF" or actionName == "HLM_TOGGLESTATE") and spec.actStep == spec.maxStep then
		spec.actStep = -spec.actStep
	end
	self:raiseDirtyFlags(spec.dirtyFlag)
end

-- GUI

function HeadlandManagement:SHOWGUI(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("SHOWGUI", 3)
	local spec = self.spec_HeadlandManagement
	local hlmGui = g_gui:showDialog("HeadlandManagementGui")
	local spec_gs = self.spec_globalPositioningSystem
	local gsConfigured = spec_gs ~= nil and spec_gs.hasGuidanceSystem == true
	local gpsEnabled = spec_gs ~= nil and spec_gs.lastInputValues ~= nil and spec_gs.lastInputValues.guidanceSteeringIsActive
	dbgprint_r(spec, 4, 2)
	hlmGui.target:setCallback(HeadlandManagement.guiCallback, self)
	HeadlandManagementGui.setData(
		hlmGui.target,
		self:getFullName(),
		spec.useSpeedControl,
		spec.useModSpeedControl,
		spec.crabSteeringFound,
		spec.useCrabSteering,
		spec.useCrabSteeringTwoStep,
		spec.turnSpeed,
		spec.useRaiseImplementF,
		spec.useRaiseImplementB,
		spec.useStopPTOF,
		spec.useStopPTOB,
		spec.useTurnPlow,
		spec.useCenterPlow,
		spec.useRidgeMarker,
		spec.useGPS,
		spec.gpsSetting,
		spec.useGuidanceSteeringTrigger,
		spec.useGuidanceSteeringOffset,
		spec.useDiffLock,
		spec.vcaDirSwitch,
		spec.beep,
		spec.beepVol,
		spec.modSpeedControlFound,
		spec.modGuidanceSteeringFound and gsConfigured,
		spec.modVCAFound,
		gpsEnabled
	)
end

function HeadlandManagement:guiCallback(
		useSpeedControl, 
		useModSpeedControl, 
		useCrabSteering, 
		useCrabSteeringTwoStep, 
		turnSpeed, 
		useRaiseImplementF, 
		useRaiseImplementB, 
		useStopPTOF, 
		useStopPTOB, 
		useTurnPlow, 
		useCenterPlow, 
		useRidgeMarker, 
		useGPS, 
		gpsSetting, 
		useGuidanceSteeringTrigger, 
		useGuidanceSteeringOffset,
		useDiffLock,
		vcaDirSwitch, 
		beep,
		beepVol
	)
	dbgprint("guiCallback", 2)
	local spec = self.spec_HeadlandManagement
	spec.useSpeedControl = useSpeedControl
	spec.useModSpeedControl = useModSpeedControl
	spec.useCrabSteering = useCrabSteering
	spec.useCrabSteeringTwoStep = useCrabSteeringTwoStep
	spec.turnSpeed = turnSpeed
	spec.useRaiseImplementF = useRaiseImplementF
	spec.useRaiseImplementB = useRaiseImplementB
	spec.useStopPTOF = useStopPTOF
	spec.useStopPTOB = useStopPTOB
	spec.useTurnPlow = useTurnPlow
	spec.useCenterPlow = useCenterPlow
	spec.useRidgeMarker = useRidgeMarker
	spec.useGPS = useGPS
	spec.gpsSetting = gpsSetting
	spec.useGuidanceSteeringTrigger = useGuidanceSteeringTrigger
	spec.useGuidanceSteeringOffset = useGuidanceSteeringOffset
	spec.useDiffLock = useDiffLock
	spec.vcaDirSwitch = vcaDirSwitch
	spec.beep = beep
	spec.beepVol = beepVol
	self:raiseDirtyFlags(spec.dirtyFlag)
	dbgprint_r(spec, 4, 2)
end

-- Main part

function HeadlandManagement:onUpdate(dt)
	local spec = self.spec_HeadlandManagement
	
	-- debug output
	if spec.actStep == 1 then
		dbgprint("onUpdate : spec_HeadlandManagement:", 3)
	end
	
	-- play warning sound if headland management is active
	if not HeadlandManagement.isDedi and self:getIsActive() and self == g_currentMission.controlledVehicle and spec.exists and spec.beep and spec.isActive then
		spec.timer = spec.timer + dt
		if spec.timer > 2000 then 
			playSample(HeadlandManagement.BEEPSOUND, 1, spec.beepVol / 10, 0, 0, 0)
			dbgprint("Beep: "..self:getName(), 4)
			spec.timer = 0
		end	
	else
		spec.timer = 0
	end
	
	-- activate headland management at headland in auto-mode
	if self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger then
		local gsSpec = self.spec_globalPositioningSystem
		if not spec.isActive and gsSpec.playHeadLandWarning then
			spec.isActive = true
		end
	end
	
	-- headland management main control
	if self:getIsActive() and spec.isActive and self == g_currentMission.controlledVehicle and spec.exists and spec.actStep<spec.maxStep then
		-- Set management actions
		spec.action[HeadlandManagement.REDUCESPEED] = spec.useSpeedControl
		spec.action[HeadlandManagement.CRABSTEERING] = spec.crabSteeringFound and spec.useCrabSteering
		spec.action[HeadlandManagement.DIFFLOCK] = spec.modVCAFound and spec.useDiffLock
		spec.action[HeadlandManagement.RAISEIMPLEMENT] = spec.useRaiseImplementF or spec.useRaiseImplementB
		spec.action[HeadlandManagement.WAITTIME] = spec.useTurnPlow and (spec.useRaiseImplementF or spec.useRaiseImplementB)
		spec.action[HeadlandManagement.TURNPLOW] = spec.useTurnPlow and (spec.useRaiseImplementF or spec.useRaiseImplementB)
		spec.action[HeadlandManagement.STOPPTO] = spec.useStopPTOF or spec.useStopPTOB
		spec.action[HeadlandManagement.STOPGPS] = spec.useGPS and (spec.modGuidanceSteeringFound or spec.modVCAFound)
		
		if spec.action[math.abs(spec.actStep)] and not HeadlandManagement.isDedi then
			dbgprint("onUpdate : actStep: "..tostring(spec.actStep))
			dbgprint("onUpdate : waitTime: "..tostring(spec.waitTime), 3)
			-- Activation
			if spec.actStep == HeadlandManagement.REDUCESPEED and spec.action[HeadlandManagement.REDUCESPEED] then HeadlandManagement.reduceSpeed(self, true); end
			if spec.actStep == HeadlandManagement.CRABSTEERING and spec.action[HeadlandManagement.CRABSTEERING] then HeadlandManagement.crabSteering(self, true, spec.useCrabSteeringTwoStep); end
			if spec.actStep == HeadlandManagement.DIFFLOCK and spec.action[HeadlandManagement.DIFFLOCK] then HeadlandManagement.disableDiffLock(self, true); end
			if spec.actStep == HeadlandManagement.RAISEIMPLEMENT and spec.action[HeadlandManagement.RAISEIMPLEMENT] then spec.waitTime = HeadlandManagement.raiseImplements(self, true, spec.useTurnPlow, spec.useCenterPlow, 1); end
			if spec.actStep == HeadlandManagement.WAITTIME and spec.action[HeadlandManagement.WAITTIME] then HeadlandManagement.wait(self, spec.waitTime, dt); end
			if spec.actStep == HeadlandManagement.TURNPLOW and spec.action[HeadlandManagement.TURNPLOW] then HeadlandManagement.raiseImplements(self, true, spec.useTurnPlow, spec.useCenterPlow, 2); end
			if spec.actStep == HeadlandManagement.STOPPTO and spec.action[HeadlandManagement.STOPPTO] then HeadlandManagement.stopPTO(self, true); end
			if spec.actStep == HeadlandManagement.STOPGPS and spec.action[HeadlandManagement.STOPGPS] then HeadlandManagement.stopGPS(self, true); end
			-- Deactivation
			if spec.actStep == -HeadlandManagement.STOPGPS and spec.action[HeadlandManagement.STOPGPS] then HeadlandManagement.stopGPS(self, false); end
			if spec.actStep == -HeadlandManagement.STOPPTO and spec.action[HeadlandManagement.STOPPTO] then HeadlandManagement.stopPTO(self, false); end
			if spec.actStep == -HeadlandManagement.TURNPLOW and spec.action[HeadlandManagement.TURNPLOW] then spec.waitTime = HeadlandManagement.raiseImplements(self, false, spec.useTurnPlow, spec.useCenterPlow, 2); end
			if spec.actStep == -HeadlandManagement.WAITTIME and spec.action[HeadlandManagement.WAITTIME] then HeadlandManagement.wait(self, spec.waitTime, dt); end
			if spec.actStep == -HeadlandManagement.RAISEIMPLEMENT and spec.action[HeadlandManagement.RAISEIMPLEMENT] then HeadlandManagement.raiseImplements(self, false, spec.useTurnPlow, spec.useCenterPlow, 1); end
			if spec.actStep == -HeadlandManagement.DIFFLOCK and spec.action[HeadlandManagement.DIFFLOCK] then HeadlandManagement.disableDiffLock(self, false); end
			if spec.actStep == -HeadlandManagement.CRABSTEERING and spec.action[HeadlandManagement.CRABSTEERING] then HeadlandManagement.crabSteering(self, false, spec.useCrabSteeringTwoStep); end
			if spec.actStep == -HeadlandManagement.REDUCESPEED and spec.action[HeadlandManagement.REDUCESPEED] then HeadlandManagement.reduceSpeed(self, false); end		
		end
		spec.actStep = spec.actStep + 1
		if spec.actStep == 0 then 
			spec.isActive = false
			self:raiseDirtyFlags(spec.dirtyFlag)
		end	
		g_inputBinding:setActionEventTextVisibility(spec.actionEventOn, not spec.isActive)
		g_inputBinding:setActionEventTextVisibility(spec.actionEventOff, spec.isActive)
	end
	
	-- adapt guidance steering's headland detection
	if self:getIsActive() and spec.exists and spec.useGuidanceSteeringOffset and spec.modGuidanceSteeringFound then
		local spec_gs = self.spec_globalPositioningSystem 
		local gpsEnabled = (spec_gs.lastInputValues ~= nil and spec_gs.lastInputValues.guidanceSteeringIsActive)
		if gpsEnabled and spec.useGuidanceSteeringTrigger and not spec.isActive then
			-- set offset for GS headland detection
			if spec.lastHeadlandActDistance == nil then
				spec.lastHeadlandActDistance = spec_gs.headlandActDistance
				spec_gs.headlandActDistance = MathUtil.clamp(spec_gs.headlandActDistance - spec.guidanceSteeringOffset, 0, 100)
				spec_gs.stateMachine:requestStateUpdate()
				if not self.isServer then
					spec.setServerHeadlandActDistance = spec_gs.headlandActDistance
					self:raiseDirtyFlags(spec.dirtyFlag)
				end
				dbgprint("onUpdate: (local) set GS distance from "..tostring(spec.lastHeadlandActDistance).." to "..tostring(spec_gs.headlandActDistance), 2)
			end
		end
		if not gpsEnabled and not spec.isActive then
			-- reset offset for GS headland detection if set before
			if spec.lastHeadlandActDistance ~= nil then
				dbgprint("onUpdate: (local) reset GS distance from "..tostring(spec_gs.headlandActDistance).." to "..tostring(spec.lastHeadlandActDistance), 2)
				spec_gs.headlandActDistance = spec.lastHeadlandActDistance
				spec_gs.stateMachine:requestStateUpdate()
				spec.lastHeadlandActDistance = nil
				if not self.isServer then
					spec.setServerHeadlandActDistance = spec_gs.headlandActDistance
					self:raiseDirtyFlags(spec.dirtyFlag)
				end
			end
		end
	end
	-- set headland adaption on server, too
	if self.isServer and spec.modGuidanceSteeringFound then
		local spec_gs = self.spec_globalPositioningSystem 
		if spec.setServerHeadlandActDistance >= 0 and spec_gs.headlandActDistance ~= spec.setServerHeadlandActDistance then
			spec_gs.headlandActDistance = spec.setServerHeadlandActDistance
			spec_gs.stateMachine:requestStateUpdate()
			dbgprint("onUpdate: (remote) adapted GS distance to "..tostring(spec.setServerHeadlandActDistance), 2)
		end
	end
end

function HeadlandManagement:onDraw(dt)
	local spec = self.spec_HeadlandManagement

	-- show icon if active
	if self:getIsActive() and spec.exists then 
		if spec.isActive then
			g_currentMission:addExtraPrintText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_isActive"))
			g_inputBinding:setActionEventText(spec.actionEventSwitch, g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("input_HLM_SWITCHOFF"))
		else
			g_inputBinding:setActionEventText(spec.actionEventSwitch, g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("input_HLM_SWITCHON"))
		end
		
		local scale = g_gameSettings.uiScale
		
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.speedGaugeSizeValues.centerOffsetX * 0.9
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY - g_currentMission.inGameMenu.hud.speedMeter.speedGaugeSizeValues.centerOffsetY * 0.92
		local w = 0.015 * scale
		local h = w * g_screenAspectRatio
		local guiIcon = HeadlandManagement.guiIconField
		
		if spec.isActive then 
			guiIcon = HeadlandManagement.guiIconHeadland
		end

		if spec.gpsSetting == 4 and self.vcaSnapReverseLeft ~= nil and self.vcaGetState ~= nil and self:vcaGetState("snapIsOn")then
			if not spec.isActive then 
				guiIcon = HeadlandManagement.guiIconFieldL
			else
				guiIcon = HeadlandManagement.guiIconHeadlandL
			end
		end
		if spec.gpsSetting == 5 and self.vcaSnapReverseRight ~= nil and self.vcaGetState ~= nil and self:vcaGetState("snapIsOn") then
			if not spec.isActive then 
				guiIcon = HeadlandManagement.guiIconFieldR
			else
				guiIcon = HeadlandManagement.guiIconHeadlandR
			end
		end
		if not spec.isActive and spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger then
			local spec_gs = self.spec_globalPositioningSystem 
			local gpsEnabled = (spec_gs.lastInputValues ~= nil and spec_gs.lastInputValues.guidanceSteeringIsActive)
			if gpsEnabled then
				guiIcon = HeadlandManagement.guiIconStandby
			end
		end
		
		renderOverlay(guiIcon, x, y, w, h)
	end
	
	dbgrenderTable(spec, 1, 3)
	local spec_gs = self.spec_globalPositioningSystem
	if spec_gs ~= nil then 
		-- dbgrenderTable(spec_gs, 1, 3)
	end
end
	
function HeadlandManagement.reduceSpeed(self, enable)	
	local spec = self.spec_HeadlandManagement
	local spec_drv = self.spec_drivable
	if spec_drv == nil then return; end;
	dbgprint("reduceSpeed : "..tostring(enable))
	if enable then
		spec.cruiseControlState = self:getCruiseControlState()
		dbgprint("reduceSpeed : cruiseControlState: "..tostring(spec.cruiseControlState))
		if spec.modSpeedControlFound and spec.useModSpeedControl and self.speedControl ~= nil then
			spec.normSpeed = self.speedControl.currentKey or 2
			if spec.normSpeed ~= spec.turnSpeed then
				dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.turnSpeed))
				SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.turnSpeed), true, false, false)
			end
		else
			spec.normSpeed = self:getCruiseControlSpeed()
			self:setCruiseControlMaxSpeed(spec.turnSpeed, spec.turnSpeed)
			if spec.modSpeedControlFound and self.speedControl ~= nil then
				self.speedControl.keys[self.speedControl.currentKey].speed = spec.turnSpeed
				dbgprint("reduceSpeed: SpeedControl adjusted")
			end
			if not self.isServer then
				g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent.new(self, spec.turnSpeed, spec.turnSpeed))
				dbgprint("reduceSpeed: speed sent to server")
			end
			dbgprint("reduceSpeed : Set cruise control to "..tostring(spec.turnSpeed))
		end
	else
		if spec.modSpeedControlFound and spec.useModSpeedControl and self.speedControl ~= nil then
			if self.speedControl.currentKey ~= spec.normSpeed then
				dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.normSpeed))
				SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.normSpeed), true, false, false)
			end
		else
			spec.turnSpeed = self:getCruiseControlSpeed()
			self:setCruiseControlMaxSpeed(spec.normSpeed, spec.normSpeed)
			if spec.modSpeedControlFound and self.speedControl ~= nil then
				self.speedControl.keys[self.speedControl.currentKey].speed = spec.normSpeed
				dbgprint("reduceSpeed: SpeedControl adjusted")
			end
			if not self.isServer then
				g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent.new(self, spec.normSpeed, spec.normSpeed))
				dbgprint("reduceSpeed: speed sent to server")
			end
			dbgprint("reduceSpeed : Set cruise control back to "..tostring(spec.normSpeed))
		end
		if spec.cruiseControlState == Drivable.CRUISECONTROL_STATE_ACTIVE then
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
			dbgprint("reduceSpeed : Reactivating CruiseControl")
		end
		spec.cruiseControlState = nil
	end
end

function HeadlandManagement.crabSteering(self, enable, twoSteps)
	local spec = self.spec_HeadlandManagement
	local csSpec = self.spec_crabSteering
	local stateMax = csSpec.stateMax
	local state = csSpec.state
	local newState = 1
	local turnState = 1
	if csSpec.aiSteeringModeIndex ~= nil then
		turnState = csSpec.aiSteeringModeIndex
	end
	dbgprint("crabSteering : "..tostring(enable))
	if enable then
		local csMode = 0
		if csSpec ~= nil and csSpec.steeringModes ~= nil and state ~= nil and csSpec.steeringModes[state] ~= nil and csSpec.steeringModes[state].wheels ~= nil and csSpec.steeringModes[state].wheels[3] ~= nil and csSpec.steeringModes[state].wheels[3].offset ~= nil then
			csMode = csSpec.steeringModes[state].wheels[3].offset
			dbgprint("crabSteering : Mode: "..tostring(csMode))
		end
		-- CrabSteering active? Find opposite state
		if csMode ~= 0 then
			for i=1,stateMax do
				local testMode = csSpec.steeringModes[i].wheels[3].offset
				dbgprint("crabSteering : testMode: state "..tostring(i)..": offset: "..tostring(testMode), 2)
				if testMode == -csMode then 
					newState = i
				end
			end
			if twoSteps then
				self:setCrabSteering(turnState)
				spec.csNewState = newState
			else
				self:setCrabSteering(newState)
			end
		end
	else
		if twoSteps and spec.csNewState ~= nil then
			self:setCrabSteering(spec.csNewState)
			spec.csNewState = nil
		end
	end
end

function HeadlandManagement.raiseImplements(self, raise, turnPlow, centerPlow, round)
	local spec = self.spec_HeadlandManagement
    dbgprint("raiseImplements : raise: "..tostring(raise).." / turnPlow: "..tostring(turnPlow))
    
    local waitTime = 0
	local allImplements = self:getRootVehicle():getChildVehicles()
	
	dbgprint("raiseImplements : #allImplements = "..tostring(#allImplements), 3)
    
	for index,actImplement in pairs(allImplements) do
		-- raise or lower implement and turn plow
		if actImplement ~= nil and actImplement.getAllowsLowering ~= nil then
			local implName = actImplement:getName()
			dbgprint("raiseImplements : actImplement: "..implName)
			local filtered = false
			for _,filterName in pairs(HeadlandManagement.filterList) do
				if implName == filterName then filtered = true end
			end
			if not filtered and (actImplement:getAllowsLowering() or actImplement.spec_pickup ~= nil or actImplement.spec_foldable ~= nil) then
				dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName()..") allows lowering, is PickUp or is foldable", 3)
				local jointDescIndex = 1 -- Joint #1 will always exist
				local actVehicle = actImplement:getAttacherVehicle()
				local frontImpl = false
				local backImpl = false
				
				-- find corresponding jointDescIndex
				if actVehicle ~= nil then
					for _,impl in pairs(actVehicle.spec_attacherJoints.attachedImplements) do
						if impl.object == actImplement then
							jointDescIndex = impl.jointDescIndex
							break
						end
					end
					
					local jointDesc = actVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]
					local wx, wy, wz = getWorldTranslation(jointDesc.jointTransform)
					local lx, ly, lz = worldToLocal(actVehicle.steeringAxleNode, wx, wy, wz)
				
					if lz > 0 then 
						frontImpl = true 
						dbgprint("raiseImplements: Front implement")
					else 
						backImpl = true
						dbgprint("raiseImplements: Back implement")
					end 
					
					local moveTime = actVehicle.spec_attacherJoints.attacherJoints[jointDescIndex].moveTime or 0
					if actImplement.spec_plow == nil then
						moveTime = 0
					end
					waitTime = math.max(waitTime, moveTime)
				else 
					print("HeadlandManagement :: raiseImplement : AttacherVehicle not set: Function restricted to first attacher joint")
					backImpl = true
				end
				
				if (frontImpl and spec.useRaiseImplementF) or (backImpl and spec.useRaiseImplementB) then
					if raise and round == 1 then
						local lowered = actImplement:getIsLowered()
						dbgprint("raiseImplements : lowered starts with "..tostring(lowered))
						dbgprint("raiseImplements : jointDescIndex: "..tostring(jointDescIndex))
						local wasLowered = lowered
						spec.implementStatusTable[index] = wasLowered
						if lowered and self.setJointMoveDown ~= nil then
							self:setJointMoveDown(jointDescIndex, false)
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is raised by setJointMoveDown: "..tostring(not lowered))
						end
						if lowered and actImplement.setLoweredAll ~= nil then 
							actImplement:setLoweredAll(false, jointDescIndex)
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is raised by setLoweredAll: "..tostring(not lowered))
						end
						if lowered and (actImplement.spec_attacherJointControlPlow ~= nil or actImplement.spec_attacherJointControlCutter~= nil or actImplement.spec_attacherJointControlCultivator~= nil) then
							local implSpec = actImplement.spec_attacherJointControl
							implSpec.heightTargetAlpha = implSpec.jointDesc.upperAlpha
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is raised by heightTargetAlpha: "..tostring(not lowered))
						end
					elseif raise and round == 2 then 
						local plowSpec = actImplement.spec_plow
						if plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and spec.implementStatusTable[index] then 
							if actImplement:getIsPlowRotationAllowed() then
								spec.plowRotationMaxNew = not plowSpec.rotationMax
								if centerPlow then 
									actImplement:setRotationCenter()
									dbgprint("raiseImplements : plow is centered")
								else
									actImplement:setRotationMax(spec.plowRotationMaxNew)
									dbgprint("raiseImplements : plow is turned")
								end
							end
						end
					elseif not raise then
						local wasLowered = spec.implementStatusTable[index]
						local lowered = false
						dbgprint("raiseImplements : wasLowered: "..tostring(wasLowered))
						dbgprint("raiseImplements : jointDescIndex: "..tostring(jointDescIndex))
						local plowSpec = actImplement.spec_plow
						if round == 2 and plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and wasLowered and spec.plowRotationMaxNew ~= nil then 
							actImplement:setRotationMax(spec.plowRotationMaxNew)
							spec.plowRotationMaxNew = nil
							dbgprint("raiseImplements : plow is turned")
							if not centerPlow then
								waitTime = 0
							end
						end
						if round == 1 and wasLowered and self.setJointMoveDown ~= nil then
							self:setJointMoveDown(jointDescIndex, true)
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is lowered by setJointMoveDown: "..tostring(lowered))
						end
						if round == 1 and wasLowered and not lowered and actImplement.setLoweredAll ~= nil then
							actImplement:setLoweredAll(true, jointDescIndex)
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is lowered by setLoweredAll: "..tostring(lowered))
						end
						if round == 1 and wasLowered and not lowered and (actImplement.spec_attacherJointControlPlow ~= nil or actImplement.spec_attacherJointControlCutter~= nil or actImplement.spec_attacherJointControlCultivator~= nil) then
							local implSpec = actImplement.spec_attacherJointControl
							implSpec.heightTargetAlpha = implSpec.jointDesc.lowerAlpha
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is lowered by heightTargetAlpha: "..tostring(lowered))
						end
					end	
					-- switch ridge marker
					if round == 1 and spec.useRidgeMarker and actImplement ~= nil and actImplement.spec_ridgeMarker ~= nil then
						local specRM = actImplement.spec_ridgeMarker
						dbgprint_r(specRM, 4)
						if raise then
							spec.ridgeMarkerState = specRM.ridgeMarkerState or 0
							dbgprint("ridgeMarker: State is "..tostring(spec.ridgeMarkerState).." / "..tostring(specRM.ridgeMarkerState))
							if spec.ridgeMarkerState ~= 0 and specRM.numRigdeMarkers ~= 0 then
								actImplement:setRidgeMarkerState(0)
							elseif spec.ridgeMarkerState ~= 0 and specRM.numRigdeMarkers == 0 then
								print("FS22_HeadlandManagement :: Info : Can't set ridgeMarkerState: RidgeMarkers not controllable by script!")
							end
						elseif spec.ridgeMarkerState ~= 0 then
							for state,_ in pairs(specRM.ridgeMarkers) do
								if state ~= spec.ridgeMarkerState then
									spec.ridgeMarkerState = state
									break
								end
							end
							dbgprint("ridgeMarker: New state will be "..tostring(spec.ridgeMarkerState))
							if specRM.numRigdeMarkers ~= 0 then
								actImplement:setRidgeMarkerState(spec.ridgeMarkerState)
								dbgprint("ridgeMarker: Set to "..tostring(specRM.ridgeMarkerState))
							elseif spec.ridgeMarkerState ~= 0 and specRM.numRigdeMarkers == 0 then
								print("FS22_HeadlandManagement :: Info : Can't set ridgeMarkerState: RidgeMarkers not controllable by script!")
							end
						end
					end
				end
		 	else
		 		if filtered then
		 			dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName()..") was filtered.", 1)
		 		else
		 			dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName()..") don't allows lowering, is no PickUp and is not foldable", 3)
		 		end
		 	end
		else
			if actImplement ~= nil then
				dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName().."): actImplement.getAllowsLowering == nil", 3)
			else
				dbgprint("raiseImplements : implement #"..tostring(index)..": actImplement == nil", 3)
			end
		end
	end
	return waitTime
end

function HeadlandManagement.wait(self, waitTime, dt)
	local spec = self.spec_HeadlandManagement
	dbgprint("wait : waitCounter: "..tostring(spec.waitCounter), 4)
	if spec.waitCounter == nil then
		spec.waitCounter = 0
	end
	spec.waitCounter = spec.waitCounter + dt
	if spec.waitCounter < waitTime then
		spec.actStep = spec.actStep - 1
	else
		spec.waitCounter = nil
	end
end

function HeadlandManagement.stopPTO(self, stopPTO)
	local spec = self.spec_HeadlandManagement
    dbgprint("stopPTO: "..tostring(stopPTO))
	
    local allImplements = self:getRootVehicle():getChildVehicles()
	
	for index,actImplement in pairs(allImplements) do
		-- stop or start implement
		if actImplement ~= nil and actImplement.getAttacherVehicle ~= nil then
			local implName = actImplement:getName()
			dbgprint("stopPTO : actImplement: "..implName)
			local filtered = false
			for _,filterName in pairs(HeadlandManagement.filterList) do
				if implName == filterName then filtered = true end
			end
			
			if not filtered then
			
				local jointDescIndex = 1 -- Joint #1 will always exist
				local actVehicle = actImplement:getAttacherVehicle()
				local frontPTO = false
				local backPTO = false
				
				-- find corresponding jointDescIndex and decide if front or back
				if actVehicle ~= nil then
					for _,impl in pairs(actVehicle.spec_attacherJoints.attachedImplements) do
						if impl.object == actImplement then
							jointDescIndex = impl.jointDescIndex
							break
						end
					end
					
					local jointDesc = actVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]
					local wx, wy, wz = getWorldTranslation(jointDesc.jointTransform)
					local lx, ly, lz = worldToLocal(actVehicle.steeringAxleNode, wx, wy, wz)
				
					if lz > 0 then 
						frontPTO = true 
						dbgprint("stopPTO: Front PTO")
					else 
						backPTO = true
						dbgprint("stopPTO: Back PTO")
					end 
				else 
					print("HeadlandManagement :: stopPTO : AttacherVehicle not set: Function restricted to all or nothing")
					frontPTO = true
					backPTO = true
				end
			
				dbgprint("stopPTO : actImplement: "..actImplement:getName())
				if (frontPTO and spec.useStopPTOF) or (backPTO and spec.useStopPTOB) then
					if stopPTO then
						local active = actImplement.getIsPowerTakeOffActive ~= nil and actImplement:getIsPowerTakeOffActive()
						spec.implementPTOTable[index] = active
						if active and actImplement.setIsTurnedOn ~= nil then 
							actImplement:setIsTurnedOn(false)
							dbgprint("stopPTO : implement PTO stopped by setIsTurnedOn")
						elseif active and actImplement.deactivate ~= nil then
							actImplement:deactivate()
							dbgprint("stopPTO : implement PTO stopped by deactivate")
						end
					else
						local active = spec.implementPTOTable[index]
						if active and actImplement.setIsTurnedOn ~= nil then 
							actImplement:setIsTurnedOn(true) 
							dbgprint("stopPTO : implement PTO started by setIsTurnedOn")
						elseif active and actImplement.activate ~= nil then
							actImplement:activate()
							dbgprint("stopPTO : implement PTO started by activate")
						end
					end
				end
			else
				dbgprint("stopPTO : implement #"..tostring(index).." ("..actImplement:getName()..") was filtered.", 1)
			end
		end
	end
end

function HeadlandManagement.stopGPS(self, enable)
	local spec = self.spec_HeadlandManagement
	dbgprint("stopGPS : "..tostring(enable))

-- Part 1: Detect used mod
	if spec.gpsSetting == 1 then
		spec.wasGPSAutomatic = true
	end
	
	if spec.gpsSetting == 1 and spec.modGuidanceSteeringFound then
		local gsSpec = self.spec_globalPositioningSystem
		local gpsEnabled = (gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive)
		if gpsEnabled then 
			spec.gpsSetting = 2 
			dbgprint("stopGPS : GS is active")
		end
	end
		
	if spec.gpsSetting == 1 and spec.modVCAFound then
		local vcaStatus = self:vcaGetState("snapIsOn")
		if vcaStatus then 
			spec.gpsSetting = 3 
			dbgprint("stopGPS : VCA is active")
		end
	end
	dbgprint("stopGPS : gpsSetting: "..tostring(spec.gpsSetting))

-- Part 2: Guidance Steering	
	if spec.modGuidanceSteeringFound and self.onSteeringStateChanged ~= nil and spec.gpsSetting < 3 then
		local gsSpec = self.spec_globalPositioningSystem
		if enable then
			dbgprint("stopGPS : Guidance Steering off")
			local gpsEnabled = (gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive)
			if gpsEnabled then
				spec.gpsSetting = 2
				spec.GSStatus = true
				gsSpec.lastInputValues.guidanceSteeringIsActive = false
				self:onSteeringStateChanged(false)
			else
				spec.GSStatus = false
			end
		else
			local gpsEnabled = spec.GSStatus	
			if gpsEnabled then
				dbgprint("stopGPS : Guidance Steering on")
				spec.gpsSetting = 2
				gsSpec.lastInputValues.guidanceSteeringIsActive = true
				self:onSteeringStateChanged(true)
			end
			if spec.wasGPSAutomatic then
				spec.gpsSetting = 1
				spec.wasGPSAutomatic = false
			end
		end
	end
	
-- Part 3: Vehicle Control Addon (VCA)
	dbgprint("spec.gpsSetting: "..tostring(spec.gpsSetting))
	if spec.modVCAFound and spec.gpsSetting ~= 2 and enable then
		spec.vcaStatus = self:vcaGetState("snapIsOn")
		if spec.vcaStatus then 
			if spec.gpsSetting == 1 or spec.gpsSetting == 3 then
				dbgprint("stopGPS : VCA-GPS off")
				self:vcaSetState( "snapIsOn", false )
			else
				if spec.gpsSetting == 4 then 
					if self.vcaSnapReverseLeft ~= nil then 
						self:vcaSnapReverseLeft()
						dbgprint("stopGPS : VCA-GPS turn left")
					end
				else
					if self.vcaSnapReverseRight ~= nil then 
						self:vcaSnapReverseRight() 
						dbgprint("stopGPS : VCA-GPS turn right")
					end
				end
			end
		end 
	end
	if spec.modVCAFound and spec.vcaStatus and (spec.gpsSetting == 1 or spec.gpsSetting == 3) and not enable then
		dbgprint("stopGPS : VCA-GPS on")
		self:vcaSetState( "snapIsOn", true )
		self:vcaSetState( "snapDirection", 0 )
		self:vcaSetSnapFactor()
		if spec.wasGPSAutomatic then
			spec.gpsSetting = 1
			spec.wasGPSAutomatic = false
		end
	end
	if spec.modVCAFound and spec.vcaStatus and (spec.gpsSetting == 4 or spec.gpsSetting == 5) and not enable and spec.vcaDirSwitch then
		if spec.gpsSetting == 4 then 
			spec.gpsSetting = 5
			print("Switch 1")
		else
			spec.gpsSetting = 4
			print("Switch 2")
		end
	end
end

function HeadlandManagement.disableDiffLock(self, disable)
	local spec = self.spec_HeadlandManagement
	if disable then
		spec.diffStateF = self:vcaGetState("diffLockFront") --self.vcaDiffLockFront
		spec.diffStateB = self:vcaGetState("diffLockBack") --self.vcaDiffLockBack
		if spec.diffStateF then 
			dbgprint("disableDiffLock : DiffLockF off")
			self:vcaSetState("diffLockFront", false)
		end
		if spec.diffStateB then 
			dbgprint("disableDiffLock : DiffLockB off")
			self:vcaSetState("diffLockBack", false)
		end
	else
		dbgprint("disableDiffLock : DiffLock reset")
		self:vcaSetState("diffLockFront", spec.diffStateF)
		self:vcaSetState("diffLockBack", spec.diffStateB)
	end
end
