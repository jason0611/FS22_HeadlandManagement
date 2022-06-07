--
-- Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 2.1.1.7 beta
--
-- Make Headland Detection independent from other mods like GS
-- Two nodes: front node + back node
-- Adapt front/back nodes, if implement is being attached or detached
-- Detect, if turn has ended --> Headland Management with automatic field mode
-- Separate raising of front and back implement, each when reaching headland
-- Enable manual override of trigger controlled actions
-- Turn Headland Management on/off
-- Option to temporary disable headland automatic by key
-- Auto-Resume if trigger leaves headland area
-- Save configuration locally with implement-type
-- Headland Management configured into mission vehicles
 
HeadlandManagement = {}

if HeadlandManagement.MOD_NAME == nil then HeadlandManagement.MOD_NAME = g_currentModName end
HeadlandManagement.MODSETTINGSDIR = g_currentModSettingsDirectory

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(HeadlandManagement.MOD_NAME, true, 2)
GMSDebug:enableConsoleCommands("hlmDebug")

source(g_currentModDirectory.."gui/HeadlandManagementGui.lua")
g_gui:loadGui(g_currentModDirectory.."gui/HeadlandManagementGui.xml", "HeadlandManagementGui", HeadlandManagementGui:new())

HeadlandManagement.REDUCESPEED = 1
HeadlandManagement.WAITTIME1 = 2
HeadlandManagement.CRABSTEERING = 3
HeadlandManagement.DIFFLOCK = 4
HeadlandManagement.RAISEIMPLEMENT1 = 5
HeadlandManagement.WAITONTRIGGER = 6
HeadlandManagement.RAISEIMPLEMENT2 = 7
HeadlandManagement.WAITTIME2 = 8
HeadlandManagement.WAITTIME3 = 8
HeadlandManagement.TURNPLOW = 9
HeadlandManagement.STOPPTO = 10
HeadlandManagement.STOPGPS = 11
HeadlandManagement.MAXSTEP = 12

HeadlandManagement.debug = false

HeadlandManagement.BEEPSOUND = createSample("HLMBEEP")
loadSample(HeadlandManagement.BEEPSOUND, g_currentModDirectory.."sound/beep.ogg", false)

HeadlandManagement.sideInfo = SideNotification.new(nil, "dataS/menu/hud/hud_elements.png")

HeadlandManagement.guiIconOff = createImageOverlay(g_currentModDirectory.."gui/hlm_off.dds")
HeadlandManagement.guiIconField = createImageOverlay(g_currentModDirectory.."gui/hlm_field_normal.dds")
HeadlandManagement.guiIconFieldR = createImageOverlay(g_currentModDirectory.."gui/hlm_field_right.dds")
HeadlandManagement.guiIconFieldL = createImageOverlay(g_currentModDirectory.."gui/hlm_field_left.dds")
HeadlandManagement.guiIconFieldLR = createImageOverlay(g_currentModDirectory.."gui/hlm_field_leftright.dds")
HeadlandManagement.guiIconFieldA = createImageOverlay(g_currentModDirectory.."gui/hlm_field_auto_normal.dds")
HeadlandManagement.guiIconFieldAR = createImageOverlay(g_currentModDirectory.."gui/hlm_field_auto_right.dds")
HeadlandManagement.guiIconFieldAL = createImageOverlay(g_currentModDirectory.."gui/hlm_field_auto_left.dds")
HeadlandManagement.guiIconFieldALR = createImageOverlay(g_currentModDirectory.."gui/hlm_field_auto_leftright.dds")
HeadlandManagement.guiIconFieldW = createImageOverlay(g_currentModDirectory.."gui/hlm_field_working.dds")
HeadlandManagement.guiIconFieldGS = createImageOverlay(g_currentModDirectory.."gui/hlm_field_gs.dds")
HeadlandManagement.guiIconFieldEV = createImageOverlay(g_currentModDirectory.."gui/hlm_field_ev.dds")
HeadlandManagement.guiIconHeadland = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_normal.dds")
HeadlandManagement.guiIconHeadlandA = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_auto_normal.dds")
HeadlandManagement.guiIconHeadlandW = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_working.dds")
HeadlandManagement.guiIconHeadlandEV = createImageOverlay(g_currentModDirectory.."gui/hlm_headland_ev.dds")

-- Filteres implements
HeadlandManagement.filterList = {}
HeadlandManagement.filterList[1] = "E-DriveLaner"

-- Killbits for not yet published mods
HeadlandManagement.kbVCA = false
HeadlandManagement.kbGS = false
HeadlandManagement.kbSC = false
HeadlandManagement.kbEV = false

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
    	dbgprint_r(configurations["HeadlandManagement"], 4)
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
	dbgprint("initSpecialization: starting xmlSchemaSavegame registration process", 1)
	
	local schemaKey = HeadlandManagement.MOD_NAME..".HeadlandManagement"
	
	-- register new and old schema for backwarts compatibility reasons
	for _, key in pairs({schemaKey,"HeadlandManagement"}) do
 		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#configured", "HLM configured", false)
	    	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#isOn", "HLM is turned on", false)
    
	    	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#beep", "Audible alert", true)
	    	schemaSavegame:register(XMLValueType.INT,  "vehicles.vehicle(?)."..key.."#beepVol", "Audible alert volume", 5)
	
		schemaSavegame:register(XMLValueType.FLOAT,"vehicles.vehicle(?)."..key.."#turnSpeed", "Speed in headlands", 5)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useSpeedControl", "Change speed in headlands", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useModSpeedControl", "use mod SpeedControl", false)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useCrabSteering", "Change crab steering in headlands", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useCrabSteeringTwoStep", "Changecrab steering over turn config", true)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useRaiseImplementF", "Raise front attachements in headlands", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useRaiseImplementB", "Raise back attahements in headlands", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#waitOnTrigger", "Raise back attachements when reaching position of front implement's raise", false)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useStopPTOF", "Stop front PTO in headlands", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useStopPTOB", "Stop back PTO in headlands", true)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#turnPlow", "Turn plow in headlands", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#centerPlow", "Center plow first in headlands", false)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#switchRidge", "Change ridgemarkers", true)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useGPS", "Change GPS", true)
		schemaSavegame:register(XMLValueType.INT,  "vehicles.vehicle(?)."..key.."#gpsSetting", "GPS-Mode", 1)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#vcaDirSwitch", "Switch vca-turn", true)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#autoResume", "Auto resume field mode after turn", false)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useGuidanceSteeringTrigger", "Use headland automatic of GS", false)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useGuidanceSteeringOffset", "Use back trigger", false)
		
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useEVTrigger", "Use headland automatic of EV", false)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useHLMTriggerF", "Use HLM trigger with front node", false)
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useHLMTriggerB", "Use HLM trigger with back node", false)
		schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)."..key.."#headlandDistance", "Distance to headland", 9)
	
		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#useDiffLock", "Unlock diff locks in headland", true)
		dbgprint("initSpecialization: finished xmlSchemaSavegame registration process for schema "..key, 1)
	end
		dbgprint("initSpecialization: finished xmlSchemaSavegame registration process", 1)
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
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", HeadlandManagement) 
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", HeadlandManagement) 
end

function HeadlandManagement:onLoad(savegame)
	dbgprint("onLoad", 2)

	HeadlandManagement.isDedi = g_server ~= nil and g_currentMission.connectedToDedicatedServer
	
	-- Make Specialization easier accessible
	self.spec_HeadlandManagement = self["spec_"..HeadlandManagement.MOD_NAME..".HeadlandManagement"]
	
	local spec = self.spec_HeadlandManagement
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	spec.exists = false				-- Headland Management is configured into vehicle
	spec.isOn = false				-- Headland Management is switched on
	
	spec.timer = 0					-- Timer for waiting actions
	spec.beep = true				-- Beep on or off
	spec.beepVol = 5				-- Beep volume setting
	
	spec.normSpeed = 20				-- working speed on field
	spec.turnSpeed = 5				-- working speed on headland

	spec.actStep = 0				-- actual step in process chain
	
	spec.isActive = false			-- Headland Management in headland mode (active) or field mode (inactive)
	spec.action = {}				-- switches for process chain
	spec.action[0] =false
	
	spec.useSpeedControl = true		-- change working speed n headland
	spec.modSpeedControlFound = false	-- is mod 'FS22_zzzSpeedControl' existing?
	spec.useModSpeedControl = false	-- use mod 'FS22_xxxSpeedControl'
	
	spec.useHLMTriggerF = false 	-- use vehicle's front node as trigger
	spec.useHLMTriggerB = false 	-- use vehicle's back node as trigger
	spec.headlandDistance = 9 		-- headland width (distance to field border)	-- needs config settings	 
	spec.headlandF = false			-- front node over headland?
	spec.headlandB = false 			-- back node over headland?
	spec.lastHeadlandF = false		-- was front node already over headland?
	spec.lastHeadlandB = false		-- was back node already over headland?
	
	spec.useRaiseImplementF = true	-- raise front implements in headland mode
	spec.useRaiseImplementB = true	-- raise back implements in headland mode
	spec.implementStatusTable = {}	-- table of implement's state (lowered on field?)
	spec.implementPTOTable = {}		-- table of implement's pto state on field
	spec.useStopPTOF = true			-- stop front pto in headland mode
	spec.useStopPTOB = true			-- stop back pto in headland mode
	spec.waitTime = 0				-- time to wait for animations to finish
	spec.waitOnTrigger = false 		-- wait until vehicle has moved to trigger point before raising back implements
	spec.useTurnPlow = true			-- turn plow in headland mode
	spec.useCenterPlow = true		-- turn plow in two steps
	spec.plowRotationMaxNew = nil	-- plow state while turning
	spec.vehicleLength = 0			-- calculated vehicle's length
	spec.vehicleWidth = 0			-- vehicle's width
	spec.maxTurningRadius = 0		-- vehicle's turn radius
	spec.autoOverride = false		-- temporary override of headland automatic
	
	spec.useRidgeMarker = true		-- switch ridge markers in headland mode
	spec.ridgeMarkerState = 0		-- state of ridge markers on field
	
	spec.crabSteeringFound = false	-- vehicle has crab steering feature
	spec.useCrabSteering = true		-- change crab steering in headland mode
	spec.useCrabSteeringTwoStep = true -- change crab steering to AI driver position in headland mode
	
	spec.useGPS = true				-- control gps in headland mode
	spec.gpsSetting = 1 			-- 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right, 6: ev-mode
	spec.wasGPSAutomatic = false	-- was headland automatic active on field?
	
	spec.modGuidanceSteeringFound = false
	spec.useGuidanceSteeringTrigger = false	
	spec.useGuidanceSteeringOffset = false
	spec.guidanceSteeringOffset = 0
	spec.setServerHeadlandActDistance = -1
	spec.GSStatus = false
	
	spec.modVCAFound = false
	spec.vcaStatus = false
	spec.vcaDirSwitch = true
	spec.autoResume = false 
	spec.autoResumeOnTrigger = false
	
	spec.modEVFound = false
	spec.useEVTrigger = false
	
	spec.useDiffLock = true
	spec.diffStateF = false
	spec.diffStateB = false
	
	spec.debugFlag = false			-- shows green flag for triggerNode and red flag for vehicle's measure node
end

-- Detect outmost frontNode and outmost backNode by considering vehicle's attacherJoints and known workAreas
local function vehicleMeasurement(self, excludedImplement)
	local frontNode, backNode
	local vehicleLength, vehicleWidth, maxTurningRadius = 0, 0, 0
	local distFront, distBack, lastFront, lastBack = 0, 0, 0, 0		
	local frontExists, backExists
	local lengthBackup, tmpLen = 0, 0

	local allImplements = self:getRootVehicle():getChildVehicles()
	dbgprint("vehicleMeasurement : #allImplements = "..tostring(#allImplements), 2)

	-- the to-be-detached implement is still connected, so we have to exclude it and it's children from calculation of vehicle's length
	local excludedChilds = {}
	if excludedImplement ~= nil and excludedImplement.getFullName ~= nil then 
		dbgprint("vehicleMeasurement : excludedImplement: "..excludedImplement:getFullName(), 2)
		if excludedImplement.getChildVehicles ~= nil then excludedChilds = excludedImplement:getChildVehicles() end
	end
	
	for _,implement in pairs(allImplements) do
		if implement ~= nil then 
			
			local filtered = false
			for _,filterName in pairs(HeadlandManagement.filterList) do
				if implement.getName ~= nil and implement:getName() == filterName then filtered = true end
			end
			if implement == excludedImplement then filtered = true end
			for _,excludedChild in pairs(excludedChilds) do 
				if implement == excludedChild then filtered = true end
			end
			
			local spec_at = implement.spec_attacherJoints
			
			if implement.getName ~= nil then dbgprint("vehicleMeasurement : implement: "..implement:getName()) end
			
			local implTurningRadius = implement.maxTurningRadius
			if implTurningRadius ~= nil then maxTurningRadius = math.max(maxTurningRadius, implTurningRadius) end
			dbgprint("vehicleMeasurement : maxTurningRadius: "..tostring(maxTurningRadius), 2)
			
			if implement.size ~= nil then 
				dbgprint("vehicleMeasurement : width: "..tostring(implement.size.width))
				dbgprint("vehicleMeasurement : length: "..tostring(implement.size.length)) 
				lengthBackup = lengthBackup + implement.size.length
				vehicleWidth = math.max(vehicleWidth, implement.size.width)
			end
			
			if not filtered and spec_at ~= nil then
				for index,joint in pairs(spec_at.attacherJoints) do
					local wx, wy, wz = getWorldTranslation(joint.jointTransform)
					local lx, ly, lz = worldToLocal(self.rootNode, wx, wy, wz)
					lastFront, lastBack = distFront, distBack
					distFront, distBack = math.max(distFront, lz), math.min(distBack, lz)
					if distFront ~= lastFront then 
						frontExists = true
						frontNode = joint.jointTransform
						dbgprint("vehicleMeasurement joint "..tostring(index)..": New frontNode set", 2) 
					end
					if distBack ~= lastBack then 
						backExists = true
						backNode = joint.jointTransform 
						dbgprint("vehicleMeasurement joint "..tostring(index)..": New backNode set", 2) 
					end
			
					tmpLen = math.floor(math.abs(distFront) + math.abs(distBack) + 0.5)
					dbgprint("vehicleMeasurement joint "..tostring(index)..": new distFront: "..tostring(distFront), 2)
					dbgprint("vehicleMeasurement joint "..tostring(index)..": new distBack: "..tostring(distBack), 2)
					dbgprint("vehicleMeasurement joint "..tostring(index)..": new vehicleLength: "..tostring(tmpLen), 2)
				end
			else
				dbgprint("vehicleMeasurement: filtered or no attacherJoint", 2)
			end

			local spec_wa = implement.spec_workArea
			if not filtered and spec_wa ~= nil and spec_wa.workAreas ~= nil then
				local waWidth = 0
				local maxX, minX = 0, 0
				for index, workArea in pairs(spec_wa.workAreas) do
					if workArea.start ~= nil then
						local testNode = workArea.start
						local widthNode = workArea.width
						local wx, wy, wz = getWorldTranslation(testNode)
						local lx, ly, lz = worldToLocal(self.rootNode, wx, wy, wz)
		
						local wwx, wwy, wwz = getWorldTranslation(widthNode)
						local lwx, lwy, lwz = worldToLocal(self.rootNode, wwx, wwy, wwz)
						maxX = math.max(maxX, math.max(lwx, lx))
						minX = math.min(minX, math.min(lwx, lx))
						waWidth = math.abs(maxX - minX)
						lastFront, lastBack = distFront, distBack
						distFront, distBack = math.max(distFront, lz), math.min(distBack, lz)
						if lastFront ~= distFront then 
							frontExists = true
							frontNode = testNode; 
							dbgprint("vehicleMeasurement workArea "..tostring(index)..": New frontNode set", 2) 
						end
						if lastBack ~= distBack then
							backExists = true 
							backNode = testNode; 
							dbgprint("vehicleMeasurement workArea "..tostring(index)..": New backNode set", 2) 
						end
					end
					tmpLen = math.floor(math.abs(distFront) + math.abs(distBack) + 0.5)
					dbgprint("vehicleMeasurement workArea "..tostring(index)..": new distFront: "..tostring(distFront), 2)
					dbgprint("vehicleMeasurement workArea "..tostring(index)..": new distBack: "..tostring(distBack), 2)
					dbgprint("vehicleMeasurement workArea "..tostring(index)..": new vehicleLength: "..tostring(tmpLen), 2)
				end
				vehicleWidth = math.max(vehicleWidth, waWidth)
				dbgprint("vehicleMeasurement workArea: new vehicleWidth: "..tostring(vehicleWidth), 2)
			else
				dbgprint("vehicleMeasurement: filtered or no workArea", 2)
			end
		else
			dbgprint("vehicleMeasurement: implement == nil", 2)
		end
	end	
	if frontExists and backExists then
		vehicleLength = math.floor(math.abs(distFront) + math.abs(distBack) + 0.5)
	else
		vehicleLength = lengthBackup
	end
	dbgprint("vehicleMeasurement : distFront: "..tostring(distFront), 2)
	dbgprint("vehicleMeasurement : distBack: "..tostring(distBack), 2)
	dbgprint("vehicleMeasurement : vehicleLength: "..tostring(vehicleLength), 1)
	dbgprint("vehicleMeasurement : vehicleWidth: "..tostring(vehicleWidth), 1)
	return frontNode, backNode, vehicleLength, vehicleWidth, maxTurningRadius
end

function HeadlandManagement:onPostLoad(savegame)
	dbgprint("onPostLoad: "..self:getFullName(), 2)
	local spec = self.spec_HeadlandManagement
	if spec == nil then return end
	
	-- Check if vehicle supports CrabSteering
	local csSpec = self.spec_crabSteering
	spec.crabSteeringFound = csSpec ~= nil and csSpec.stateMax ~= nil and csSpec.stateMax > 0
	dbgprint("onPostLoad : CrabSteering exists: "..tostring(spec.crabSteeringFound), 1)
	
	-- Check if Mod SpeedControl exists
	if FS22_SpeedControl ~= nil and FS22_SpeedControl.SpeedControl ~= nil and FS22_SpeedControl.SpeedControl.onInputAction ~= nil and not HeadlandManagement.kbSC then 
		spec.modSpeedControlFound = true 
		spec.useModSpeedControl = true
		spec.turnSpeed = 1 --SpeedControl Mode 1
		spec.normSpeed = 2 --SpeedControl Mode 2
	end
	
	-- Check if Mod GuidanceSteering exists
	spec.modGuidanceSteeringFound = self.spec_globalPositioningSystem ~= nil and not HeadlandManagement.kbGS

	-- Check if Mod VCA exists
	spec.modVCAFound = self.vcaSetState ~= nil and not HeadlandManagement.kbVCA
	
	-- Check if Mod EV exists
	spec.modEVFound = FS22_EnhancedVehicle ~= nil and FS22_EnhancedVehicle.FS22_EnhancedVehicle ~= nil and FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall ~= nil and not HeadlandManagement.kbEV
	
	dbgprint("modEVFound is "..tostring(spec.modEVFound).."("..tostring(modEVFound).."/"..tostring(modEVEnabled)..")")

	-- HLM configured?
	spec.exists = self.configurations["HeadlandManagement"] ~= nil and self.configurations["HeadlandManagement"] > 1
	
	if savegame ~= nil then	
		dbgprint("onPostLoad : loading saved data", 2)
		local xmlFile = savegame.xmlFile
		local key = savegame.key .."."..HeadlandManagement.MOD_NAME..".HeadlandManagement"
		local keyOld = savegame.key..".HeadlandManagement"
		spec.exists = xmlFile:getValue(key.."#configured", spec.exists)
		if not spec.exists then
			-- Old savegame from version before 1.4.0.0? Load from old schema path!
			spec.exists = xmlFile:getValue(keyOld.."#configured", spec.exists)
			if spec.exists then key = keyOld end
		end
		if spec.exists then
			spec.isOn = xmlFile:getValue(key.."#isOn", spec.isOn)
			spec.beep = xmlFile:getValue(key.."#beep", spec.beep)
			spec.beepVol = xmlFile:getValue(key.."#beepVol", spec.beepVol)
			spec.turnSpeed = xmlFile:getValue(key.."#turnSpeed", spec.turnSpeed)
			spec.useSpeedControl = xmlFile:getValue(key.."#useSpeedControl", spec.useSpeedControl)
			spec.useModSpeedControl = xmlFile:getValue(key.."#useModSpeedControl", spec.useModSpeedControl)
			spec.useCrabSteering = xmlFile:getValue(key.."#useCrabSteering", spec.useCrabSteering)
			spec.useCrabSteeringTwoStep = xmlFile:getValue(key.."#useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
			spec.useRaiseImplementF = xmlFile:getValue(key.."#useRaiseImplementF", spec.useRaiseImplementF)
			spec.useRaiseImplementB = xmlFile:getValue(key.."#useRaiseImplementB", spec.useRaiseImplementB)
			spec.waitOnTrigger = xmlFile:getValue(key.."#waitOnTrigger", spec.waitOnTrigger)
			spec.useStopPTOF = xmlFile:getValue(key.."#useStopPTOF", spec.useStopPTOF)
			spec.useStopPTOB = xmlFile:getValue(key.."#useStopPTOB", spec.useStopPTOB)
			spec.useTurnPlow = xmlFile:getValue(key.."#turnPlow", spec.useTurnPlow)
			spec.useCenterPlow = xmlFile:getValue(key.."#centerPlow", spec.useCenterPlow)
			spec.useRidgeMarker = xmlFile:getValue(key.."#switchRidge", spec.useRidgeMarker)
			spec.useGPS = xmlFile:getValue(key.."#useGPS", spec.useGPS)
			spec.gpsSetting = xmlFile:getValue(key.."#gpsSetting", spec.gpsSetting)
			spec.useGuidanceSteeringTrigger = xmlFile:getValue(key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
			spec.useGuidanceSteeringOffset = xmlFile:getValue(key.."#useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
			spec.useEVTrigger = xmlFile:getValue(key.."#useEVTrigger", spec.useEVTrigger) and spec.modEVFound
			spec.useHLMTriggerF = xmlFile:getValue(key.."#useHLMTriggerF", spec.useHLMTriggerF)
			spec.useHLMTriggerB = xmlFile:getValue(key.."#useHLMTriggerB", spec.useHLMTriggerB)
			spec.headlandDistance = xmlFile:getValue(key.."#headlandDistance", spec.headlandDistance)
			spec.vcaDirSwitch = xmlFile:getValue(key.."#vcaDirSwitch", spec.vcaDirSwitch)
			spec.autoResume = xmlFile:getValue(key.."#autoResume", spec.autoResume)	
			spec.useDiffLock = xmlFile:getValue(key.."#useDiffLock", spec.useDiffLock)
			dbgprint("onPostLoad : Loaded whole data set using key "..key, 1)
		end
		dbgprint("onPostLoad : Loaded data for "..self:getName(), 1)
	end
	
	-- enable HLM in mission vehicles
	spec.exists = spec.exists or (self.configurations["HeadlandManagement"] ~= nil and self.propertyState == Vehicle.PROPERTY_STATE_MISSION)
	
	if spec.gpsSetting == 2 and not spec.modGuidanceSteeringFound then spec.gpsSetting = 1 end
	if spec.gpsSetting > 2 and spec.gpsSetting < 6 and not spec.modVCAFound then spec.gpsSetting = 1 end
	if spec.gpsSetting > 5 and not spec.modEVFound then spec.gpsSetting = 1 end
	
	spec.autoResumeOnTrigger = spec.autoResume and (spec.useHLMTriggerF or spec.useHLMTriggerB)
	
	if spec.exists then
		-- Detect frontNode, backNode and calculate vehicle length and width
		spec.frontNode, spec.backNode, spec.vehicleLength, spec.vehicleWidth, spec.maxTurningRadius = vehicleMeasurement(self)
		spec.guidanceSteeringOffset = spec.vehicleLength
		dbgprint("onPostLoad : length: "..tostring(spec.vehicleLength), 1)
		dbgprint("onPostLoad : frontNode: "..tostring(spec.frontNode), 2)
		dbgprint("onPostLoad : backNode: "..tostring(spec.backNode), 2)
	end
	
	-- Set HLM configuration if set by savegame
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
		xmlFile:setValue(key.."#isOn", spec.isOn)
		xmlFile:setValue(key.."#beep", spec.beep)
		xmlFile:setValue(key.."#beepVol", spec.beepVol)
		xmlFile:setValue(key.."#turnSpeed", spec.turnSpeed)
		xmlFile:setValue(key.."#useSpeedControl", spec.useSpeedControl)
		xmlFile:setValue(key.."#useModSpeedControl", spec.useModSpeedControl)
		xmlFile:setValue(key.."#useCrabSteering", spec.useCrabSteering)
		xmlFile:setValue(key.."#useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
		xmlFile:setValue(key.."#useRaiseImplementF", spec.useRaiseImplementF)
		xmlFile:setValue(key.."#useRaiseImplementB", spec.useRaiseImplementB)
		xmlFile:setValue(key.."#waitOnTrigger", spec.waitOnTrigger)
		xmlFile:setValue(key.."#useStopPTOF", spec.useStopPTOF)
		xmlFile:setValue(key.."#useStopPTOB", spec.useStopPTOB)
		xmlFile:setValue(key.."#turnPlow", spec.useTurnPlow)
		xmlFile:setValue(key.."#centerPlow", spec.useCenterPlow)
		xmlFile:setValue(key.."#switchRidge", spec.useRidgeMarker)
		xmlFile:setValue(key.."#useGPS", spec.useGPS)
		xmlFile:setValue(key.."#gpsSetting", spec.gpsSetting)
		xmlFile:setValue(key.."#useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
		xmlFile:setValue(key.."#useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
		xmlFile:setValue(key.."#useEVTrigger", spec.useEVTrigger)
		xmlFile:setValue(key.."#useHLMTriggerF", spec.useHLMTriggerF)
		xmlFile:setValue(key.."#useHLMTriggerB", spec.useHLMTriggerB)
		xmlFile:setValue(key.."#headlandDistance", spec.headlandDistance)
		xmlFile:setValue(key.."#vcaDirSwitch", spec.vcaDirSwitch)
		xmlFile:setValue(key.."#autoResume", spec.autoResume)
		xmlFile:setValue(key.."#useDiffLock", spec.useDiffLock)
		
		dbgprint("saveToXMLFile : saving whole data", 2)
	end
	dbgprint("saveToXMLFile : saving data finished", 2)
end

function HeadlandManagement:onReadStream(streamId, connection)
	dbgprint("onReadStream", 3)
	local spec = self.spec_HeadlandManagement
	spec.exists = streamReadBool(streamId, connection)
	if spec.exists then
		spec.isOn = streamReadBool(streamId)
		spec.beep = streamReadBool(streamId)
		spec.beepVol = streamReadInt8(streamId)
		spec.turnSpeed = streamReadFloat32(streamId)
		spec.useSpeedControl = streamReadBool(streamId)
		spec.useModSpeedControl = streamReadBool(streamId)
		spec.useCrabSteering = streamReadBool(streamId)
		spec.useCrabSteeringTwoStep = streamReadBool(streamId)
		spec.useRaiseImplementF = streamReadBool(streamId)
		spec.useRaiseImplementB = streamReadBool(streamId)
		spec.waitOnTrigger = streamReadBool(streamId)
		spec.useStopPTOF = streamReadBool(streamId)
		spec.useStopPTOB = streamReadBool(streamId)
		spec.useTurnPlow = streamReadBool(streamId)
		spec.useCenterPlow = streamReadBool(streamId)
		spec.useRidgeMarker = streamReadBool(streamId)
		spec.useGPS = streamReadBool(streamId)
		spec.gpsSetting = streamReadInt8(streamId)
		spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
		spec.useGuidanceSteeringOffset = streamReadBool(streamId)
		spec.useEVTrigger = streamReadBool(streamId)
		spec.useHLMTriggerF = streamReadBool(streamId)
		spec.useHLMTriggerB = streamReadBool(streamId)
		spec.headlandDistance = streamReadInt8(streamId)
		spec.vcaDirSwitch = streamReadBool(streamId)
		spec.autoResume = streamReadBool(streamId)
		spec.autoResumeOnTrigger = streamReadBool(streamId)
		spec.useDiffLock = streamReadBool(streamId)
	end
end

function HeadlandManagement:onWriteStream(streamId, connection)
	dbgprint("onWriteStream", 3)
	local spec = self.spec_HeadlandManagement
	streamWriteBool(streamId, spec.exists)
	if spec.exists then
		streamWriteBool(streamId, spec.isOn)
		streamWriteBool(streamId, spec.beep)
		streamWriteInt8(streamId, spec.beepVol)
		streamWriteFloat32(streamId, spec.turnSpeed)
		streamWriteBool(streamId, spec.useSpeedControl)
		streamWriteBool(streamId, spec.useModSpeedControl)
		streamWriteBool(streamId, spec.useCrabSteering)
		streamWriteBool(streamId, spec.useCrabSteeringTwoStep)
		streamWriteBool(streamId, spec.useRaiseImplementF)
		streamWriteBool(streamId, spec.useRaiseImplementB)
		streamWriteBool(streamId, spec.waitOnTrigger)
		streamWriteBool(streamId, spec.useStopPTOF)
		streamWriteBool(streamId, spec.useStopPTOB)
		streamWriteBool(streamId, spec.useTurnPlow)
		streamWriteBool(streamId, spec.useCenterPlow)
		streamWriteBool(streamId, spec.useRidgeMarker)
		streamWriteBool(streamId, spec.useGPS)
		streamWriteInt8(streamId, spec.gpsSetting)
		streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
		streamWriteBool(streamId, spec.useGuidanceSteeringOffset)
		streamWriteBool(streamId, spec.useEVTrigger)
		streamWriteBool(streamId, spec.useHLMTriggerF)
		streamWriteBool(streamId, spec.useHLMTriggerB)
		streamWriteInt8(streamId, spec.headlandDistance)
		streamWriteBool(streamId, spec.vcaDirSwitch)
		streamWriteBool(streamId, spec.autoResume)
		streamWriteBool(streamId, spec.autoResumeOnTrigger)
		streamWriteBool(streamId, spec.useDiffLock)
	end
end
	
function HeadlandManagement:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_HeadlandManagement
		if streamReadBool(streamId) then
			dbgprint("onReadUpdateStream: receiving data...", 4)
			spec.exists = streamReadBool(streamId)
			if spec.exists then
				spec.isOn = streamReadBool(streamId)
				spec.beep = streamReadBool(streamId)
				spec.beepVol = streamReadInt8(streamId)
				spec.turnSpeed = streamReadFloat32(streamId)
				spec.useSpeedControl = streamReadBool(streamId)
				spec.useModSpeedControl = streamReadBool(streamId)
				spec.useCrabSteering = streamReadBool(streamId)
				spec.useCrabSteeringTwoStep = streamReadBool(streamId)
				spec.useRaiseImplementF = streamReadBool(streamId)
				spec.useRaiseImplementB = streamReadBool(streamId)
				spec.waitOnTrigger = streamReadBool(streamId)
				spec.useStopPTOF = streamReadBool(streamId)
				spec.useStopPTOB = streamReadBool(streamId)
				spec.useTurnPlow = streamReadBool(streamId)
				spec.useCenterPlow = streamReadBool(streamId)
				spec.useRidgeMarker = streamReadBool(streamId)
				spec.useGPS = streamReadBool(streamId)
				spec.gpsSetting = streamReadInt8(streamId)
				spec.useGuidanceSteeringTrigger = streamReadBool(streamId)
				spec.useGuidanceSteeringOffset = streamReadBool(streamId)
				spec.useEVTrigger = streamReadBool(streamId)
				spec.useHLMTriggerF = streamReadBool(streamId)
				spec.useHLMTriggerB = streamReadBool(streamId)
				spec.headlandDistance = streamReadInt8(streamId)
				spec.setServerHeadlandActDistance = streamReadFloat32(streamId)
				spec.vcaDirSwitch = streamReadBool(streamId)
				spec.autoResume = streamReadBool(streamId)
				spec.autoResumeOnTrigger = streamReadBool(streamId)
				spec.useDiffLock = streamReadBool(streamId)
			end
		end
	end
end

function HeadlandManagement:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_HeadlandManagement
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			dbgprint("onWriteUpdateStream: sending data...", 4)
			streamWriteBool(streamId, spec.exists)
			if spec.exists then
				streamWriteBool(streamId, spec.isOn)
				streamWriteBool(streamId, spec.beep)
				streamWriteInt8(streamId, spec.beepVol)
				streamWriteFloat32(streamId, spec.turnSpeed)
				streamWriteBool(streamId, spec.useSpeedControl)
				streamWriteBool(streamId, spec.useModSpeedControl)
				streamWriteBool(streamId, spec.useCrabSteering)
				streamWriteBool(streamId, spec.useCrabSteeringTwoStep)
				streamWriteBool(streamId, spec.useRaiseImplementF)
				streamWriteBool(streamId, spec.useRaiseImplementB)
				streamWriteBool(streamId, spec.waitOnTrigger)
				streamWriteBool(streamId, spec.useStopPTOF)
				streamWriteBool(streamId, spec.useStopPTOB)
				streamWriteBool(streamId, spec.useTurnPlow)
				streamWriteBool(streamId, spec.useCenterPlow)
				streamWriteBool(streamId, spec.useRidgeMarker)
				streamWriteBool(streamId, spec.useGPS)
				streamWriteInt8(streamId, spec.gpsSetting)
				streamWriteBool(streamId, spec.useGuidanceSteeringTrigger)
				streamWriteBool(streamId, spec.useGuidanceSteeringOffset)
				streamWriteBool(streamId, spec.useEVTrigger)
				streamWriteBool(streamId, spec.useHLMTriggerF)
				streamWriteBool(streamId, spec.useHLMTriggerB)
				streamWriteInt8(streamId, spec.headlandDistance)
				streamWriteFloat32(streamId, spec.setServerHeadlandActDistance)
				streamWriteBool(streamId, spec.vcaDirSwitch)
				streamWriteBool(streamId, spec.autoResume)
				streamWriteBool(streamId, spec.autoResumeOnTrigger)
				streamWriteBool(streamId, spec.useDiffLock)
			end
		end
	end
end

-- inputBindings / inputActions
	
function HeadlandManagement:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 4)
	if self.isClient then
		local spec = self.spec_HeadlandManagement
		HeadlandManagement.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil and spec.exists then 
			local prio = GS_PRIO_HIGH; if spec.isOn then prio = GS_PRIO_NORMAL end
			_, spec.actionEventMainSwitch = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_MAINSWITCH', self, HeadlandManagement.MAINSWITCH, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventMainSwitch, prio)
			
			_, spec.actionEventSwitch = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_TOGGLESTATE', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventSwitch, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventSwitch, spec.isOn)
			
			_, spec.actionEventOn = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SWITCHON', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventOn, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOn, not spec.isActive and spec.isOn)
			
			_, spec.actionEventOff = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SWITCHOFF', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventOff, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOff, spec.isActive and spec.isOn)
			
			_, spec.actionEventSwitchAuto = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_TOGGLEAUTO', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventSwitchAuto, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventSwitch, spec.isOn)
			
			_, spec.actionEventAutoOn = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_AUTOON', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventAutoOn, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOn, spec.autoOverride and spec.isOn)
			
			_, spec.actionEventAutoOff = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_AUTOOFF', self, HeadlandManagement.TOGGLESTATE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(spec.actionEventAutoOff, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(spec.actionEventOff, not spec.autoOverride and (spec.useHLMTriggerF or spec.useHLMTriggerB) and spec.isOn)
			
			local actionEventId
			_, actionEventId = self:addActionEvent(HeadlandManagement.actionEvents, 'HLM_SHOWGUI', self, HeadlandManagement.SHOWGUI, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		end		
	end
end

function HeadlandManagement:TOGGLESTATE(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("TOGGLESTATE", 4)
	local spec = self.spec_HeadlandManagement
	dbgprint_r(spec, 4)
	-- headland management
	-- anschalten nur wenn inaktiv
	if not spec.isActive and spec.isOn and (actionName == "HLM_SWITCHON" or actionName == "HLM_TOGGLESTATE") then
		spec.isActive = true
		spec.evOverride = true
	-- abschalten nur wenn aktiv
	elseif spec.isActive and spec.isOn and (actionName == "HLM_SWITCHOFF" or actionName == "HLM_TOGGLESTATE") and spec.actStep == HeadlandManagement.MAXSTEP then
		if spec.actStep == HeadlandManagement.WAITONTRIGGER then spec.override = true end
		spec.actStep = -spec.actStep
		spec.evOverride = true
	elseif spec.isActive and spec.isOn and (actionName == "HLM_SWITCHOFF" or actionName == "HLM_TOGGLESTATE") and spec.actStep == HeadlandManagement.WAITONTRIGGER then
		spec.override = true
		spec.actStep = -HeadlandManagement.MAXSTEP
	elseif spec.isActive and spec.isOn and (actionName == "HLM_SWITCHOFF" or actionName == "HLM_TOGGLESTATE") and spec.actStep == -HeadlandManagement.WAITONTRIGGER then
		spec.override = true
	end
	-- headland automatic
	-- abschalten nur wenn aktiv
	if not spec.autoOverride and (spec.useHLMTriggerF or spec.useHLMTriggerB or spec.useGuidanceSteeringTrigger) and spec.isOn and (actionName == "HLM_AUTOOFF" or actionName == "HLM_TOGGLEAUTO") then
		spec.autoOverride = true
	-- anschalten nur wenn inaktiv
	elseif spec.autoOverride and spec.isOn and (actionName == "HLM_AUTOON" or actionName == "HLM_TOGGLEAUTO") then
		spec.autoOverride = false
	end
	
	self:raiseDirtyFlags(spec.dirtyFlag)
end

function HeadlandManagement:MAINSWITCH(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("MAINSWITCH", 4)
	local spec = self.spec_HeadlandManagement
	if spec.isOn then
		spec.isActive = false
		spec.actStep = 0
		spec.autoOverride = false
		spec.isOn = false
	else
		spec.lastHeadlandF = false
		spec.lastHeadlandB = false
		spec.isOn = true
	end
	local prio = GS_PRIO_HIGH; if spec.isOn then prio = GS_PRIO_NORMAL end
	g_inputBinding:setActionEventTextPriority(spec.actionEventMainSwitch, prio)
	g_inputBinding:setActionEventTextVisibility(spec.actionEventSwitch, spec.isOn)
	g_inputBinding:setActionEventTextVisibility(spec.actionEventOn, not spec.isActive and spec.isOn)
	g_inputBinding:setActionEventTextVisibility(spec.actionEventOff, spec.isActive and spec.isOn)
	self:raiseDirtyFlags(spec.dirtyFlag)
end	

-- GUI

function HeadlandManagement:SHOWGUI(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("SHOWGUI", 4)
	local spec = self.spec_HeadlandManagement
	local hlmGui = g_gui:showDialog("HeadlandManagementGui")
	local spec_gs = self.spec_globalPositioningSystem
	local gpsEnabled = spec_gs ~= nil and spec_gs.lastInputValues ~= nil and spec_gs.lastInputValues.guidanceSteeringIsActive
	spec.frontNode, spec.backNode, spec.vehicleLength, spec.vehicleWidth = vehicleMeasurement(self)
	dbgprint_r(spec, 4, 2)
	hlmGui.target:setCallback(HeadlandManagement.guiCallback, self)
	HeadlandManagementGui.setData(hlmGui.target, self:getFullName(), spec, gpsEnabled, HeadlandManagement.debug)
end

function HeadlandManagement:guiCallback(changes, debug)
	self.spec_HeadlandManagement = changes
	HeadlandManagement.debug = debug
	local spec = self.spec_HeadlandManagement
	dbgprint("guiCallback", 4)
	self:raiseDirtyFlags(spec.dirtyFlag)
	dbgprint_r(spec, 4, 2)
end

local function saveConfigWithImplement(spec, implementName)
	--local spec = self.spec_HeadlandManagement
	dbgprint("saveConfigWithImplement : spec: "..tostring(spec), 2)
	local saved = false
	if spec ~= nil and spec.exists then
		createFolder(HeadlandManagement.MODSETTINGSDIR)
		
		local filename = HeadlandManagement.MODSETTINGSDIR..implementName..".xml"
		local key = "configSettings"
		local xmlFile = XMLFile.create("configSettingsXML", filename, key)
		
		if xmlFile ~= nil then 		
			dbgprint("saveConfigToImplement : key: "..tostring(key), 2)

			xmlFile:setFloat(key..".turnSpeed", spec.turnSpeed)
			xmlFile:setBool(key..".useSpeedControl", spec.useSpeedControl)
			xmlFile:setBool(key..".useModSpeedControl", spec.useModSpeedControl)
			xmlFile:setBool(key..".useCrabSteering", spec.useCrabSteering)
			xmlFile:setBool(key..".useCrabSteeringTwoStep", spec.useCrabSteeringTwoStep)
			xmlFile:setBool(key..".useRaiseImplementF", spec.useRaiseImplementF)
			xmlFile:setBool(key..".useRaiseImplementB", spec.useRaiseImplementB)
			xmlFile:setBool(key..".waitOnTrigger", spec.waitOnTrigger)
			xmlFile:setBool(key..".useStopPTOF", spec.useStopPTOF)
			xmlFile:setBool(key..".useStopPTOB", spec.useStopPTOB)
			xmlFile:setBool(key..".turnPlow", spec.useTurnPlow)
			xmlFile:setBool(key..".centerPlow", spec.useCenterPlow)
			xmlFile:setBool(key..".switchRidge", spec.useRidgeMarker)
			xmlFile:setBool(key..".useGPS", spec.useGPS)
			xmlFile:setInt(key..".gpsSetting", spec.gpsSetting)
			xmlFile:setBool(key..".useGuidanceSteeringTrigger", spec.useGuidanceSteeringTrigger)
			xmlFile:setBool(key..".useGuidanceSteeringOffset", spec.useGuidanceSteeringOffset)
			xmlFile:setBool(key..".useHLMTriggerF", spec.useHLMTriggerF)
			xmlFile:setBool(key..".useHLMTriggerB", spec.useHLMTriggerB)
			xmlFile:setInt(key..".headlandDistance", spec.headlandDistance)
			xmlFile:setBool(key..".vcaDirSwitch", spec.vcaDirSwitch)
			xmlFile:setBool(key..".autoResume", spec.autoResume)
			xmlFile:setBool(key..".useDiffLock", spec.useDiffLock)
			
			xmlFile:save()
			xmlFile:delete()
			dbgprint("saveConfigWithImplement : saving data finished", 2)
			saved = true
		end
	end
	return saved
end

local function loadConfigWithImplement(spec, implementName)
	--local spec = self.spec_HeadlandManagement
	dbgprint("loadConfigWithImplement : spec: "..tostring(spec), 2)
	local loaded = false
	if spec ~= nil and spec.exists then
		createFolder(HeadlandManagement.MODSETTINGSDIR)
		
		local filename = HeadlandManagement.MODSETTINGSDIR..implementName..".xml"
		local key = "configSettings"
		local xmlFile = XMLFile.loadIfExists("configSettingsXML", filename, key)
		
		if xmlFile ~= nil then 
			dbgprint("loadConfigToImplement : key: "..tostring(key), 2)

			spec.turnSpeed = xmlFile:getFloat(key..".turnSpeed")
			spec.useSpeedControl = xmlFile:getBool(key..".useSpeedControl")
			spec.useModSpeedControl = xmlFile:getBool(key..".useModSpeedControl")
			spec.useCrabSteering = xmlFile:getBool(key..".useCrabSteering")
			spec.useCrabSteeringTwoStep = xmlFile:getBool(key..".useCrabSteeringTwoStep")
			spec.useRaiseImplementF = xmlFile:getBool(key..".useRaiseImplementF")
			spec.useRaiseImplementB = xmlFile:getBool(key..".useRaiseImplementB")
			spec.waitOnTrigger = xmlFile:getBool(key..".waitOnTrigger")
			spec.useStopPTOF = xmlFile:getBool(key..".useStopPTOF")
			spec.useStopPTOB = xmlFile:getBool(key..".useStopPTOB")
			spec.useTurnPlow = xmlFile:getBool(key..".turnPlow")
			spec.useCenterPlow = xmlFile:getBool(key..".centerPlow")
			spec.useRidgeMarker = xmlFile:getBool(key..".switchRidge")
			spec.useGPS = xmlFile:getBool(key..".useGPS")
			spec.gpsSetting = xmlFile:getInt(key..".gpsSetting")
			spec.useGuidanceSteeringTrigger = xmlFile:getBool(key..".useGuidanceSteeringTrigger")
			spec.useGuidanceSteeringOffget = xmlFile:getBool(key..".useGuidanceSteeringOffget")
			spec.useHLMTriggerF = xmlFile:getBool(key..".useHLMTriggerF")
			spec.useHLMTriggerB = xmlFile:getBool(key..".useHLMTriggerB")
			spec.headlandDistance = xmlFile:getInt(key..".headlandDistance")
			spec.vcaDirSwitch = xmlFile:getBool(key..".vcaDirSwitch")
			spec.autoResume = xmlFile:getBool(key..".autoResume")
			spec.useDiffLock = xmlFile:getBool(key..".useDiffLock")
			
			xmlFile:delete()
			dbgprint("loadConfigToImplement : loading data finished", 2)
			loaded = true
		end
	end
	return spec, loaded
end

local function isConfigImplement(implement)
	--return implement.spec_workArea ~= nil or implement.spec_combine ~= nil or implement.spec_forageWagon ~= nil or implement.spec_baler ~= nil
	local returnType
	
	if implement.spec_plow ~= nil then returnType = "Plow"
		elseif implement.spec_combine ~= nil then returnType = "Combine"
		elseif implement.spec_sowingMachine ~= nil then returnType = "Sowingmachine"
		elseif implement.spec_cultivator ~= nil then returnType = "Cultivator"
		elseif implement.spec_mulcher ~= nil then returnType = "Mulcher"
		elseif implement.spec_roller ~= nil then returnType = "Roller"
		elseif implement.spec_forageWagon ~= nil then returnType = "Foragewagon"
		elseif implement.spec_baler ~= nil then returnType = "Baler"
	end
	
	return returnType
end

function HeadlandManagement:onPostAttachImplement(implement, jointDescIndex)
	local spec = self.spec_HeadlandManagement
	if spec.exists and not HeadlandManagement.isDedi then
		dbgprint("onPostAttachImplement : vehicle: "..self:getFullName(),2 )
		dbgprint("onPostAttachImplement : jointDescIndex: "..tostring(jointDescIndex), 2)
		dbgprint("onPostAttachImplement : implement: "..implement:getFullName(), 2)
		-- Detect frontNode, backNode and recalculate vehicle length
		spec.frontNode, spec.backNode, spec.vehicleLength, spec.vehicleWidth, spec.maxTurningRadius = vehicleMeasurement(self)
		spec.guidanceSteeringOffset = spec.vehicleLength
		dbgprint("onPostAttachImplement : length: "..tostring(spec.vehicleLength), 2)
		dbgprint("onPostAttachImplement : frontNode: "..tostring(spec.frontNode), 2)
		dbgprint("onPostAttachImplement : backNode: "..tostring(spec.backNode), 2)
		-- try to load headland management configuration for added implement
		local isControlledVehicle = g_currentMission.controlledVehicle ~= nil and self == g_currentMission.controlledVehicle -- w/o manual attach
		local isControlledPlayer = g_currentMission.player ~= nil and g_currentMission.player.isControlled -- with manual attach
		local isMAVehicle = isControlledPlayer and g_currentMission.interactiveVehicleInRange ~= nil and self == g_currentMission.interactiveVehicleInRange
		local implementType = isConfigImplement(implement)
		if (isControlledVehicle or isMAVehicle) and implement~= nil and implement.getFullName ~= nil and implementType ~= nil and g_currentMission.isMissionStarted then
			local loaded
			spec, loaded = loadConfigWithImplement(spec, implementType)
			dbgprint("onPostAttachImplement : configuration loaded for implement type "..tostring(implementType), 2)
			if loaded then
				g_currentMission:addGameNotification(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_configuration"), g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_implementTypeLoaded").." "..g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_type_"..implementType), "", 2500)
			end
		end
		self.spec_HeadlandManagement = spec
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function HeadlandManagement:onPreDetachImplement(implement)
	local spec = self.spec_HeadlandManagement
	if spec.exists and not HeadlandManagement.isDedi then
		dbgprint("onPreDetachImplement : vehicle: "..self:getFullName(), 2)
		-- Detect frontNode, backNode and recalculate vehicle length
		spec.frontNode, spec.backNode, spec.vehicleLength, spec.vehicleWidth, spec.maxTurningRadius = vehicleMeasurement(self, implement.object)
		spec.guidanceSteeringOffset = spec.vehicleLength
		dbgprint("onPreDetachImplement : length: "..tostring(spec.vehicleLength), 2)
		dbgprint("onPreDetachImplement : frontNode: "..tostring(spec.frontNode), 2)
		dbgprint("onPreDetachImplement : backNode: "..tostring(spec.backNode), 2)
		-- save headland management configuration for implement to be removed 
		local isControlledVehicle = g_currentMission.controlledVehicle ~= nil and self == g_currentMission.controlledVehicle -- w/o manual attach
		local isControlledPlayer = g_currentMission.player ~= nil and g_currentMission.player.isControlled -- with manual attach
		local isMAVehicle = isControlledPlayer and g_currentMission.interactiveVehicleInRange ~= nil and self == g_currentMission.interactiveVehicleInRange
		local implementType = isConfigImplement(implement.object)
		if (isControlledVehicle or isMAVehicle) and implement ~= nil and implement.object ~= nil and implement.object.getFullName ~= nil and implementType ~= nil then
			local saved = saveConfigWithImplement(spec, implementType)
			dbgprint("onPreDetachImplement : configuration saved for implement type "..tostring(implementType), 2)
			if saved then
				g_currentMission:addGameNotification(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_configuration"), g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_implementTypeSaved").." "..g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_type_"..implementType), "", 2500)
			end
		end
		self.spec_HeadlandManagement = spec
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

local function getHeading(self)
	local x1, y1, z1 = localToWorld(self.rootNode, 0, 0, 0)
	local x2, y2, z2 = localToWorld(self.rootNode, 0, 0, 1)
	local dx, dz = x2 - x1, z2 - z1
	local heading = math.floor(180 - (180 / math.pi) * math.atan2(dx, dz))
	return heading, dx, dz
end	

-- Main part

local function isOnField(node, x, z)
	if (x == nil) or (z == nil) then x, _, z = getWorldTranslation(node) end
	return getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
end	

local function getFieldNum(node, x, z)
	local fieldNum = 0
	if (x == nil) or (z == nil) then x, _, z = getWorldTranslation(node) end
	local farmland = g_farmlandManager:getFarmlandAtWorldPosition(x, z)
    local field
    local dist = math.huge
    if farmland ~= nil then
        local fields = g_fieldManager.farmlandIdFieldMapping[farmland.id]
        if fields ~= nil then
			for _, field in pairs(fields) do
				local rx, rz = field.posX, field.posZ
				dx, dz = rx - x, rz - z
				rdist = math.sqrt(dx^2 + dz^2)
				dist = math.min(dist, rdist)				
				if rdist == dist then fieldNum = field.fieldId end
			end
		end
    end
    return fieldNum or 0
end

-- Research part
function HeadlandManagement.onUpdateResearch(self)
	local spec = self.spec_HeadlandManagement
	if spec == nil or not self:getIsActive() or self ~= g_currentMission.controlledVehicle then return end
	
	dbgrender("radius: "..tostring(spec.maxTurningRadius), 3, 3)
	
	dbgrender("onHeadlandF: "..tostring(spec.headlandF), 5, 3)
	dbgrender("onHeadlandB: "..tostring(spec.headlandB), 6, 3)
	
	dbgrender("lastOnHeadlandF: "..tostring(spec.lastHeadlandF), 8, 3)
	dbgrender("lastOnHeadlandB: "..tostring(spec.lastHeadlandB), 9, 3)
	
	dbgrender("fieldNumF: "..tostring(spec.fieldNumF), 11, 3)
	dbgrender("fieldNumB: "..tostring(spec.fieldNumB), 13, 3)

	dbgrender("direction: "..tostring(math.floor(spec.heading)), 15, 3)
	
	dbgrender("isActive: "..tostring(spec.isActive), 17, 3)
	dbgrender("actStep: "..tostring(spec.actStep), 18, 3)
	
	local turnTarget
	if spec.turnHeading ~= nil then turnTarget=math.floor(spec.turnHeading) else turnTarget = nil end
	dbgrender("turnHeading:"..tostring(turnTarget), 20, 3)
	
	local fieldNum = getFieldNum(self.rootNode)
	dbgrender("Field ID: "..tostring(fieldNum), 21, 3)
	
	dbgrender("useEVTrigger: "..tostring(spec.useEVTrigger), 23, 3)
	dbgrender("EV: isOnField: "..tostring(self.vData.track.isOnField), 24, 3)
	dbgrender("EV: Status (vData5): "..tostring(self.vData.is[5]), 25, 3)
	dbgrender("EV: Track  (vData6): "..tostring(self.vData.is[6]), 26, 3)
	
	local analyseTable = nil
	
	if analyseTable ~= nil then 
		dbgrenderTable(analyseTable, 1, 3)
		if spec.researchOutput == nil then
			dbgprint_r(analyseTable, 3, 3)
			spec.researchOutput = true
		end
	end
end

function HeadlandManagement:onUpdate(dt)
	local spec = self.spec_HeadlandManagement
	
	-- self.actionEventUpdateRequested = true -- restore of actionBindings
	
	if not spec.isOn then return end

	-- debug output
	if spec.actStep == 1 then
		dbgprint("onUpdate : spec_HeadlandManagement:", 4)
		dbgprint_r("spec", 4)
	end
		
	-- calculate position, direction, field mode and vehicle's heading
	local fx, fz, bx, bz, dx, dz, tfx, tfz, tbx, tbz
	spec.heading, dx, dz = getHeading(self)
	
	if spec.isActive and spec.turnHeading == nil then
		spec.turnHeading = (spec.heading + 180) % 360
	end
	
	local distance = spec.headlandDistance
	local override = false
	
	if spec.turnHeading ~= nil then 
		local heading = (spec.turnHeading + 180) % 360
		local bearing = (spec.heading - heading) % 360
		-- Prevent distance growing to infinite and prevent resuming too early because of not right-angular field borders
		if bearing > 22.5 and bearing <= 135 then override = true end
		if bearing > 225 and bearing < 337.5 then override = true end
		dbgrender("bearing: "..tostring(bearing), 16, 3)
		distance = distance / math.cos(bearing * (2 * math.pi / 360))
		if distance < 0 then distance = distance + 3 end -- correction value to smoothen field edge
	end
	
	dbgrender("distance: "..tostring(distance), 17, 3)
	
	if spec.frontNode ~= nil then 
		local oldValue = spec.headlandF
		-- transform to center position
		local nx, ny, nz = getWorldTranslation(spec.frontNode)
		local lx, ly, lz = worldToLocal(self.rootNode, nx, ny, nz)
		local fx, _, fz = localToWorld(self.rootNode, 0, 0, lz)
		tfx, tfz = fx + distance * dx, fz + distance * dz
		spec.headlandF = override or getDensityAtWorldPos(g_currentMission.terrainDetailId, tfx, 0, tfz) == 0
		if not spec.headlandF then spec.fieldNumF = getFieldNum(spec.frontNode, tfx, tfz) end -- Update fieldNumF only, if trigger is on field
		if HeadlandManagement.debug then
			DebugUtil.drawDebugLine(nx, ny, nz, tfx, 0, tfz, 1, 0, 0, nil, true)
		end
		if spec.headlandF ~= oldValue then dbgprint("headlandF: Changed to "..tostring(spec.headlandF), 3) end
	else
		spec.headlandF = false
	end

	if spec.backNode ~= nil then 
		local oldValue = spec.headlandB
		-- transform to center position
		local nx, ny, nz = getWorldTranslation(spec.backNode)
		local lx, ly, lz = worldToLocal(self.rootNode, nx, ny, nz)
		local bx, _, bz = localToWorld(self.rootNode, 0, 0, lz)
	 	tbx, tbz = bx + distance * dx, bz + distance * dz
		spec.headlandB = override or getDensityAtWorldPos(g_currentMission.terrainDetailId, tbx, 0, tbz) == 0
		if not spec.headlandB then spec.fieldNumB = getFieldNum(spec.backNode, tbx, tbz) end -- Update fieldNumB only, if trigger is on field
		if HeadlandManagement.debug then
			DebugUtil.drawDebugLine(nx, ny, nz, tbx, 0, tbz, 0, 1, 0, nil, true)
		end
		if spec.headlandB ~= oldValue then dbgprint("headlandB: Changed to "..tostring(spec.headlandB), 3) end
	else
		spec.headlandB = false
	end
	
	-- research output
	HeadlandManagement.onUpdateResearch(self)

	-- play warning sound if headland management is active
	if not HeadlandManagement.isDedi and self:getIsActive() and self == g_currentMission.controlledVehicle and spec.exists and spec.beep and spec.actStep==HeadlandManagement.MAXSTEP then
		spec.timer = spec.timer + dt
		if spec.timer > 2000 then 
			playSample(HeadlandManagement.BEEPSOUND, 1, spec.beepVol / 10, 0, 0, 0)
			dbgprint("Beep: "..self:getName(), 4)
			spec.timer = 0
		end	
	else
		spec.timer = 0
	end
	
	-- if activated, use EV's trigger instead of hlm's one
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.modEVFound and spec.isOn then
		if spec.vData ~= nil and spec.vData.track ~= nil then spec.useEVTrigger = spec.vData.track.headlandMode > 1 end
	end
	
	-- activate headland mode when reaching headland in auto-mode
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and not spec.isActive and not spec.useEVTrigger
		and spec.useHLMTriggerF and not spec.autoOverride
		and spec.headlandF and not spec.lastHeadlandF 
	then
		spec.isActive = true
		spec.lastHeadlandF = true
		spec.lastFieldNumF = spec.fieldNumF
		dbgprint("onUpdate : Headland mode activated by front trigger (auto-mode) on Field "..tostring(spec.lastFieldNumF), 2)
	end
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and not spec.isActive and not spec.useEVTrigger
		and spec.useHLMTriggerB and not spec.autoOverride
		and spec.headlandB and not spec.lastHeadlandB 
	then
		spec.isActive = true
		spec.lastHeadlandB = true
		spec.lastFieldNumB = spec.fieldNumB
		dbgprint("onUpdate : Headland mode activated by back trigger (auto-mode) on Field "..tostring(spec.lastFieldNumB), 2)
	end
	
	-- activate headland management at headland in auto-mode triggered by Guidance Steering
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger and not spec.useEVTrigger then
		local gsSpec = self.spec_globalPositioningSystem
		if not spec.isActive and gsSpec.playHeadLandWarning and not spec.autoOverride then
			spec.isActive = true
			dbgprint("onUpdate : Headland mode activated by guidance steering (auto-mode)", 2)
		end
	end

	-- activate headland management at headland in auto-mode triggered by Enhanced Vehicle
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.modEVFound and spec.useEVTrigger then
		local gsSpec = self.spec_globalPositioningSystem
		if not spec.isActive and not spec.evOverride and self.vData ~= nil and self.vData.track ~= nil and self.vData.track.isOnField == 0 and not spec.autoOverride 
			and self.vData ~= nil and self.vData.is ~= nil and self.vData.is[6] == true and not spec.evOverride then
			spec.isActive = true
			spec.evStatus = true
			dbgprint("onUpdate : Headland mode activated by enhanced vehicle (auto-mode)", 2)
		end
	end
	
	-- set Enhanced Vehicle's headland settings to avoid interferences
	--if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.modEVFound and spec.isOn and not spec.useEVTrigger then
	--	if spec.vData ~= nil and spec.vData.track ~= nil then spec.vData.track.headlandMode = 1 end
	--end
	
	-- headland management main control
	if self:getIsActive() and spec.isActive and self == g_currentMission.controlledVehicle and spec.exists and spec.actStep<HeadlandManagement.MAXSTEP then
		-- Set management actions
		spec.action[HeadlandManagement.REDUCESPEED] = spec.useSpeedControl
		spec.action[HeadlandManagement.WAITTIME1] = spec.useRaiseImplementF or spec.useRaiseImplementB
		spec.action[HeadlandManagement.CRABSTEERING] = spec.crabSteeringFound and spec.useCrabSteering
		spec.action[HeadlandManagement.DIFFLOCK] = (spec.modVCAFound or spec.modEVFound) and spec.useDiffLock
		spec.action[HeadlandManagement.RAISEIMPLEMENT1] = spec.useRaiseImplementF or spec.useRaiseImplementB
		spec.action[HeadlandManagement.WAITONTRIGGER] = spec.waitOnTrigger
		spec.action[HeadlandManagement.RAISEIMPLEMENT2] = spec.useRaiseImplementF or spec.useRaiseImplementB
		spec.action[HeadlandManagement.WAITTIME2] = spec.useTurnPlow and (spec.useRaiseImplementF or spec.useRaiseImplementB)
		spec.action[HeadlandManagement.WAITTIME3] = spec.useTurnPlow and spec.useCenterPlow and self.spec_plow ~= nil and (spec.useRaiseImplementF or spec.useRaiseImplementB)
		spec.action[HeadlandManagement.TURNPLOW] = spec.useTurnPlow and (spec.useRaiseImplementF or spec.useRaiseImplementB)
		spec.action[HeadlandManagement.STOPPTO] = spec.useStopPTOF or spec.useStopPTOB
		spec.action[HeadlandManagement.STOPGPS] = spec.useGPS and (spec.modGuidanceSteeringFound or spec.modVCAFound)
		
		if spec.action[math.abs(spec.actStep)] and not HeadlandManagement.isDedi then
			dbgprint("onUpdate : actStep: "..tostring(spec.actStep), 2)
			dbgprint("onUpdate : waitTime: "..tostring(spec.waitTime), 4)
			local useEV = spec.modEVFound
			-- Activation
			if spec.actStep == HeadlandManagement.REDUCESPEED and spec.action[HeadlandManagement.REDUCESPEED] then HeadlandManagement.reduceSpeed(self, true); end
			if spec.actStep == HeadlandManagement.CRABSTEERING and spec.action[HeadlandManagement.CRABSTEERING] then HeadlandManagement.crabSteering(self, true, spec.useCrabSteeringTwoStep); end
			if spec.actStep == HeadlandManagement.DIFFLOCK and spec.action[HeadlandManagement.DIFFLOCK] then HeadlandManagement.disableDiffLock(self, true, useEV); end
			if spec.actStep == HeadlandManagement.RAISEIMPLEMENT1 and spec.action[HeadlandManagement.RAISEIMPLEMENT1] then spec.waitTime = HeadlandManagement.raiseImplements(self, true, spec.useTurnPlow, spec.useCenterPlow, 1, true, false); end
			if spec.actStep == HeadlandManagement.WAITONTRIGGER and spec.action[HeadlandManagement.WAITONTRIGGER] then HeadlandManagement.waitOnTrigger(self, spec.useHLMTriggerB); end
			if spec.actStep == HeadlandManagement.RAISEIMPLEMENT2 and spec.action[HeadlandManagement.RAISEIMPLEMENT2] then spec.waitTime = HeadlandManagement.raiseImplements(self, true, spec.useTurnPlow, spec.useCenterPlow, 1, false, true); end
			if spec.actStep == HeadlandManagement.WAITTIME2 and spec.action[HeadlandManagement.WAITTIME2] then HeadlandManagement.wait(self, spec.waitTime, dt); end
			if spec.actStep == HeadlandManagement.TURNPLOW and spec.action[HeadlandManagement.TURNPLOW] then HeadlandManagement.raiseImplements(self, true, spec.useTurnPlow, spec.useCenterPlow, 2, true, true); end
			if spec.actStep == HeadlandManagement.STOPPTO and spec.action[HeadlandManagement.STOPPTO] then HeadlandManagement.stopPTO(self, true); end
			if spec.actStep == HeadlandManagement.STOPGPS and spec.action[HeadlandManagement.STOPGPS] then HeadlandManagement.stopGPS(self, true); end
			-- Deactivation
			if spec.actStep == -HeadlandManagement.STOPGPS and spec.action[HeadlandManagement.STOPGPS] then HeadlandManagement.stopGPS(self, false); end
			if spec.actStep == -HeadlandManagement.STOPPTO and spec.action[HeadlandManagement.STOPPTO] then HeadlandManagement.stopPTO(self, false); end
			if spec.actStep == -HeadlandManagement.TURNPLOW and spec.action[HeadlandManagement.TURNPLOW] then spec.waitTime = HeadlandManagement.raiseImplements(self, false, spec.useTurnPlow, spec.useCenterPlow, 2, true, true); end
			if spec.actStep == -HeadlandManagement.WAITTIME3 and spec.action[HeadlandManagement.WAITTIME3] then HeadlandManagement.wait(self, spec.waitTime, dt); end
			if spec.actStep == -HeadlandManagement.RAISEIMPLEMENT2 and spec.action[HeadlandManagement.RAISEIMPLEMENT2] then HeadlandManagement.raiseImplements(self, false, spec.useTurnPlow, spec.useCenterPlow, 1, true, false); end
			if spec.actStep == -HeadlandManagement.WAITONTRIGGER and spec.action[HeadlandManagement.WAITONTRIGGER] then HeadlandManagement.waitOnTrigger(self, false); end
			if spec.actStep == -HeadlandManagement.RAISEIMPLEMENT1 and spec.action[HeadlandManagement.RAISEIMPLEMENT1] then HeadlandManagement.raiseImplements(self, false, spec.useTurnPlow, spec.useCenterPlow, 1, false, true); end
			if spec.actStep == -HeadlandManagement.DIFFLOCK and spec.action[HeadlandManagement.DIFFLOCK] then HeadlandManagement.disableDiffLock(self, false, useEV); end
			if spec.actStep == -HeadlandManagement.CRABSTEERING and spec.action[HeadlandManagement.CRABSTEERING] then HeadlandManagement.crabSteering(self, false, spec.useCrabSteeringTwoStep); end
			if spec.actStep == -HeadlandManagement.WAITTIME1 and spec.action[HeadlandManagement.WAITTIME1] then HeadlandManagement.wait(self, spec.waitTime, dt); end
			if spec.actStep == -HeadlandManagement.REDUCESPEED and spec.action[HeadlandManagement.REDUCESPEED] then HeadlandManagement.reduceSpeed(self, false); end		
		end
		spec.actStep = spec.actStep + 1
		if spec.actStep == 0 then 
			spec.isActive = false
			spec.override = false
			spec.evOverride = false
			spec.turnHeading = nil
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
	
	-- auto resume on turn (180 degrees)
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.isActive and spec.actStep == HeadlandManagement.MAXSTEP
		and not spec.useEVTrigger and spec.autoResume and not spec.autoOverride and not spec.autoResumeOnTrigger and spec.heading == spec.turnHeading 
	then
		spec.actStep = -spec.actStep
		spec.turnHeading = nil
		dbgprint("onUpdate : Field mode activated by 180°-turn", 2)
	end
	
	-- auto resume by enhanced vehicle
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.modEVFound and spec.useEVTrigger then
		local gsSpec = self.spec_globalPositioningSystem
		if spec.isActive and not spec.evOverride and spec.actStep == HeadlandManagement.MAXSTEP and self.vData ~= nil and self.vData.track ~= nil and self.vData.track.isOnField > 5 and not spec.autoOverride then
			spec.actStep = -spec.actStep
			dbgprint("onUpdate : Field mode activated by enhanced vehicle (auto-resume)", 2)
		end
	end
	
	-- auto resume on trigger: activate field mode when leaving headland in auto-mode
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.isActive and spec.actStep == HeadlandManagement.MAXSTEP and not spec.useEVTrigger
		and spec.useHLMTriggerF and spec.autoResumeOnTrigger 
		and not spec.headlandF and spec.lastHeadlandF and not spec.autoOverride 
		and isOnField(self.rootNode) and (spec.fieldNumF == getFieldNum(self.rootNode)) --spec.lastFieldNumF)
	then
		spec.actStep = -spec.actStep
		spec.lastHeadlandF = false 
		spec.turnHeading = nil
		dbgprint("onUpdate : Field mode activated by front trigger (auto-resume)", 2)
	end
	if not HeadlandManagement.isDedi and self:getIsActive() and spec.exists and self == g_currentMission.controlledVehicle and spec.isActive and spec.actStep == HeadlandManagement.MAXSTEP
		and spec.useHLMTriggerB and spec.autoResumeOnTrigger 
		and not spec.headlandB and spec.lastHeadlandB and not spec.autoOverride
		and isOnField(self.rootNode) and (spec.fieldNumB == getFieldNum(self.rootNode)) --spec.lastFieldNumB)
	then
		spec.actStep = -spec.actStep
		spec.lastHeadlandB = false 
		spec.turnHeading = nil
		spec.evOverride = false
		dbgprint("onUpdate : Field mode activated by back trigger (auto-resume)", 2)
	end
	
	-- reset lastHeadland if no automatic field mode is active
	if spec.lastHeadlandF and (not spec.autoResumeOnTrigger or spec.autoOverride) and not spec.isActive and not spec.headlandF and isOnField(self.rootNode) then 
		spec.lastHeadlandF = false 
		dbgprint("onUpdate: reset lastHeadlandF", 2)
	end
	if spec.lastHeadlandB and (not spec.autoResumeOnTrigger or spec.autoOverride) and not spec.isActive and not spec.headlandB and isOnField(self.rootNode) then 
		spec.lastHeadlandB = false 
		dbgprint("onUpdate: reset lastHeadlandB", 2)
	end
end

function HeadlandManagement:onDraw(dt)
	local spec = self.spec_HeadlandManagement
	if self:getIsActive() and spec.exists then

		-- keybindings 
		if spec.isActive then
			g_currentMission:addExtraPrintText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("text_HLM_isActive"))
			g_inputBinding:setActionEventText(spec.actionEventSwitch, g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("input_HLM_SWITCHOFF"))
		else
			g_inputBinding:setActionEventText(spec.actionEventSwitch, g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("input_HLM_SWITCHON"))
		end
		
		-- gui icon
		local scale = g_gameSettings.uiScale
		
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.speedGaugeSizeValues.centerOffsetX * 0.9
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY - g_currentMission.inGameMenu.hud.speedMeter.speedGaugeSizeValues.centerOffsetY * 0.92
		local w = 0.015 * scale
		local h = w * g_screenAspectRatio
		local guiIcon = HeadlandManagement.guiIconOff
		
		local headlandAutomaticGS = not spec.autoOverride and (spec.modGuidanceSteeringFound and spec.useGuidanceSteeringTrigger) 
		--local headlandAutomaticEV = not spec.autoOverride and (spec.modEVFound and spec.useEVTrigger and not spec.evOverride)
		local headlandAutomatic	  = not spec.autoOverride and (spec.useHLMTriggerF or spec.useHLMTriggerB)
		local headlandAutomaticResume = spec.autoResume and not spec.autoOverride 
		--local headlandAutomaticResumeEV = (spec.modEVFound and spec.useEVTrigger and not spec.evOverride) and not spec.autoOverride and spec.vData ~= nil and spec.vData.is ~= nil and spec.vData.is[6]
				
		-- field mode
		if spec.isOn and headlandAutomatic and not spec.isActive and not spec.useEVTrigger then 
			guiIcon = HeadlandManagement.guiIconFieldA
			if spec.gpsSetting == 4 and self.vcaSnapReverseLeft ~= nil and self.vcaGetState ~= nil and self:vcaGetState("snapIsOn") then 
				guiIcon = HeadlandManagement.guiIconFieldAL 
			end
			if spec.gpsSetting == 5 and self.vcaSnapReverseRight ~= nil and self.vcaGetState ~= nil and self:vcaGetState("snapIsOn") then 
				guiIcon = HeadlandManagement.guiIconFieldAR 
			end
			if spec.gpsSetting == 7 and self.vData = nil and self.vData.is = nil and self.vData.is[6] then 
				guiIcon = HeadlandManagement.guiIconFieldALR
			end
		end
		
		if spec.isOn and not headlandAutomatic and not spec.isActive and not spec.useEVTrigger then 
			guiIcon = HeadlandManagement.guiIconField
			if spec.gpsSetting == 4 and self.vcaSnapReverseLeft ~= nil and self.vcaGetState ~= nil and self:vcaGetState("snapIsOn") then 
				guiIcon = HeadlandManagement.guiIconFieldL 
			end
			if spec.gpsSetting == 5 and self.vcaSnapReverseRight ~= nil and self.vcaGetState ~= nil and self:vcaGetState("snapIsOn") then 
				guiIcon = HeadlandManagement.guiIconFieldR 
			end
			if spec.gpsSetting == 7 and self.vData = nil and self.vData.is = nil and self.vData.is[6] then 
				guiIcon = HeadlandManagement.guiIconFieldLR
			end
		end
		
		if spec.isOn and headlandAutomaticGS and not spec.isActive and not spec.useEVTrigger then
			local spec_gs = self.spec_globalPositioningSystem 
			local gpsEnabled = (spec_gs.lastInputValues ~= nil and spec_gs.lastInputValues.guidanceSteeringIsActive)
			if gpsEnabled then
				guiIcon = HeadlandManagement.guiIconFieldGS
			end
		end
		
		if spec.isOn and not spec.isActive and spec.useEVTrigger then 
			guiIcon = HeadlandManagement.guiIconFieldEV
		end
	
		-- headland mode			
		if spec.isOn and headlandAutomaticResume and spec.isActive and spec.actStep==HeadlandManagement.MAXSTEP and not spec.useEVTrigger then
			guiIcon = HeadlandManagement.guiIconHeadlandA
		end
		
		if spec.isOn and spec.useEVTrigger and spec.isActive and spec.actStep==HeadlandManagement.MAXSTEP then
			guiIcon = HeadlandManagement.guiIconHeadlandEV
		end
		
		if spec.isOn and not headlandAutomaticResume and spec.isActive and spec.actStep==HeadlandManagement.MAXSTEP and not spec.useEVTrigger then 
			guiIcon = HeadlandManagement.guiIconHeadland
		end	
		
		-- Working Mode
		if spec.isOn and spec.isActive and spec.actStep > 0 and spec.actStep < HeadlandManagement.MAXSTEP then
			guiIcon = HeadlandManagement.guiIconHeadlandW
		end
		if spec.isOn and spec.isActive and spec.actStep < 0 then
			guiIcon = HeadlandManagement.guiIconFieldW
		end
		
		renderOverlay(guiIcon, x, y, w, h)
		
		-- debug: show frontnode and backnode
		if HeadlandManagement.debug then
			ShowNodeF = DebugCube.new()
			ShowNodeB = DebugCube.new()
			if spec.frontNode ~= nil then 
				ShowNodeF:createWithNode(spec.frontNode, 0.3, 0.3, 0.3) 
				ShowNodeF:draw()
			end
			if spec.backNode ~= nil then 
				ShowNodeB:createWithNode(spec.backNode, 0.3, 0.3, 0.3)
				ShowNodeB:draw() 
			end
		end
	end
end
	
function HeadlandManagement.waitOnTrigger(self, automatic)
	local spec = self.spec_HeadlandManagement
	dbgprint("waitOnTrigger : automatic: "..tostring(automatic), 2)
	
	if automatic then
		if not spec.headlandB then 
			spec.actStep = spec.actStep - 1
		end
	else
		if spec.triggerPos == nil then
			spec.triggerNode = spec.frontNode
			spec.measureNode = spec.backNode
			dbgprint(spec.triggerNode, 3)
			dbgprint(spec.measureNode, 3)
			if spec.measureNode == nil then dbgprint("waitOnTrigger: measureNode is nil", 3); spec.measureNode = self.rootNode end
			if spec.triggerNode == nil then dbgprint("waitOnTrigger: triggerNode is nil", 3); spec.triggerNode = self.rootNode end
			spec.triggerPos = {}
			spec.triggerPos.x, spec.triggerPos.y, spec.triggerPos.z = getWorldTranslation(spec.triggerNode)
		end
		
		local triggerFlag = DebugFlag.new(1,0,0)
		local measureFlag = DebugFlag.new(0,1,0)
		
		local tx, _, tz = worldToLocal(self.rootNode, spec.triggerPos.x, 0, spec.triggerPos.z)
		
		if spec.debugFlag then
			triggerFlag:create(spec.triggerPos.x, spec.triggerPos.y, spec.triggerPos.z, tx * 0.3, tz * 0.3)
			triggerFlag:draw()
		end
	
		local  wx, wy, wz = getWorldTranslation(spec.measureNode)
		local mx, _, mz = worldToLocal(self.rootNode, wx, 0, wz)
		
		if spec.debugFlag then
			measureFlag:create(wx, wy, wz, mx * 0.3, mz * 0.3)
			measureFlag:draw()
		end
		
		local dist = math.abs(tz - mz)
		dbgprint("waitOnTrigger : dist: "..tostring(dist), 4)
	
		if dist <= 0.1 or spec.override then 
			dbgprint("waitOnTrigger: Condition met", 3)
			spec.triggerPos = nil
		else 
			spec.actStep = spec.actStep - 1
		end
	end
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

function HeadlandManagement.reduceSpeed(self, enable)	
	local spec = self.spec_HeadlandManagement
	local spec_drv = self.spec_drivable
	if spec_drv == nil then return; end;
	dbgprint("reduceSpeed : "..tostring(enable))
	if enable then
		spec.cruiseControlState = self:getCruiseControlState()
		dbgprint("reduceSpeed : cruiseControlState: "..tostring(spec.cruiseControlState))
		if spec.modSpeedControlFound and spec.useModSpeedControl and self.speedControl ~= nil then
			-- Use Mod Speedontrol
			spec.normSpeed = self.speedControl.currentKey or 2
			if spec.normSpeed ~= spec.turnSpeed then
				dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.turnSpeed))
				FS22_SpeedControl.SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.turnSpeed), true, false, false)
			end
		else
			-- Use Vanilla Speedcontrol
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
			-- Use Mod Speedontrol
				dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.normSpeed))
				FS22_SpeedControl.SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.normSpeed), true, false, false)
			end
		else
			-- Use Vanilla Speedcontrol
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

function HeadlandManagement.raiseImplements(self, raise, turnPlow, centerPlow, round, front, back)
	-- round 1: raise/lower implement
	-- round 2: turn plow
	local spec = self.spec_HeadlandManagement
    dbgprint("raiseImplements : raise: "..tostring(raise).." / turnPlow: "..tostring(turnPlow).." / round: "..tostring(round).." / front: "..tostring(front).." / back: "..tostring(back))
    
    local waitTime = 0
	local allImplements = self:getRootVehicle():getChildVehicles()
	
	dbgprint("raiseImplements : #allImplements = "..tostring(#allImplements), 2)
    
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
				dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName()..") allows lowering, is PickUp or is foldable", 2)
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
					-- if actImplement.spec_plow == nil then
					--	moveTime = 0
					-- end
					waitTime = math.max(waitTime, moveTime)
				else 
					print("HeadlandManagement :: raiseImplement : AttacherVehicle not set: Function restricted to first attacher joint")
					backImpl = true
				end
				
				if (frontImpl and spec.useRaiseImplementF and front) or (backImpl and spec.useRaiseImplementB and back) then
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
							-- if not centerPlow then
							--	 waitTime = 0
							-- end
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
					if round == 1 and ((frontImpl and front) or (backImpl and back)) and spec.useRidgeMarker and actImplement ~= nil and actImplement.spec_ridgeMarker ~= nil then
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
		 			dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName()..") don't allows lowering, is no PickUp and is not foldable", 2)
		 		end
		 	end
		else
			if actImplement ~= nil and front then
				-- Possible potato harvester with fixed cutter or mower like BigM? Raise and lower anyways...
				dbgprint("raiseImplements : implement #"..tostring(index).." ("..actImplement:getName().."): actImplement.getAllowsLowering == nil", 2)
				if actImplement.getAttachedAIImplements ~= nil and (actImplement.spec_combine ~= nil or actImplement.spec_mower ~= nil) then
					if raise then
						for _, implement in pairs(actImplement:getAttachedAIImplements()) do
						dbgprint("raiseImplements : aiImplementEndLine")
						implement.object:aiImplementEndLine()
						end
						actImplement:raiseStateChange(Vehicle.STATE_CHANGE_AI_END_LINE)
					else
						for _, implement in pairs(actImplement:getAttachedAIImplements()) do
							dbgprint("raiseImplements : aiImplementStartLine")
							implement.object:aiImplementStartLine()
						end
						actImplement:raiseStateChange(Vehicle.STATE_CHANGE_AI_START_LINE)
					end
				else
					dbgprint("raiseImplements : actImplement is no combine and no mower or has no aiImplements", 2)
				end
			else
				dbgprint("raiseImplements : implement #"..tostring(index)..": actImplement == nil", 2)
			end
		end
	end
	return waitTime
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
	
	if spec.gpsSetting == 1 and spec.modEVFound then
		local evStatus = self.vData.is[5]
		if evStatus then
			spec.gpsSetting = 6
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
	if spec.modVCAFound and spec.gpsSetting ~= 2 and spec.gpsSetting < 6 and enable then
		spec.vcaStatus = self:vcaGetState("snapIsOn")
		if spec.vcaStatus then 
			if spec.gpsSetting == 1 or spec.gpsSetting == 3 then
				dbgprint("stopGPS : VCA-GPS off")
				self:vcaSetState( "snapIsOn", false )
			else
				if spec.gpsSetting == 4 then 
					if self.vcaSnapReverseLeft ~= nil then 
						self:vcaSnapReverseLeft()
						--spec.vcaTurnHeading = (spec.heading + 180) % 360
						dbgprint("stopGPS : VCA-GPS turn left")
					end
				else
					if self.vcaSnapReverseRight ~= nil then 
						self:vcaSnapReverseRight() 
						--spec.vcaTurnHeading = (spec.heading + 180) % 360
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
		else
			spec.gpsSetting = 4
		end
	end
	
-- Part 4: Enhanced Vehicle
	dbgprint("spec.gpsSetting: "..tostring(spec.gpsSetting))
	if spec.modEVFound and spec.gpsSetting >= 6 and enable and not spec.useEVTrigger then
		spec.evStatus = self.vData.is[5]
		spec.evTrack = self.vData.is[6]
		if spec.evStatus then
			dbgprint("stopGPS : EV-GPS off")
			if spec.gpsSetting < 7 then spec.gpsSetting = 6 end
			if spec.evTrack and spec.gpsSetting == 7 then
				FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_SNAP_REVERSE", 1, nil, nil, nil)
			else
				FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_SNAP_ONOFF", 1, nil, nil, nil)
			end
		end
	end
	if spec.modEVFound and (spec.gpsSetting == 6 and not enable or spec.useEVTrigger) then
		if spec.evStatus and not self.vData.is[5] then
			dbgprint("stopGPS : EV-GPS on")
			FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_SNAP_ONOFF", 1, nil, nil, nil)
			spec.evStatus = false
		end	
		if spec.wasGPSAutomatic then
			spec.gpsSetting = 1
			spec.wasGPSAutomatic = false
		end
	end
end

function HeadlandManagement.disableDiffLock(self, disable, EV)
	local spec = self.spec_HeadlandManagement
	local useEV = EV or false
	if useEV and (self.vData == nil or self.vData.want == nil) then
		dbgprint("DisableDiffLock: EV not usable")
		return
	end
	if useEV then
		-- EnhancedVehicle diff-control
		if disable then
			spec.diffStateF = self.vData.want[1] or false
			spec.diffStateB = self.vData.want[2] or false
			if spec.diffStateF then 
				dbgprint("disableDiffLock : EV DiffLockF off")
				FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_FD", 1, nil, nil, nil)
			end
			if spec.diffStateB then 
				dbgprint("disableDiffLock : EV DiffLockB off")
				FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_BD", 1, nil, nil, nil)
			end
		else
			if spec.diffStateF then 
				dbgprint("disableDiffLock : EV DiffLockF on")
				if not self.vData.is[1] then FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_FD", 1, nil, nil, nil) end
			end
			if spec.diffStateB then 
				dbgprint("disableDiffLock : EV DiffLockB on")
				if not self.vData.is[2] then FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall(self, "FS22_EnhancedVehicle_RD", 1, nil, nil, nil) end
			end
		end
	else
		-- VCA diff-control
		if disable then
			spec.diffStateF = self:vcaGetState("diffLockFront") --self.vcaDiffLockFront
			spec.diffStateB = self:vcaGetState("diffLockBack") --self.vcaDiffLockBack
			if spec.diffStateF then 
				dbgprint("disableDiffLock : VCA DiffLockF off")
				self:vcaSetState("diffLockFront", false)
			end
			if spec.diffStateB then 
				dbgprint("disableDiffLock : VCA DiffLockB off")
				self:vcaSetState("diffLockBack", false)
			end
		else
			dbgprint("disableDiffLock : VCA DiffLock reset")
			self:vcaSetState("diffLockFront", spec.diffStateF)
			self:vcaSetState("diffLockBack", spec.diffStateB)
		end
	end
end
