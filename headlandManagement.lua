--
-- Headland Management for LS 19
--
-- Jason06 / Glowins Modschmiede
-- Version 1.2.0.0
--

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(g_currentModName, true, 3)
GMSDebug:enableConsoleCommands("hlmDebug")

source(g_currentModDirectory.."gui/HeadlandManagementGui.lua")
g_gui:loadGui(g_currentModDirectory.."gui/HeadlandManagementGui.xml", "HeadlandManagementGui", HeadlandManagementGui:new())

HeadlandManagement = {}
HeadlandManagement.MOD_NAME = g_currentModName

HeadlandManagement.REDUCESPEED = 1
HeadlandManagement.CRABSTEERING = 2
HeadlandManagement.DIFFLOCK = 3
HeadlandManagement.RAISEIMPLEMENT = 4
HeadlandManagement.STOPPTO = 5
HeadlandManagement.STOPGPS = 6

HeadlandManagement.isDedi = g_dedicatedServerInfo ~= nil

HeadlandManagement.BEEPSOUND = createSample("HLMBEEP")
loadSample(HeadlandManagement.BEEPSOUND, g_currentModDirectory.."sound/beep.ogg", false)

HeadlandManagement.guiIcon = createImageOverlay(g_currentModDirectory.."gui/hlm_gui.dds")
HeadlandManagement.guiAuto = createImageOverlay(g_currentModDirectory.."gui/hlm_auto.dds")

-- Standards / Basics

function HeadlandManagement.prerequisitesPresent(specializations)
  return true
end

function HeadlandManagement.initSpecialization()
    --[[
    local schema = Vehicle.xmlSchema
    dbgprint("initSpecialization: starting xmlSchema registration process")
    schema:setXMLSpecializationType("headlandmanagement")
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#beep", "Audible alert", true)
	
	schema:register(XMLValueType.FLOAT, "vehicle.headlandmanagement#turnSpeed", "Speed in headlands", 5)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useSpeedControl", "Change speed in headlands", true)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useModSpeedControl", "use mod SpeedControl", false)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useCrabSteering", "Change crab steering in headlands", true)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useCrabSteeringTwoStep", "Changecrab steering over turn config", true)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useRaiseImplementF", "Raise front attachements in headlands", true)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useRaiseImplementB", "Raise back attahements in headlands", true)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useStopPTOF", "Stop front PTO in headlands", true)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useStopPTOB", "Stop back PTO in headlands", true)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#turnPlow", "Turn plow in headlands", true)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#centerPlow", "Center plow first in headlands", false)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#switchRidge", "Change ridgemarkers", true)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useGPS", "Change GPS", true)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useGuidanceSteering", "Use mod GuidanceSteering", false)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useGuidanceSteeringTrigger", "Use headland automatic", false)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useGuidanceSteeringOffset", "Use back trigger", false)
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useVCA", "Use mod VCA", false)
	
	schema:register(XMLValueType.BOOL, "vehicle.headlandmanagement#useDiffLock", "Unlock diff locks in headland", true)
	
    schema:setXMLSpecializationType()
   	dbgprint("initSpecialization: finished xmlSchema registration process")
   	--]]

    local schemaSavegame = Vehicle.xmlSchemaSavegame
	dbgprint("initSpecialization: starting xmlSchemaSavegame registration process")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#beep", "Audible alert", true)
	
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).HeadlandManagement#turnSpeed", "Speed in headlands", 5)
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
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useGuidanceSteering", "Use mod GuidanceSteering", false)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useGuidanceSteeringTrigger", "Use headland automatic", false)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useGuidanceSteeringOffset", "Use back trigger", false)
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).HeadlandManagement#useVCA", "Use mod VCA", false)
	
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
	
	spec.normSpeed = 20
	spec.turnSpeed = 5

	spec.actStep = 0
	spec.maxStep = 7
	
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
	spec.useTurnPlow = true
	spec.useCenterPlow = true
	spec.plowRotationMaxNew = nil
	
	spec.useRidgeMarker = true
	spec.ridgeMarkerState = 0
	
	spec.crabSteeringFound = false
	spec.useCrabSteering = true
	spec.useCrabSteeringTwoStep = true
	
	spec.useGPS = true
	spec.gpsSetting = 1 -- auto-mode
	spec.wasGPSAutomatic = false
	spec.modGuidanceSteeringFound = false
	spec.useGuidanceSteering = false
	spec.useGuidanceSteeringTrigger = false	
	spec.useGuidanceSteeringOffset = false
	spec.guidanceSteeringOffset = 0
	spec.setServerHeadlandActDistance = -1
	spec.GSStatus = false
	spec.modVCAFound = false
	spec.useVCA = false
	spec.vcaStatus = false
	
	spec.useDiffLock = true
	spec.diffStateF = false
	spec.diffStateB = false
end

function HeadlandManagement:onPostLoad(savegame)
	dbgprint("onPostLoad", 2)
	local spec = self.spec_HeadlandManagement
	if spec == nil then return end
	
	--spec.exists = self.configurations["HeadlandManagement"] == 2
	spec.exists = true
	dbgprint("onPostLoad : HLM exists: "..tostring(spec.exists))
	
	-- Check if vehicle supports CrabSteering
	local csSpec = self.spec_crabSteering
	spec.crabSteeringFound = csSpec ~= nil and csSpec.stateMax ~= nil and csSpec.stateMax > 0
	dbgprint("onPostLoad : CrabSteering exists: "..tostring(spec.crabSteeringFound))
	
	-- Check if Mod SpeedControl exists
	if SpeedControl ~= nil and SpeedControl.onInputAction ~= nil then 
		spec.modSpeedControlFound = true 
		spec.useModSpeedControl = true
		spec.turnSpeed = 1 --SpeedControl Mode 1
		spec.normSpeed = 2 --SpeedControl Mode 2
	end
	
	-- Check if Mod GuidanceSteering exists
	spec.modGuidanceSteeringFound = self.spec_globalPositioningSystem ~= nil
	
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
	spec.modVCAFound = self.vcaSetState ~= nil

	if savegame ~= nil and spec.exists then	
		dbgprint("onPostLoad : loading saved data", 2)
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".HeadlandManagement"
	
		spec.beep = xmlFile:getValue(key.."#beep", spec.beep)
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
		spec.useGuidanceSteering = xmlFile:getValue(key.."#useGuidanceSteering", spec.useGuidanceSteering)
		spec.useGuidanceSteeringTrigger = xmlFile:getValue(key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
		spec.useGuidanceSteeringOffset = xmlFile:getValue(key.."#useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
		spec.useVCA = xmlFile:getValue(key.."#useVCA", spec.useVCA)
		spec.useDiffLock = xmlFile:getValue(key.."#useDiffLock", spec.useDiffLock)
		dbgprint("onPostLoad : Loaded data for "..self:getName())
	end
	
	-- Set management actions
	spec.action[HeadlandManagement.REDUCESPEED] = spec.useSpeedControl
	spec.action[HeadlandManagement.CRABSTEERING] = spec.crabSteeringFound and spec.useCrabSteering
	spec.action[HeadlandManagement.DIFFLOCK] = spec.modVCAFound and spec.useDiffLock
	spec.action[HeadlandManagement.RAISEIMPLEMENT] = spec.useRaiseImplementF or spec.useRaiseImplementB
	spec.action[HeadlandManagement.STOPPTO] = spec.useStopPTOF or spec.useStopPTOB
	spec.action[HeadlandManagement.STOPGPS] = (spec.modGuidanceSteeringFound and spec.useGuidanceSteering) or (spec.modVCAFound and spec.useVCA)
end

function HeadlandManagement:saveToXMLFile(xmlFile, key)
-- TODO: Change save routines to xml and schema-based way using xmlFile.setData
	dbgprint("saveToXMLFile", 2)
	local spec = self.spec_HeadlandManagement
	if spec.exists then
		dbgprint("saveToXMLFile : key: "..tostring(key), 2)
		dbgprint_r(xmlFile, 4)
		setXMLBool(xmlFile.handle, key.."#beep", spec.beep)
		setXMLFloat(xmlFile.handle, key.."#turnSpeed", spec.turnSpeed)
		setXMLBool(xmlFile.handle, key.."#useSpeedControl", spec.useSpeedControl)
		setXMLBool(xmlFile.handle, key.."#useModSpeedControl", spec.useModSpeedControl)
		setXMLBool(xmlFile.handle, key.."#useCrabSteering", spec.useCrabSteering)
		setXMLBool(xmlFile.handle, key.."#useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
		setXMLBool(xmlFile.handle, key.."#useRaiseImplementF", spec.useRaiseImplementF)
		setXMLBool(xmlFile.handle, key.."#useRaiseImplementB", spec.useRaiseImplementB)
		setXMLBool(xmlFile.handle, key.."#useStopPTOF", spec.useStopPTOF)
		setXMLBool(xmlFile.handle, key.."#useStopPTOB", spec.useStopPTOB)
		setXMLBool(xmlFile.handle, key.."#turnPlow", spec.useTurnPlow)
		setXMLBool(xmlFile.handle, key.."#centerPlow", spec.useCenterPlow)
		setXMLBool(xmlFile.handle, key.."#switchRidge", spec.useRidgeMarker)
		setXMLBool(xmlFile.handle, key.."#useGPS", spec.useGPS)
		setXMLBool(xmlFile.handle, key.."#useGuidanceSteering", spec.useGuidanceSteering)
		setXMLBool(xmlFile.handle, key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
		setXMLBool(xmlFile.handle, key.."#useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
		setXMLBool(xmlFile.handle, key.."#useVCA", spec.useVCA)
		setXMLBool(xmlFile.handle, key.."#useDiffLock", spec.useDiffLock)
		dbgprint("saveToXMLFile : saving data finished", 2)
	end
end

function HeadlandManagement:onReadStream(streamId, connection)
	dbgprint("onReadStream", 2)
	local spec = self.spec_HeadlandManagement
	spec.beep = streamReadBool(streamId)
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
  	spec.useGuidanceSteering = streamReadBool(streamId)
  	spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
  	spec.useGuidanceSteeringOffset = streamReadBool(streamId)
  	spec.useVCA = streamReadBool(streamId)
  	spec.useDiffLock = streamReadBool(streamId)
end

function HeadlandManagement:onWriteStream(streamId, connection)
	dbgprint("onWriteStream", 2)
	local spec = self.spec_HeadlandManagement
	streamWriteBool(streamId, spec.beep)
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
  	streamWriteBool(streamId, spec.useGuidanceSteering)
  	streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
  	streamWriteBool(streamId, spec.useGuidanceSteeringOffset)
  	streamWriteBool(streamId, spec.useVCA)
  	streamWriteBool(streamId, spec.useDiffLock)
end
	
function HeadlandManagement:onReadUpdateStream(streamId, timestamp, connection)
	dbgprint("onReadUpdateStream", 3)
	if not connection:getIsServer() then
		dbgprint("onReadUpdateStream: receiving data...", 2)
		local spec = self.spec_HeadlandManagement
		if streamReadBool(streamId) then
			spec.beep = streamReadBool(streamId)
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
			spec.useGuidanceSteering = streamReadBool(streamId)
			spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
			spec.useGuidanceSteeringOffset = streamReadBool(streamId)
			spec.setServerHeadlandActDistance = streamReadFloat32(streamId)
			spec.useVCA = streamReadBool(streamId)
			spec.useDiffLock = streamReadBool(streamId)
		end;
	end
end

function HeadlandManagement:onWriteUpdateStream(streamId, connection, dirtyMask)
	dbgprint("onReadUpdateStream", 3)
	if connection:getIsServer() then
		dbgprint("onReadUpdateStream: sending data...", 2)
		local spec = self.spec_HeadlandManagement
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.beep)
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
			streamWriteBool(streamId, spec.useGuidanceSteering)
			streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
			streamWriteBool(streamId, spec.useGuidanceSteeringOffset)
			streamWriteFloat32(streamId, spec.setServerHeadlandActDistance)
			streamWriteBool(streamId, spec.useVCA)
			streamWriteBool(streamId, spec.useDiffLock)
		end
	end
end

-- inputBindings / inputActions
	
function HeadlandManagement:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 2)
	if self.isClient then
		local spec = self.spec_HeadlandManagement
		HeadlandManagement.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil and spec.exists then 
			local actionEventId;
			_, actionEventId = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_TOGGLESTATE', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			_, spec.actionEventOn = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SWITCHON', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventOn, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOn, not spec.isActive)
			_, spec.actionEventOff = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SWITCHOFF', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventOff, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOff, spec.isActive)
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
	dbgprint_r(hlmGui, 4, 2)
	hlmGui.target:setCallback(HeadlandManagement.guiCallback, self)
	--hlmGui.target:setData(
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
		spec.useGuidanceSteering,
		spec.useGuidanceSteeringTrigger,
		spec.useGuidanceSteeringOffset,
		spec.useVCA,
		spec.useDiffLock,
		spec.beep,
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
		useGuidanceSteering, 
		useGuidanceSteeringTrigger, 
		useGuidanceSteeringOffset,
		useVCA, 
		useDiffLock, 
		beep
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
	spec.useGuidanceSteering = useGuidanceSteering
	spec.useGuidanceSteeringTrigger = useGuidanceSteeringTrigger
	spec.useGuidanceSteeringOffset = useGuidanceSteeringOffset
	spec.useVCA = useVCA
	spec.useDiffLock = useDiffLock
	spec.beep = beep
	self:raiseDirtyFlags(spec.dirtyFlag)
end

-- Main part

function HeadlandManagement:onUpdate(dt)
	local spec = self.spec_HeadlandManagement
	
	-- play warning sound if headland management is active
	if not HeadlandManagement.isDedi and self:getIsActive() and self == g_currentMission.controlledVehicle and spec.exists and spec.beep and spec.isActive then
		spec.timer = spec.timer + dt
		if spec.timer > 2000 then 
			playSample(HeadlandManagement.BEEPSOUND, 1, 0.5, 0, 0, 0)
			dbgprint("Beep: "..self:getName(), 3)
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
		if spec.action[math.abs(spec.actStep)] and not HeadlandManagement.isDedi then
			dbgprint("onUpdate : actStep: "..tostring(spec.actStep))
			-- Set management actions
			spec.action[HeadlandManagement.REDUCESPEED] = spec.useSpeedControl
			spec.action[HeadlandManagement.CRABSTEERING] = spec.crabSteeringFound and spec.useCrabSteering
			spec.action[HeadlandManagement.DIFFLOCK] = spec.modVCAFound and spec.useDiffLock
			spec.action[HeadlandManagement.RAISEIMPLEMENT] = spec.useRaiseImplementF or spec.useRaiseImplementB
			spec.action[HeadlandManagement.STOPPTO] = spec.useStopPTOF or spec.useStopPTOB
			spec.action[HeadlandManagement.STOPGPS] = spec.useGPS and (spec.modGuidanceSteeringFound or spec.modVCAFound)
			
			-- Activation
			if spec.actStep == HeadlandManagement.REDUCESPEED and spec.action[HeadlandManagement.REDUCESPEED] then HeadlandManagement:reduceSpeed(self, true); end
			if spec.actStep == HeadlandManagement.CRABSTEERING and spec.action[HeadlandManagement.CRABSTEERING] then HeadlandManagement:crabSteering(self, true, spec.useCrabSteeringTwoStep); end
			if spec.actStep == HeadlandManagement.DIFFLOCK and spec.action[HeadlandManagement.DIFFLOCK] then HeadlandManagement:disableDiffLock(self, true); end
			if spec.actStep == HeadlandManagement.RAISEIMPLEMENT and spec.action[HeadlandManagement.RAISEIMPLEMENT] then HeadlandManagement:raiseImplements(self, true, spec.useTurnPlow, spec.useCenterPlow); end
			if spec.actStep == HeadlandManagement.STOPPTO and spec.action[HeadlandManagement.STOPPTO] then HeadlandManagement:stopPTO(self, true); end
			if spec.actStep == HeadlandManagement.STOPGPS and spec.action[HeadlandManagement.STOPGPS] then HeadlandManagement:stopGPS(self, true); end
			-- Deactivation
			if spec.actStep == -HeadlandManagement.STOPGPS and spec.action[HeadlandManagement.STOPGPS] then HeadlandManagement:stopGPS(self, false); end
			if spec.actStep == -HeadlandManagement.STOPPTO and spec.action[HeadlandManagement.STOPPTO] then HeadlandManagement:stopPTO(self, false); end
			if spec.actStep == -HeadlandManagement.RAISEIMPLEMENT and spec.action[HeadlandManagement.RAISEIMPLEMENT] then HeadlandManagement:raiseImplements(self, false, spec.useTurnPlow); end
			if spec.actStep == -HeadlandManagement.DIFFLOCK and spec.action[HeadlandManagement.DIFFLOCK] then HeadlandManagement:disableDiffLock(self, false); end
			if spec.actStep == -HeadlandManagement.CRABSTEERING and spec.action[HeadlandManagement.CRABSTEERING] then HeadlandManagement:crabSteering(self, false, spec.useCrabSteeringTwoStep); end
			if spec.actStep == -HeadlandManagement.REDUCESPEED and spec.action[HeadlandManagement.REDUCESPEED] then HeadlandManagement:reduceSpeed(self, false); end		
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
	if self:getIsActive() and spec.isActive and spec.exists then 
		g_currentMission:addExtraPrintText(g_i18n:getText("text_HLM_isActive"))
	 
		local scale = g_gameSettings.uiScale
		
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX * 0.70
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY
		local w = 0.015 * scale
		local h = w * g_screenAspectRatio
		
		renderOverlay(HeadlandManagement.guiIcon, x, y, w, h)
	end
	
	-- show icon if standby in auto-mode
	if self:getIsActive() and spec.exists and spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger and not spec.isActive then
		local spec_gs = self.spec_globalPositioningSystem 
		local gpsEnabled = (spec_gs.lastInputValues ~= nil and spec_gs.lastInputValues.guidanceSteeringIsActive)
		
		if gpsEnabled then
			local scale = g_gameSettings.uiScale
		
			local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX * 0.70
			local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY
			local w = 0.015 * scale
			local h = w * g_screenAspectRatio
		
			renderOverlay(HeadlandManagement.guiAuto, x, y, w, h)
		end
	end

	--dbgrenderTable(spec, 1, 3)
	local spec_gs = self.spec_globalPositioningSystem; if spec_gs ~= nil then dbgrenderTable(spec_gs, 1, 3); end
end
	
function HeadlandManagement:reduceSpeed(self, enable)	
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
			self:setCruiseControlMaxSpeed(spec.turnSpeed)
			if spec.modSpeedControlFound and self.speedControl ~= nil then
				self.speedControl.keys[self.speedControl.currentKey].speed = spec.turnSpeed
				dbgprint("reduceSpeed: SpeedControl adjusted")
			end
			if not self.isServer then
				g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent:new(self, spec.turnSpeed))
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
			self:setCruiseControlMaxSpeed(spec.normSpeed)
			if spec.modSpeedControlFound and self.speedControl ~= nil then
				self.speedControl.keys[self.speedControl.currentKey].speed = spec.normSpeed
				dbgprint("reduceSpeed: SpeedControl adjusted")
			end
			if not self.isServer then
				g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent:new(self, spec.normSpeed))
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

function HeadlandManagement:crabSteering(self, enable, twoSteps)
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
				dbgprint("crabSteering : testMode: state "..tostring(i)..": offset: "..tostring(testMode))
				if testMode == -csMode then 
					newState = i
				end
			end
			if twoSteps then
				csSpec:setCrabSteering(turnState)
				spec.csNewState = newState
			else
				csSpec:setCrabSteering(newState)
			end
		end
	else
		if twoSteps and spec.csNewState ~= nil then
			csSpec:setCrabSteering(spec.csNewState)
			spec.csNewState = nil
		end
	end
end

function HeadlandManagement:raiseImplements(self, raise, turnPlow, centerPlow)
	local spec = self.spec_HeadlandManagement
    dbgprint("raiseImplements : raise: "..tostring(raise).." / turnPlow: "..tostring(turnPlow))
    
	local allImplements = {}
	self:getRootVehicle():getChildVehicles(allImplements)
    
	for index,actImplement in pairs(allImplements) do
		-- raise or lower implement and turn plow
		if actImplement ~= nil and actImplement.getAllowsLowering ~= nil then
			dbgprint("raiseImplements : actImplement: "..actImplement:getName())
			if actImplement:getAllowsLowering() or actImplement.spec_pickup ~= nil or actImplement.spec_foldable ~= nil then
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
				else 
					print("HeadlandManagement :: raiseImplement : AttacherVehicle not set: towBar or towBarWeight active?")
					print("HeadlandManagement :: raiseImplement : Function restricted to first attacher joint")
					backImpl = true
				end
				
				if (frontImpl and spec.useRaiseImplementF) or (backImpl and spec.useRaiseImplementB) then
					if raise then
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
						local plowSpec = actImplement.spec_plow
						if plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and wasLowered then 
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
					else
						local wasLowered = spec.implementStatusTable[index]
						local lowered = false
						dbgprint("raiseImplements : wasLowered: "..tostring(wasLowered))
						dbgprint("raiseImplements : jointDescIndex: "..tostring(jointDescIndex))
						local plowSpec = actImplement.spec_plow
						if plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and wasLowered and spec.plowRotationMaxNew ~= nil then 
							actImplement:setRotationMax(spec.plowRotationMaxNew)
							spec.plowRotationMaxNew = nil
							dbgprint("raiseImplements : plow is turned")
						end
						if wasLowered and self.setJointMoveDown ~= nil then
							self:setJointMoveDown(jointDescIndex, true)
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is lowered by setJointMoveDown: "..tostring(lowered))
						end
						if wasLowered and not lowered and actImplement.setLoweredAll ~= nil then
							actImplement:setLoweredAll(true, jointDescIndex)
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is lowered by setLoweredAll: "..tostring(lowered))
						end
						if wasLowered and not lowered and (actImplement.spec_attacherJointControlPlow ~= nil or actImplement.spec_attacherJointControlCutter~= nil or actImplement.spec_attacherJointControlCultivator~= nil) then
							local implSpec = actImplement.spec_attacherJointControl
							implSpec.heightTargetAlpha = implSpec.jointDesc.lowerAlpha
							lowered = actImplement:getIsLowered()
							dbgprint("raiseImplements : implement is lowered by heightTargetAlpha: "..tostring(lowered))
						end
					end	
				end
		 	end
		end
		-- switch ridge marker
		if spec.useRidgeMarker and actImplement ~= nil and actImplement.spec_ridgeMarker ~= nil then
			local specRM = actImplement.spec_ridgeMarker
			dbgprint_r(specRM, 2)
			if raise then
				spec.ridgeMarkerState = specRM.ridgeMarkerState or 0
				dbgprint("ridgeMarker: State is "..tostring(spec.ridgeMarkerState).." / "..tostring(specRM.ridgeMarkerState))
				if spec.ridgeMarkerState ~= 0 and specRM.numRigdeMarkers ~= 0 then
					actImplement:setRidgeMarkerState(0)
				elseif spec.ridgeMarkerState ~= 0 and specRM.numRigdeMarkers == 0 then
					print("FS19_HeadlandManagement :: Info : Can't set ridgeMarkerState: RidgeMarkers not controllable by script!")
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
					print("FS19_HeadlandManagement :: Info : Can't set ridgeMarkerState: RidgeMarkers not controllable by script!")
				end
			end
		end
	end
end

function HeadlandManagement:stopPTO(self, stopPTO)
	local spec = self.spec_HeadlandManagement
    --local jointSpec = self.spec_attacherJoints
    dbgprint("stopPTO: "..tostring(stopPTO))
	
    local allImplements = {}
	self:getRootVehicle():getChildVehicles(allImplements)
	
	for index,actImplement in pairs(allImplements) do
		if actImplement ~= nil and actImplement.getAttacherVehicle ~= nil then
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
				print("HeadlandManagement :: stopPTO : AttacherVehicle not set: towBar or towBarWeight active?")
				print("HeadlandManagement :: stopPTO : Function restricted to all or nothing")
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
		end
	end
end

function HeadlandManagement:stopGPS(self, enable)
	local spec = self.spec_HeadlandManagement
	dbgprint("stopGPS : "..tostring(enable))

-- Part 1: Detect used mod
	if spec.modGuidanceSteeringFound and spec.useGuidanceSteering then spec.gpsSetting = 2; end -- GS mode enforced
	if spec.modVCAFound and spec.useVCA then spec.gpsSetting = 3; end -- VCA mode enforced
	
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
		local vcaStatus = self.vcaSnapIsOn
		if vcaStatus then 
			spec.gpsSetting = 3 
			dbgprint("stopGPS : VCA is active")
		end
	end
	dbgprint("stopGPS : gpsSetting: "..tostring(spec.gpsSetting))

-- Part 2: Guidance Steering	
	if spec.modGuidanceSteeringFound and self.onSteeringStateChanged ~= nil and spec.gpsSetting ~= 3 then
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
	if spec.modVCAFound and spec.gpsSetting ~= 2 and enable then
		spec.vcaStatus = self.vcaSnapIsOn
		if spec.vcaStatus then 
			dbgprint("stopGPS : VCA-GPS off")
			self:vcaSetState( "vcaSnapIsOn", false )
		end
	end
	if spec.modVCAFound and spec.vcaStatus and spec.gpsSetting ~= 2 and not enable then
		dbgprint("stopGPS : VCA-GPS on")
		self:vcaSetState( "vcaSnapIsOn", true )
		self:vcaSetSnapFactor()
		if spec.wasGPSAutomatic then
			spec.gpsSetting = 1
			spec.wasGPSAutomatic = false
		end
	end
end

function HeadlandManagement:disableDiffLock(self, disable)
	local spec = self.spec_HeadlandManagement
	if disable then
		spec.diffStateF = self.vcaDiffLockFront
		spec.diffStateB = self.vcaDiffLockBack
		if spec.diffStateF then 
			dbgprint("disableDiffLock : DiffLockF off")
			self:vcaSetState("vcaDiffLockFront", false)
		end
		if spec.diffStateB then 
			dbgprint("disableDiffLock : DiffLockB off")
			self:vcaSetState("vcaDiffLockBack", false)
		end
	else
		dbgprint("disableDiffLock : DiffLock reset")
		self:vcaSetState("vcaDiffLockFront", spec.diffStateF)
		self:vcaSetState("vcaDiffLockBack", spec.diffStateB)
	end
end
