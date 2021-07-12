--
-- Headland Management for LS 19
--
-- Martin Eller
-- Version 0.2.1.5
-- 
-- Turn plow full or turn plow half configurable
--

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(g_currentModName, true)
GMSDebug:enableConsoleCommands("hlmDebug")

headlandManagement = {}
headlandManagement.MOD_NAME = g_currentModName

headlandManagement.REDUCESPEED = 1
headlandManagement.DIFFLOCK = 2
headlandManagement.RAISEIMPLEMENT = 3
headlandManagement.STOPGPS = 4

headlandManagement.isDedi = g_dedicatedServerInfo ~= nil

headlandManagement.BEEPSOUND = createSample("HLMBEEP")
loadSample(headlandManagement.BEEPSOUND, g_currentModDirectory.."sound/beep.ogg", false)

headlandManagement.guiIcon = createImageOverlay(g_currentModDirectory.."gui/hlm_gui.dds")

addConsoleCommand("hlmToggleAction", "Toggle HeadlandManagement settings: ", "toggleAction", headlandManagement)
function headlandManagement:toggleAction(hlmAction)
	
	local vehicle = g_currentMission.controlledVehicle
	
	if hlmAction == nil then
		return "hlmToggleAction <Speed|Diffs|Raise|Plow|PlowHalf|PTO|Ridgemarker|GPS|Beep>"
	end
	
	local spec = vehicle.spec_headlandManagement
	if spec == nil then	
		return "No Headland Management installed"
	end
	
	if hlmAction == "Speed" then 
		spec.UseSpeedControl = not spec.UseSpeedControl
		return "Speedcontrol set to "..tostring(spec.UseSpeedControl)
	end
	
	if hlmAction == "Diffs" then
		spec.UseDiffLock = not spec.UseDiffLock and spec.ModVCAFound
		return "DiffLock set to "..tostring(spec.UseDiffLock)
	end
	
	if hlmAction == "Raise" then
		spec.UseRaiseImplement = not spec.UseRaiseImplement
		return "RaiseImplement set to "..tostring(spec.UseRaiseImplement)
	end
	
	if hlmAction == "Plow" then
		spec.UseTurnPlow = not spec.UseTurnPlow
		return "TurnPlow set to "..tostring(spec.UseTurnPlow)
	end
	
	if hlmAction == "PlowHalf" then
		spec.TurnPlowHalf = not spec.TurnPlowHalf
		return "TurnPlowHalf set to "..tostring(spec.TurnPlowHalf)
	end
	
	if hlmAction == "PTO" then
		spec.UseStopPTO = not spec.UseStopPTO
		return "PTO set to "..tostring(spec.UseStopPTO)
	end
	
	if hlmAction == "Ridgemarker" then
		spec.UseRidgeMarker = not spec.UseRidgeMarker
		return "RidgeMarker set to "..tostring(spec.UseRidgeMarker)
	end
	
	if hlmAction == "GPS" then
		spec.UseGPS = not spec.UseGPS and (spec.ModGuidanceSteeringFound or spec.ModVCAFound)
		return "GPS is set to "..tostring(spec.UseGPS)
	end
	
	if hlmAction == "Beep" then
		spec.Beep = not spec.Beep
		return "Beep is set to "..tostring(spec.Beep)
	end
end	


function headlandManagement.prerequisitesPresent(specializations)
  return true
end

function headlandManagement.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", headlandManagement)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", headlandManagement)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", headlandManagement)
end

function headlandManagement:onLoad(savegame)
	local spec = self.spec_headlandManagement
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	spec.timer = 0
	spec.Beep = true
	
	spec.NormSpeed = 20
	spec.TurnSpeed = 5

	spec.ActStep = 0
	spec.MaxStep = 5
	
	spec.IsActive = false
	spec.Action = {}
	spec.Action[0] =false
	
	spec.UseSpeedControl = true
	spec.ModSpeedControlFound = false
	spec.UseModSpeedControl = true
	
	spec.UseRaiseImplement = true
	spec.ImplementStatusTable = {}
	spec.ImplementPTOTable = {}
	spec.UseStopPTO = true
	spec.UseTurnPlow = true
	spec.TurnPlowHalf = true
	spec.PlowRotationMax = nil
	
	spec.UseRidgeMarker = true
	spec.RidgeMarkerStatus = 0
	
	spec.UseGPS = true
	spec.ModGuidanceSteeringFound = false
	spec.UseGuidanceSteering = true	
	spec.GSStatus = false
	spec.ModVCAFound = false
	spec.UseVCA = true
	spec.VCAStatus = false
	
	spec.UseDiffLock = true
	spec.DiffStateF = false
	spec.DiffStateB = false
end

function headlandManagement:onPostLoad(savegame)
	local spec = self.spec_headlandManagement
	if spec == nil then return end
	
	-- Check if Mod SpeedControl exists
	if SpeedControl ~= nil and SpeedControl.onInputAction ~= nil then 
		spec.ModSpeedControlFound = true 
		spec.UseSpeedControl = true
		spec.TurnSpeed = 1 --SpeedControl Mode 1
		spec.NormSpeed = 2 --SpeedControl Mode 2
	end
	
	-- Check if Mod GuidanceSteering exists
	spec.ModGuidanceSteeringFound = self.spec_globalPositioningSystem ~= nil
	
	-- Check if Mod VCA exists
	spec.ModVCAFound = self.vcaSetState ~= nil

	if savegame ~= nil then	
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".headlandManagement"
	
		spec.Beep = Utils.getNoNil(getXMLBool(xmlFile, key.."#beep"), spec.Beep)
		spec.TurnSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key.."#turnSpeed"), spec.TurnSpeed)
		spec.IsActive = Utils.getNoNil(getXMLBool(xmlFile, key.."#isActive"), spec.IsActive)
		spec.UseSpeedControl = Utils.getNoNil(getXMLBool(xmlFile, key.."#useSpeedControl"), spec.UseSpeedControl)
		spec.UseRaiseImplement = Utils.getNoNil(getXMLBool(xmlFile, key.."#useRaiseImplement"), spec.UseRaiseImplement)
		spec.UseStopPTO = Utils.getNoNil(getXMLBool(xmlFile, key.."#useStopPTO"), spec.UseStopPTO)
		spec.UseGuidanceSteering = Utils.getNoNil(getXMLBool(xmlFile, key.."#useGuidanceSteering"), spec.UseGuidanceSteering)
		spec.UseTurnPlow = Utils.getNoNil(getXMLBool(xmlFile, key.."#turnPlow"), spec.UseTurnPlow)
		spec.TurnPlowHalf = Utils.getNoNil(getXMLBool(xmlFile, key.."#turnPlowHalf"), spec.TurnPlowHalf)
		spec.UseRidgeMarker = Utils.getNoNil(getXMLBool(xmlFile, key.."#switchRidge"), spec.UseRidgeMarker)
		print("HeadlandManagement: Loaded data for "..self:getName())
	end
	
	-- Set management actions
	spec.Action[headlandManagement.REDUCESPEED] = spec.UseSpeedControl
	spec.Action[headlandManagement.DIFFLOCK] = spec.ModVCAFound and spec.UseDiffLock
	spec.Action[headlandManagement.RAISEIMPLEMENT] = spec.UseRaiseImplement
	spec.Action[headlandManagement.STOPGPS] = (spec.ModGuidanceSteeringFound and spec.UseGuidanceSteering) or (spec.ModVCAFound and spec.UseVCA)
	
end

function headlandManagement:saveToXMLFile(xmlFile, key)
	local spec = self.spec_headlandManagement
	setXMLBool(xmlFile, key.."#beep", spec.Beep)
	setXMLFloat(xmlFile, key.."#turnSpeed", spec.TurnSpeed)
	setXMLBool(xmlFile, key.."#isActive", spec.IsActive)
	setXMLBool(xmlFile, key.."#useSpeedControl", spec.UseSpeedControl)
	setXMLBool(xmlFile, key.."#useRaiseImplement", spec.UseRaiseImplement)
	setXMLBool(xmlFile, key.."#useStopPTO", spec.UseStopPTO)
	setXMLBool(xmlFile, key.."#useGuidanceSteering", spec.UseGuidanceSteering)
	setXMLBool(xmlFile, key.."#turnPlow", spec.UseTurnPlow)
	setXMLBool(xmlFile, key.."#turnPlowHalf", spec.TurnPlowHalf)
	setXMLBool(xmlFile, key.."#switchRidge", spec.UseRidgeMarker)
end

function headlandManagement:onReadStream(streamId, connection)
	local spec = self.spec_headlandManagement
	spec.Beep = streamReadBool(streamId)
	spec.TurnSpeed = streamReadFloat32(streamId)
	spec.IsActive = streamReadBool(streamId)
	spec.UseSpeedControl = streamReadBool(streamId)
	spec.UseRaiseImplement = streamReadBool(streamId)
	spec.UseStopPTO = streamReadBool(streamId)
	spec.UseGuidanceSteering = streamReadBool(streamId)
	spec.UseTurnPlow = streamReadBool(streamId)
	spec.TurnPlowHalf = streamReadBool(streamId)
end

function headlandManagement:onWriteStream(streamId, connection)
	local spec = self.spec_headlandManagement
	streamWriteBool(streamId, spec.Beep)
	streamWriteFloat32(streamId, spec.TurnSpeed)
	streamWriteBool(streamId, spec.IsActive)
	streamWriteBool(streamId, spec.UseSpeedControl)
	streamWriteBool(streamId, spec.UseRaiseImplement)
	streamWriteBool(streamId, spec.UseStopPTO)
	streamWriteBool(streamId, spec.UseGuidanceSteering)
	streamWriteBool(streamId, spec.UseTurnPlow)
	streamWriteBool(streamId, spec.TurnPlowHalf)
end
	
function headlandManagement:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_headlandManagement
		if streamReadBool(streamId) then
			spec.Beep = streamReadBool(streamId)
			spec.TurnSpeed = streamReadFloat32(streamId)
			spec.ActStep = streamReadInt8(streamId)
			spec.IsActive = streamReadBool(streamId)
			spec.UseSpeedControl = streamReadBool(streamId)
			spec.UseRaiseImplement = streamReadBool(streamId)
			spec.UseStopPTO = streamReadBool(streamId)
			spec.UseGuidanceSteering = streamReadBool(streamId)
			spec.UseTurnPlow = streamReadBool(streamId)
			spec.TurnPlowHalf = streamReadBool(streamId)
		end;
	end
end

function headlandManagement:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_headlandManagement
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.Beep)
			streamWriteFloat32(streamId, spec.TurnSpeed)
			streamWriteInt8(streamId, spec.ActStep)
			streamWriteBool(streamId, spec.IsActive)
			streamWriteBool(streamId, spec.UseSpeedControl)
			streamWriteBool(streamId, spec.UseRaiseImplement)
			streamWriteBool(streamId, spec.UseStopPTO)
			streamWriteBool(streamId, spec.UseGuidanceSteering)
			streamWriteBool(streamId, spec.UseTurnPlow)
			streamWriteBool(streamId, spec.TurnPlowHalf)
		end
	end
end
	
function headlandManagement:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		headlandManagement.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;
			_, actionEventId = self:addActionEvent(headlandManagement.actionEvents, 'HLM_TOGGLESTATE', self, headlandManagement.TOGGLESTATE, false, true, false, true, nil)
			_, actionEventId = self:addActionEvent(headlandManagement.actionEvents, 'HLM_SWITCHON', self, headlandManagement.TOGGLESTATE, false, true, false, true, nil)
			_, actionEventId = self:addActionEvent(headlandManagement.actionEvents, 'HLM_SWITCHOFF', self, headlandManagement.TOGGLESTATE, false, true, false, true, nil)
		end		
	end
end

function headlandManagement:TOGGLESTATE(actionName, keyStatus, arg3, arg4, arg5)
	local spec = self.spec_headlandManagement
	dbgprint("TOGGLESTATE : spec:")
	dbgprint_r(spec)
	-- anschalten nur wenn inaktiv
	if not spec.IsActive and (actionName == "HLM_SWITCHON" or actionName == "HLM_TOGGLESTATE") then
		spec.IsActive = true
	-- abschalten nur wenn aktiv
	elseif spec.IsActive and (actionName == "HLM_SWITCHOFF" or actionName == "HLM_TOGGLESTATE") and spec.ActStep == spec.MaxStep then
		spec.ActStep = -spec.ActStep
	end
	self:raiseDirtyFlags(spec.dirtyFlag)
end

function headlandManagement:onUpdate(dt)
	local spec = self.spec_headlandManagement
	if self:getIsActive() and spec.IsActive and not headlandManagement.isDedi and spec.Beep then
		spec.timer = spec.timer + dt
		if spec.timer > 2000 then 
			dbgprint("onUpdate : Beep")
			playSample(headlandManagement.BEEPSOUND, 1, 0.5, 0, 0, 0)
			spec.timer = 0
		end	
	else
		spec.timer = 0
	end
	if self:getIsActive() and spec.IsActive and spec.ActStep<spec.MaxStep then
		if spec.Action[math.abs(spec.ActStep)] and not headlandManagement.isDedi then
			dbgprint("onUpdate : ActStep: "..tostring(spec.ActStep))
			-- Set management actions
			spec.Action[headlandManagement.REDUCESPEED] = spec.UseSpeedControl
			spec.Action[headlandManagement.DIFFLOCK] = spec.ModVCAFound and spec.UseDiffLock
			spec.Action[headlandManagement.RAISEIMPLEMENT] = spec.UseRaiseImplement
			spec.Action[headlandManagement.STOPGPS] = (spec.ModGuidanceSteeringFound and spec.UseGuidanceSteering) or (spec.ModVCAFound and spec.UseVCA)	
			
			-- Activation
			if spec.ActStep == headlandManagement.REDUCESPEED and spec.Action[headlandManagement.REDUCESPEED] then headlandManagement:reduceSpeed(self, true); end
			if spec.ActStep == headlandManagement.DIFFLOCK and spec.Action[headlandManagement.DIFFLOCK] then headlandManagement:disableDiffLock(self, true); end
			if spec.ActStep == headlandManagement.RAISEIMPLEMENT and spec.Action[headlandManagement.RAISEIMPLEMENT] then headlandManagement:raiseImplements(self, true, spec.UseTurnPlow, spec.UseStopPTO); end
			if spec.ActStep == headlandManagement.STOPGPS and spec.Action[headlandManagement.STOPGPS] then headlandManagement:stopGPS(self, true); end
			-- Deactivation
			if spec.ActStep == -headlandManagement.STOPGPS and spec.Action[headlandManagement.STOPGPS] then headlandManagement:stopGPS(self, false); end
			if spec.ActStep == -headlandManagement.RAISEIMPLEMENT and spec.Action[headlandManagement.RAISEIMPLEMENT] then headlandManagement:raiseImplements(self, false, spec.UseTurnPlow, spec.UseStopPTO); end
			if spec.ActStep == -headlandManagement.DIFFLOCK and spec.Action[headlandManagement.DIFFLOCK] then headlandManagement:disableDiffLock(self, false); end
			if spec.ActStep == -headlandManagement.REDUCESPEED and spec.Action[headlandManagement.REDUCESPEED] then headlandManagement:reduceSpeed(self, false); end		
		end
		spec.ActStep = spec.ActStep + 1
		if spec.ActStep == 0 then 
			spec.IsActive = false
			self:raiseDirtyFlags(spec.dirtyFlag)
		end	
	end
end

function headlandManagement:onDraw(dt)
	local spec = self.spec_headlandManagement

	if self:getIsActive() and spec.IsActive then 
		g_currentMission:addExtraPrintText(g_i18n:getText("text_HLM_isActive"))
	 
		local scale = g_gameSettings.uiScale
		
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX * 0.70
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY
		local w = 0.015 * scale
		local h = w * g_screenAspectRatio
		
		renderOverlay(headlandManagement.guiIcon, x, y, w, h)
	end
end
	
function headlandManagement:reduceSpeed(self, enable)	
	local spec = self.spec_headlandManagement
	dbgprint("reduceSpeed : "..tostring(enable))
	if enable then
		if spec.UseSpeedControl and spec.ModSpeedControlFound then
			dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.TurnSpeed))
			SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.TurnSpeed), true, false, false)
		else
			spec.NormSpeed = self:getCruiseControlSpeed()
			self:setCruiseControlMaxSpeed(spec.TurnSpeed)
			dbgprint("reduceSpeed : Set cruise control to "..tostring(spec.TurnSpeed))
		end
	else
		if spec.UseSpeedControl and spec.ModSpeedControlFound then
			dbgprint("reduceSpeed : ".."SPEEDCONTROL_SPEED"..tostring(spec.NormSpeed))
			SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(spec.NormSpeed), true, false, false)
		else
			self:setCruiseControlMaxSpeed(spec.NormSpeed)
			dbgprint("redceSpeed : Set cruise control back to "..tostring(spec.NormSpeed))
		end
	end
end

function headlandManagement:raiseImplements(self, raise, turnPlow, stopPTO)
	local spec = self.spec_headlandManagement
    local jointSpec = self.spec_attacherJoints
    dbgprint("raiseImplements : raise: "..tostring(raise).." / turnPlow: "..tostring(turnPlow).." / stopPTO: "..tostring(stopPTO))
    for _,attachedImplement in pairs(jointSpec.attachedImplements) do
    	local index = attachedImplement.jointDescIndex
    	local actImplement = attachedImplement.object
    	dbgprint("raiseImplements : actImplement: "..actImplement:getName())
		-- raise or lower implement and turn plow
		if actImplement ~= nil and actImplement.getAllowsLowering ~= nil then
			if actImplement:getAllowsLowering() or actImplement.spec_pickup ~= nil or actImplement.spec_foldable ~= nil then
				if raise then
					local lowered = actImplement:getIsLowered()
					local wasLowered = lowered
					spec.ImplementStatusTable[index] = wasLowered
					if lowered and actImplement.setLoweredAll ~= nil then 
						actImplement:setLoweredAll(false, index)
						lowered = actImplement:getIsLowered()
						dbgprint("raiseImplements : implement is raised by setLoweredAll: "..tostring(not lowered))
		 			end
		 			if lowered and actImplement.setLowered ~= nil then
		 				actImplement:setLowered(false)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is raised by setLowered: "..tostring(not lowered))
		 			end
		 			if lowered and self.setJointMoveDown ~= nil then
		 				self:setJointMoveDown(index, false)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is raised by setJointMoveDown: "..tostring(not lowered))
		 			end
		 			if lowered and (actImplement.spec_attacherJointControlPlow ~= nil or actImplement.spec_attacherJointControlCutter~= nil or actImplement.spec_attacherJointControlCultivator~= nil) then
		 				local implSpec = actImplement.spec_attacherJointControl
		 				implSpec.heightTargetAlpha = implSpec.jointDesc.upperAlpha
				        actImplement:requestActionEventUpdate()
				    	lowered = actImplement:getIsLowered()
				    	dbgprint("raiseImplements : implement is raised by heightTargetAlpha: "..tostring(not lowered))
				    end
				    if stopPTO then
				    	local active = actImplement.getIsPowerTakeOffActive ~= nil and actImplement:getIsPowerTakeOffActive() and actImplement.deactivate ~= nil
				    	spec.ImplementPTOTable[index] = active
				    	if active then actImplement:deactivate(); end
				    	dbgprint("raiseImplements : implement PTO stopped")
				    end
		 			local plowSpec = actImplement.spec_plow
		 			if plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and wasLowered then 
				        if actImplement:getIsPlowRotationAllowed() then
							spec.PlowRotationMaxNew = not plowSpec.rotationMax
							if spec.TurnPlowHalf then 
								actImplement:setRotationCenter()
								dbgprint("raiseImplements : plow is centered")
							else
								actImplement:setRotationMax(spec.PlowRotationMaxNew)
								spec.PlowRotationMaxNew = nil
								dbgprint("raiseImplements : plow is turned")
							end
				        end
		 			end
		 		else
		 			local wasLowered = spec.ImplementStatusTable[index]
		 			local lowered
		 			local plowSpec = actImplement.spec_plow
		 			if plowSpec ~= nil and plowSpec.rotationPart ~= nil and plowSpec.rotationPart.turnAnimation ~= nil and turnPlow and wasLowered and spec.PlowRotationMaxNew ~= nil then 
						actImplement:setRotationMax(spec.PlowRotationMaxNew)
						spec.PlowRotationMaxNew = nil
						dbgprint("raiseImplements : plow is turned")
					end
					if stopPTO then
				    	local active = spec.ImplementPTOTable[index]
				    	if active and actImplement.setIsTurnedOn ~= nil then actImplement:setIsTurnedOn(true); end -- actImplement:activate(); end
				    	dbgprint("raiseImplements : implement PTO started")
				    end
					if wasLowered and actImplement.setLoweredAll ~= nil then
		 				actImplement:setLoweredAll(true, index)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is lowered by setLoweredAll: "..tostring(lowered))
		 			end
		 			if wasLowered and not lowered and actImplement.setLowered ~= nil then
		 				actImplement:setLowered(true)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is lowered by setLowered: "..tostring(lowered))
		 			end
		 			if wasLowered and not lowered and self.setJointMoveDown ~= nil then
		 				self:setJointMoveDown(index, true)
		 				lowered = actImplement:getIsLowered()
		 				dbgprint("raiseImplements : implement is lowered by setJointMoveDown: "..tostring(lowered))
		 			end
		 			if wasLowered and not lowered and (actImplement.spec_attacherJointControlPlow ~= nil or actImplement.spec_attacherJointControlCutter~= nil or actImplement.spec_attacherJointControlCultivator~= nil) then
		 				local implSpec = actImplement.spec_attacherJointControl
		 				implSpec.heightTargetAlpha = implSpec.jointDesc.lowerAlpha
				        actImplement:requestActionEventUpdate()
				    	lowered = actImplement:getIsLowered()
				    	dbgprint("raiseImplements : implement is lowered by heightTargetAlpha: "..tostring(lowered))
				    end
		 		end	
		 	end
		end
		-- switch ridge marker
		if actImplement ~= nil and actImplement.spec_ridgeMarker ~= nil then
			local specRM = actImplement.spec_ridgeMarker
			if raise then
				spec.RidgeMarkerStatus = specRM.ridgeMarkerState
				if spec.RidgeMarkerStatus ~= 0 then
					actImplement:setRidgeMarkerState(0)
				end
			else
				if spec.RidgeMarkerStatus == 1 then 
					spec.RidgeMarkerStatus = 2 
				elseif spec.RidgeMarkerStatus == 2 then
		  			spec.RidgeMarkerStatus = 1
				end
				actImplement:setRidgeMarkerState(spec.RidgeMarkerStatus)
			end
			dbgprint("ridgeMarker: "..tostring(specRM.ridgeMarkerState))
		end
	end
end

function headlandManagement:stopGPS(self, enable)
	local spec = self.spec_headlandManagement
	dbgprint("stopGPS : "..tostring(enable))
-- Part 1: Guidance Steering	
	if spec.ModGuidanceSteeringFound then
		local gsSpec = self.spec_globalPositioningSystem
		dbgprint("stopGPS : Guidance Steering")
		if self.onSteeringStateChanged == nil then return; end
		if enable then
			local gpsEnabled = (gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive)
			if gpsEnabled then
				spec.GSStatus = true
				gsSpec.lastInputValues.guidanceSteeringIsActive = false
				self:onSteeringStateChanged(false)
			else
				spec.GSStatus = false
			end
		else
			local gpsEnabled = spec.GSStatus	
			if gpsEnabled then
				gsSpec.lastInputValues.guidanceSteeringIsActive = true
				self:onSteeringStateChanged(true)
			end
		end
	end
	
-- Part 2: Vehicle Control Addon (VCA)
	if spec.ModVCAFound and enable then
		spec.VCAStatus = self.vcaSnapIsOn
		if spec.VCAStatus then 
			dbgprint("stopGPS : VCA-GPS off")
			self:vcaSetState( "vcaLastSnapAngle", 10 )
			self:vcaSetState( "vcaLastSnapPosX", 0 )
			self:vcaSetState( "vcaLastSnapPosZ", 0 )
			self:vcaSetState( "vcaSnapIsOn", false )
		end
	end
	if spec.ModVCAFound and spec.VCAStatus and not enable then
		dbgprint("stopGPS : VCA-GPS on")
		self:vcaSetState( "vcaSnapIsOn", true )
		self:vcaSetSnapFactor()
	end
end

function headlandManagement:disableDiffLock(self, disable)
	local spec = self.spec_headlandManagement
	if not spec.ModVCAFound then 
		return
	end
	
	if disable then
		spec.DiffStateF = self.vcaDiffLockFront
		spec.DiffStateB = self.vcaDiffLockBack
		if spec.DiffStateF then 
			dbgprint("disableDiffLock : DiffLockF off")
			self:vcaSetState("vcaDiffLockFront", false)
		end
		if spec.DiffStateB then 
			dbgprint("disableDiffLock : DiffLockB off")
			self:vcaSetState("vcaDiffLockBack", false)
		end
	else
		dbgprint("disableDiffLock : DiffLock reset")
		self:vcaSetState("vcaDiffLockFront", spec.DiffStateF)
		self:vcaSetState("vcaDiffLockBack", spec.DiffStateB)
	end
end
