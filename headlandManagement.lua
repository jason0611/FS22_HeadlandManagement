--
-- Headland Management for LS 19
--
-- Jason06 / Glowins Modschmiede
-- Version 1.1.0.0
--
-- Fixed wrong JointDescIndex
--

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(g_currentModName, true, 2)
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

-- Console Commands

addConsoleCommand("hlmToggleAction", "Toggle HeadlandManagement settings: ", "toggleAction", HeadlandManagement)
function HeadlandManagement:toggleAction(hlmAction)
	
	local vehicle = g_currentMission.controlledVehicle
	
	if hlmAction == nil then
		return "hlmToggleAction <Status|Speed|Diffs|Raise|Plow|PlowCenter|PTO|Ridgemarker|GPS|beep>"
	end
	
	local spec = vehicle.spec_HeadlandManagement
	if spec == nil then	
		return "No Headland Management installed"
	end
	
	if hlmAction == "Status" then
		print("Spec:")
		print_r(spec)
		return "=="
	end
	
	if hlmAction == "Speed" then 
		spec.useSpeedControl = not spec.useSpeedControl
		return "Speedcontrol set to "..tostring(spec.useSpeedControl)
	end
	
	if hlmAction == "Diffs" then
		spec.useDiffLock = not spec.useDiffLock and spec.modVCAFound
		return "DiffLock set to "..tostring(spec.useDiffLock)
	end
	
	if hlmAction == "Raise" then
		spec.useRaiseImplement = not spec.useRaiseImplement
		return "RaiseImplement set to "..tostring(spec.useRaiseImplement)
	end
	
	if hlmAction == "Plow" then
		spec.useTurnPlow = not spec.useTurnPlow
		return "TurnPlow set to "..tostring(spec.useTurnPlow)
	end
	
	if hlmAction == "PlowCenter" then
		spec.useCenterPlow = not spec.useCenterPlow
		return "CenterPlow set to "..tostring(spec.useCenterPlow)

	end
	
	if hlmAction == "PTO" then
		spec.useStopPTO = not spec.useStopPTO
		return "PTO set to "..tostring(spec.useStopPTO)
	end
	
	if hlmAction == "Ridgemarker" then
		spec.useRidgeMarker = not spec.useRidgeMarker
		return "RidgeMarker set to "..tostring(spec.useRidgeMarker)
	end
	
	if hlmAction == "GPS" then
		spec.useGPS = not spec.useGPS and (spec.modGuidanceSteeringFound or spec.modVCAFound)
		return "GPS is set to "..tostring(spec.useGPS)
	end
	
	if hlmAction == "beep" then
		spec.beep = not spec.beep
		return "beep is set to "..tostring(spec.beep)
	end
	
	if hlmAction == "Status" then
		print_r(spec)
		return "done"
	end
end	

-- Standards / Basics

function HeadlandManagement.prerequisitesPresent(specializations)
  return true
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
	
	spec.useRaiseImplement = true
	spec.implementStatusTable = {}
	spec.implementPTOTable = {}
	spec.useStopPTO = true
	spec.useTurnPlow = true
	spec.useCenterPlow = true
	spec.plowRotationMaxNew = nil
	
	spec.useRidgeMarker = true
	spec.ridgeMarkerStatus = 0
	
	spec.crabSteeringFound = false
	spec.useCrabSteering = true
	spec.useCrabSteeringTwoStep = true
	
	spec.useGPS = true
	spec.gpsSetting = 1 -- auto-mode
	spec.wasGPSAutomatic = false
	spec.modGuidanceSteeringFound = false
	spec.useGuidanceSteering = false
	spec.useGuidanceSteeringTrigger = false	
	spec.GSStatus = false
	spec.modVCAFound = false
	spec.useVCA = false
	spec.vcaStatus = false
	
	spec.useDiffLock = true
	spec.diffStateF = false
	spec.diffStateB = false
end

function HeadlandManagement:onPostLoad(savegame)
	local spec = self.spec_HeadlandManagement
	if spec == nil then return end
	
	spec.exists = self.configurations["HeadlandManagement"] == 2
	dbgprint("onPostLoad : HLM exists: "..tostring(spec.exists))
	
	-- Check if vehicle supports CrabSteering
	local csSpec = self.spec_crabSteering
	spec.crabSteeringFound = csSpec ~= nil
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
	
	-- Check if Mod VCA exists
	spec.modVCAFound = self.vcaSetState ~= nil

	if savegame ~= nil and spec.exists then	
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".HeadlandManagement"
	
		spec.beep = Utils.getNoNil(getXMLBool(xmlFile, key.."#beep"), spec.beep)
		spec.turnSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key.."#turnSpeed"), spec.turnSpeed)
		spec.isActive = Utils.getNoNil(getXMLBool(xmlFile, key.."#isActive"), spec.isActive)
		spec.useSpeedControl = Utils.getNoNil(getXMLBool(xmlFile, key.."#useSpeedControl"), spec.useSpeedControl)
		spec.useModSpeedControl = Utils.getNoNil(getXMLBool(xmlFile, key.."#useModSpeedControl"), spec.useModSpeedControl)
		spec.useCrabSteering = Utils.getNoNil(getXMLBool(xmlFile, key.."#useCrabSteering"), spec.useCrabSteering)
		spec.useCrabSteeringTwoStep = Utils.getNoNil(getXMLBool(xmlFile, key.."#useCrabSteeringTwoStep"), spec.useCrabSteeringTwoStep)
		spec.useRaiseImplement = Utils.getNoNil(getXMLBool(xmlFile, key.."#useRaiseImplement"), spec.useRaiseImplement)
		spec.useStopPTO = Utils.getNoNil(getXMLBool(xmlFile, key.."#useStopPTO"), spec.useStopPTO)
		spec.useTurnPlow = Utils.getNoNil(getXMLBool(xmlFile, key.."#turnPlow"), spec.useTurnPlow)
		spec.useCenterPlow = Utils.getNoNil(getXMLBool(xmlFile, key.."#centerPlow"), spec.useCenterPlow)
		spec.useRidgeMarker = Utils.getNoNil(getXMLBool(xmlFile, key.."#switchRidge"), spec.useRidgeMarker)
		spec.useGPS = Utils.getNoNil(getXMLBool(xmlFile, key.."#useGPS"), spec.useGPS)
		spec.useGuidanceSteering = Utils.getNoNil(getXMLBool(xmlFile, key.."#useGuidanceSteering"), spec.useGuidanceSteering)
		spec.useGuidanceSteeringTrigger = Utils.getNoNil(getXMLBool(xmlFile, key.."#useGuidanceSteeringTrigger"), spec.useGuidanceSteeringTrigger)
		spec.useVCA = Utils.getNoNil(getXMLBool(xmlFile, key.."#useVCA"), spec.useVCA)
		spec.useDiffLock = Utils.getNoNil(getXMLBool(xmlFile, key.."#useDiffLock"), spec.useDiffLock)
		dbgprint("onPostLoad : Loaded data for "..self:getName())
	end
	
	-- Set management actions
	spec.action[HeadlandManagement.REDUCESPEED] = spec.useSpeedControl
	spec.action[HeadlandManagement.CRABSTEERING] = spec.crabSteeringFound and spec.useCrabSteering
	spec.action[HeadlandManagement.DIFFLOCK] = spec.modVCAFound and spec.useDiffLock
	spec.action[HeadlandManagement.RAISEIMPLEMENT] = spec.useRaiseImplement
	spec.action[HeadlandManagement.STOPPTO] = spec.useStopPTO
	spec.action[HeadlandManagement.STOPGPS] = (spec.modGuidanceSteeringFound and spec.useGuidanceSteering) or (spec.modVCAFound and spec.useVCA)
end

function HeadlandManagement:saveToXMLFile(xmlFile, key)
	local spec = self.spec_HeadlandManagement
	if spec.exists then
		setXMLBool(xmlFile, key.."#beep", spec.beep)
		setXMLFloat(xmlFile, key.."#turnSpeed", spec.turnSpeed)
		setXMLBool(xmlFile, key.."#isActive", spec.isActive)
		setXMLBool(xmlFile, key.."#useSpeedControl", spec.useSpeedControl)
		setXMLBool(xmlFile, key.."#useModSpeedControl", spec.useModSpeedControl)
		setXMLBool(xmlFile, key.."#useCrabSteering", spec.useCrabSteering)
		setXMLBool(xmlFile, key.."#useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
		setXMLBool(xmlFile, key.."#useRaiseImplement", spec.useRaiseImplement)
		setXMLBool(xmlFile, key.."#useStopPTO", spec.useStopPTO)
		setXMLBool(xmlFile, key.."#turnPlow", spec.useTurnPlow)
		setXMLBool(xmlFile, key.."#centerPlow", spec.useCenterPlow)
		setXMLBool(xmlFile, key.."#switchRidge", spec.useRidgeMarker)
		setXMLBool(xmlFile, key.."#useGPS", spec.useGPS)
		setXMLBool(xmlFile, key.."#useGuidanceSteering", spec.useGuidanceSteering)
		setXMLBool(xmlFile, key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
		setXMLBool(xmlFile, key.."#useVCA", spec.useVCA)
		setXMLBool(xmlFile, key.."#useDiffLock", spec.useDiffLock)
	end
end

function HeadlandManagement:onReadStream(streamId, connection)
	local spec = self.spec_HeadlandManagement
	spec.beep = streamReadBool(streamId)
	spec.turnSpeed = streamReadFloat32(streamId)
	spec.isActive = streamReadBool(streamId)
	spec.useSpeedControl = streamReadBool(streamId)
	spec.useModSpeedControl = streamReadBool(streamId)
	spec.useCrabSteering = streamReadBool(streamId)
	spec.useCrabSteeringTwoStep = streamReadBool(streamId)
	spec.useRaiseImplement = streamReadBool(streamId)
	spec.useStopPTO = streamReadBool(streamId)
	spec.useTurnPlow = streamReadBool(streamId)
	spec.useCenterPlow = streamReadBool(streamId)
  	spec.useRidgeMarker = streamReadBool(streamId)
  	spec.useGPS = streamReadBool(streamId)
  	spec.useGuidanceSteering = streamReadBool(streamId)
  	spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
  	spec.useVCA = streamReadBool(streamId)
  	spec.useDiffLock = streamReadBool(streamId)
end

function HeadlandManagement:onWriteStream(streamId, connection)
	local spec = self.spec_HeadlandManagement
	streamWriteBool(streamId, spec.beep)
	streamWriteFloat32(streamId, spec.turnSpeed)
	streamWriteBool(streamId, spec.isActive)
	streamWriteBool(streamId, spec.useSpeedControl)
	streamWriteBool(streamId, spec.useModSpeedControl)
	streamWriteBool(streamId, spec.useCrabSteering)
	streamWriteBool(streamId, spec.useCrabSteeringTwoStep)
	streamWriteBool(streamId, spec.useRaiseImplement)
	streamWriteBool(streamId, spec.useStopPTO)
	streamWriteBool(streamId, spec.useTurnPlow)
	streamWriteBool(streamId, spec.useCenterPlow)
  	streamWriteBool(streamId, spec.useRidgeMarker)
  	streamWriteBool(streamId, spec.useGPS)
  	streamWriteBool(streamId, spec.useGuidanceSteering)
  	streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
  	streamWriteBool(streamId, spec.useVCA)
  	streamWriteBool(streamId, spec.useDiffLock)
end
	
function HeadlandManagement:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_HeadlandManagement
		if streamReadBool(streamId) then
			spec.beep = streamReadBool(streamId)
			spec.turnSpeed = streamReadFloat32(streamId)
			spec.isActive = streamReadBool(streamId)
			spec.useSpeedControl = streamReadBool(streamId)
			spec.useModSpeedControl = streamReadBool(streamId)
			spec.useCrabSteering = streamReadBool(streamId)
			spec.useCrabSteeringTwoStep = streamReadBool(streamId)
			spec.useRaiseImplement = streamReadBool(streamId)
			spec.useStopPTO = streamReadBool(streamId)
			spec.useTurnPlow = streamReadBool(streamId)
			spec.useCenterPlow = streamReadBool(streamId)
			spec.useRidgeMarker = streamReadBool(streamId)
			spec.useGPS = streamReadBool(streamId)
			spec.useGuidanceSteering = streamReadBool(streamId)
			spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
			spec.useVCA = streamReadBool(streamId)
			spec.useDiffLock = streamReadBool(streamId)
		end;
	end
end

function HeadlandManagement:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_HeadlandManagement
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.beep)
			streamWriteFloat32(streamId, spec.turnSpeed)
			streamWriteBool(streamId, spec.isActive)
			streamWriteBool(streamId, spec.useSpeedControl)
			streamWriteBool(streamId, spec.useModSpeedControl)
			streamWriteBool(streamId, spec.useCrabSteering)
			streamWriteBool(streamId, spec.useCrabSteeringTwoStep)
			streamWriteBool(streamId, spec.useRaiseImplement)
			streamWriteBool(streamId, spec.useStopPTO)
			streamWriteBool(streamId, spec.useTurnPlow)
			streamWriteBool(streamId, spec.useCenterPlow)
			streamWriteBool(streamId, spec.useRidgeMarker)
			streamWriteBool(streamId, spec.useGPS)
			streamWriteBool(streamId, spec.useGuidanceSteering)
			streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
			streamWriteBool(streamId, spec.useVCA)
			streamWriteBool(streamId, spec.useDiffLock)
		end
	end
end

-- inputBindings / inputActions
	
function HeadlandManagement:onRegisterActionEvents(isActiveForInput)
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
	local spec = self.spec_HeadlandManagement
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
	local spec = self.spec_HeadlandManagement
	local hlmGui = g_gui:showDialog("HeadlandManagementGui")

	local gsConfigured = self.spec_globalPositioningSystem ~= nil and self.spec_globalPositioningSystem.hasGuidanceSystem == true
	
	hlmGui.target:setCallback(HeadlandManagement.guiCallback, self)
	hlmGui.target:setData(
		self:getFullName(),
		spec.useSpeedControl,
		spec.useModSpeedControl,
		spec.crabSteeringFound,
		spec.useCrabSteering,
		spec.useCrabSteeringTwoStep,
		spec.turnSpeed,
		spec.useRaiseImplement,
		spec.useStopPTO,
		spec.useTurnPlow,
		spec.useCenterPlow,
		spec.useRidgeMarker,
		spec.useGPS,
		spec.gpsSetting,
		spec.useGuidanceSteering,
		spec.useGuidanceSteeringTrigger,
		spec.useVCA,
		spec.useDiffLock,
		spec.beep,
		spec.modSpeedControlFound,
		spec.modGuidanceSteeringFound and gsConfigured,
		spec.modVCAFound
	)
end

function HeadlandManagement:guiCallback(
		useSpeedControl, 
		useModSpeedControl, 
		useCrabSteering, 
		useCrabSteeringTwoStep, 
		turnSpeed, 
		useRaiseImplement, 
		useStopPTO, 
		useTurnPlow, 
		useCenterPlow, 
		useRidgeMarker, 
		useGPS, 
		gpsSetting, 
		useGuidanceSteering, 
		useGuidanceSteeringTrigger, 
		useVCA, 
		useDiffLock, 
		beep
	)
	local spec = self.spec_HeadlandManagement
	spec.useSpeedControl = useSpeedControl
	spec.useModSpeedControl = useModSpeedControl
	spec.useCrabSteering = useCrabSteering
	spec.useCrabSteeringTwoStep = useCrabSteeringTwoStep
	spec.turnSpeed = turnSpeed
	spec.useRaiseImplement = useRaiseImplement
	spec.useStopPTO = useStopPTO
	spec.useTurnPlow = useTurnPlow
	spec.useCenterPlow = useCenterPlow
	spec.useRidgeMarker = useRidgeMarker
	spec.useGPS = useGPS
	spec.gpsSetting = gpsSetting
	spec.useGuidanceSteering = useGuidanceSteering
	spec.useGuidanceSteeringTrigger = useGuidanceSteeringTrigger
	spec.useVCA = useVCA
	spec.useDiffLock = useDiffLock
	spec.beep = beep
	self:raiseDirtyFlags(spec.dirtyFlag)
end

-- Main part

function HeadlandManagement:onUpdate(dt)
	local spec = self.spec_HeadlandManagement
	
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and spec.beep and spec.isActive then
		spec.timer = spec.timer + dt
		if spec.timer > 2000 then 
			playSample(HeadlandManagement.BEEPSOUND, 1, 0.5, 0, 0, 0)
			spec.timer = 0
		end	
	else
		spec.timer = 0
	end
	
	if self:getIsActive() and spec.exists and spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger then
		local gsSpec = self.spec_globalPositioningSystem
		if not spec.isActive and gsSpec.playHeadLandWarning then
			spec.isActive = true
		end
	end
	
	if self:getIsActive() and spec.isActive and spec.exists and spec.actStep<spec.maxStep then
		if spec.action[math.abs(spec.actStep)] and not HeadlandManagement.isDedi then
			dbgprint("onUpdate : actStep: "..tostring(spec.actStep))
			-- Set management actions
			spec.action[HeadlandManagement.REDUCESPEED] = spec.useSpeedControl
			spec.action[HeadlandManagement.CRABSTEERING] = spec.crabSteeringFound and spec.useCrabSteering
			spec.action[HeadlandManagement.DIFFLOCK] = spec.modVCAFound and spec.useDiffLock
			spec.action[HeadlandManagement.RAISEIMPLEMENT] = spec.useRaiseImplement
			spec.action[HeadlandManagement.STOPPTO] = spec.useStopPTO
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
end

function HeadlandManagement:onDraw(dt)
	local spec = self.spec_HeadlandManagement

	if self:getIsActive() and spec.isActive and spec.exists then 
		g_currentMission:addExtraPrintText(g_i18n:getText("text_HLM_isActive"))
	 
		local scale = g_gameSettings.uiScale
		
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX * 0.70
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY
		local w = 0.015 * scale
		local h = w * g_screenAspectRatio
		
		renderOverlay(HeadlandManagement.guiIcon, x, y, w, h)
	end
	if self:getIsActive() and spec.exists and spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger and not spec.isActive then
		local gsSpec = self.spec_globalPositioningSystem 
		local gpsEnabled = (gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive)
		
		if gpsEnabled then
			local scale = g_gameSettings.uiScale
		
			local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX * 0.70
			local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY
			local w = 0.015 * scale
			local h = w * g_screenAspectRatio
		
			renderOverlay(HeadlandManagement.guiAuto, x, y, w, h)
		end
	end
end
	
function HeadlandManagement:reduceSpeed(self, enable)	
	local spec = self.spec_HeadlandManagement
	dbgprint("reduceSpeed : "..tostring(enable))
	if enable then
		if spec.modSpeedControlFound and spec.useModSpeedControl and self.speedControl ~= nil then
			spec.normSpeed = self.speedControl.currentKey or 2
			dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.turnSpeed))
			SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.turnSpeed), true, false, false)
		else
			spec.normSpeed = self:getCruiseControlSpeed()
			self:setCruiseControlMaxSpeed(spec.turnSpeed)
			dbgprint("reduceSpeed : Set cruise control to "..tostring(spec.turnSpeed))
		end
	else
		if spec.modSpeedControlFound and spec.useModSpeedControl then
			dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.normSpeed))
			SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.normSpeed), true, false, false)
		else
			self:setCruiseControlMaxSpeed(spec.normSpeed)
			dbgprint("reduceSpeed : Set cruise control back to "..tostring(spec.normSpeed))
		end
	end
end

function HeadlandManagement:crabSteering(self, enable, twoSteps)
	local spec = self.spec_HeadlandManagement
	local csSpec = self.spec_crabSteering
	local stateMax = csSpec.stateMax
	local state = csSpec.state
	local newState = 1
	dbgprint("crabSteering : "..tostring(enable))
	if enable then
		local csMode = 0
		if csSpec.steeringModes ~= nil and csSpec.steeringModes[state].wheels ~= nil and csSpec.steeringModes[state].wheels[1].offset ~= nil then
			csMode = csSpec.steeringModes[state].wheels[1].offset
		end
		-- CrabSteering active? Find opposite state
		if csMode ~= 0 then
			for i=1,stateMax do
				local testMode = csSpec.steeringModes[i].wheels[1].offset
				if testMode == -csMode then 
					newState = i
				end
			end
			if twoSteps then
				csSpec:setCrabSteering(1)
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
		if spec.useRaiseImplement and actImplement ~= nil and actImplement.getAllowsLowering ~= nil then
			dbgprint("raiseImplements : actImplement: "..actImplement:getName())
			if actImplement:getAllowsLowering() or actImplement.spec_pickup ~= nil or actImplement.spec_foldable ~= nil then
				local jointDesc = actImplement:getActiveInputAttacherJointDescIndex()
				if raise then
					local lowered = actImplement:getIsLowered()
					dbgprint("raiseImplements : lowered starts with "..tostring(lowered))
					local wasLowered = lowered
					spec.implementStatusTable[index] = wasLowered
					if lowered and self.setJointMoveDown ~= nil then
		 				self:setJointMoveDown(jointDesc, false)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is raised by setJointMoveDown: "..tostring(not lowered))
		 			end
					if lowered and actImplement.setLoweredAll ~= nil then 
						actImplement:setLoweredAll(false, jointDesc)
						lowered = actImplement:getIsLowered()
						dbgprint("raiseImplements : implement is raised by setLoweredAll: "..tostring(not lowered))
		 			end
		 			if lowered and actImplement.setLowered ~= nil then
		 				actImplement:setLowered(false)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is raised by setLowered: "..tostring(not lowered))
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
		 			local plowSpec = actImplement.spec_plow
		 			if plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and wasLowered and spec.plowRotationMaxNew ~= nil then 
						actImplement:setRotationMax(spec.plowRotationMaxNew)
						spec.plowRotationMaxNew = nil
						dbgprint("raiseImplements : plow is turned")
					end
					if wasLowered and self.setJointMoveDown ~= nil then
		 				self:setJointMoveDown(jointDesc, true)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is lowered by setJointMoveDown: "..tostring(lowered))
		 			end
					if wasLowered and not lowered and actImplement.setLoweredAll ~= nil then
		 				actImplement:setLoweredAll(true, jointDesc)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is lowered by setLoweredAll: "..tostring(lowered))
		 			end
		 			if wasLowered and not lowered and actImplement.setLowered ~= nil then
		 				actImplement:setLowered(true)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is lowered by setLowered: "..tostring(lowered))
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
		-- switch ridge marker
		if spec.useRidgeMarker and actImplement ~= nil and actImplement.spec_ridgeMarker ~= nil then
			local specRM = actImplement.spec_ridgeMarker
			if raise then
				spec.ridgeMarkerStatus = specRM.ridgeMarkerState
				if spec.ridgeMarkerStatus ~= 0 then
					actImplement:setRidgeMarkerState(0)
				end
			else
				if spec.ridgeMarkerStatus == 1 then 
					spec.ridgeMarkerStatus = 2 
				elseif spec.ridgeMarkerStatus == 2 then
		  			spec.ridgeMarkerStatus = 1
				end
				actImplement:setRidgeMarkerState(spec.ridgeMarkerStatus)
			end
			dbgprint("ridgeMarker: "..tostring(specRM.ridgeMarkerState))
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
		dbgprint("stopPTO : actImplement: "..actImplement:getName())
		if stopPTO then
			local active = actImplement.getIsPowerTakeOffActive ~= nil and actImplement:getIsPowerTakeOffActive()
			spec.implementPTOTable[index] = active
			if active and actImplement.setIsTurnedOn ~= nil then 
				actImplement:setIsTurnedOn(false)
				dbgprint("raiseImplements : implement PTO stopped by setIsTurnedOn")
			elseif active and actImplement.deactivate ~= nil then
				actImplement:deactivate()
				dbgprint("raiseImplements : implement PTO stopped by deactivate")
			end
		else
			local active = spec.implementPTOTable[index]
			if active and actImplement.setIsTurnedOn ~= nil then 
				actImplement:setIsTurnedOn(true) 
				dbgprint("raiseImplements : implement PTO stopped by setIsTurnedOn")
			elseif active and actImplement.activate ~= nil then
				actImplement:activate()
				dbgprint("raiseImplements : implement PTO stopped by activate")
			end
			dbgprint("raiseImplements : implement PTO started")
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
