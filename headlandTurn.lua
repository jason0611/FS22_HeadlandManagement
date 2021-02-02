--
-- FillLevel Warning for LS 19
--
-- Martin Eller
-- Version 0.0.1.1
-- 
-- MP Preparations
--

headlandTurn = {}
headlandTurn.MOD_NAME = g_currentModName

headlandTurn.REDUCESPEED = 1
headlandTurn.RAISEIMPLEMENT = 2
headlandTurn.STOPGPS = 3

function headlandTurn.prerequisitesPresent(specializations)
  return true
end

function headlandTurn.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", headlandTurn)
--  SpecializationUtil.registerEventListener(vehicleType, "onReadStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", headlandTurn)
end

function headlandTurn:onLoad(savegame)
	local spec = self.spec_headlandTurn
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	self.hltNormSpeed = 20
	self.hltTurnSpeed = 5

	self.hltActStep = 0
	self.hltMaxStep = 4
	
	self.hltIsActive = false
	self.hltAction = {}
	
	self.hltModSpeedControlFound = false
	self.hltUseSpeedControl = true
	
	self.hltUseRaiseImplement = true
	self.hltImplementsTable = {}
	self.hltUseTurnPlow = true
	
	self.hltModGuidanceSteeringFound = false
	self.hltUseGuidanceSteering = false	
end

function headlandTurn:onPostLoad(savegame)
	local spec = self.spec_headlandTurn
	if spec == nil then return end

	if savegame ~= nil then	
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".headlandTurn"
	
		self.hltTurnSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key.."#turnSpeed"), self.hltTurnSpeed)
		self.hltIsActive = Utils.getNoNil(getXMLBool(xmlFile, key.."#isActive"), self.hltIsActive)
		self.hltUseSpeedControl = Utils.getNoNil(getXMLBool(xmlFile, key.."#useSpeedControl", self.hltUseSpeedControl)
		self.hltUseRaiseImplement = Utils.getNoNil(getXMLBool(xmlFile, key.."#useRaiseImplement", self.hltUseRaiseImplement))
--		self.hltUseGuidanceSteering = Utils.getNoNil(getXMLBool(xmlFile, key.."#useGuidanceSteering", self.hltUseGuidanceSteering))
		self.hltUseTurnPlow = Utils.getNoNil(getXMLBool(xmlFile, key.."#turnPlow", self.hltUseTurnPlow))
		print("HeadlandTurn: Loaded data for "..self:getName())
	end
	
	-- Check if Mod SpeedControl exists
	if SpeedControl ~= nil and SpeedControl.onInputAction ~= nil then 
		self.hltModSpeedControlFound = true 
		self.hltUseSpeedControl = true
		self.hltTurnSpeed = 1 --SpeedControl Mode 1
		self.hltNormSpeed = 2 --SpeedControl Mode 2
	end
	
	-- Check if Mod GuidanceSteering exists
	local gsSpec = self.spec_globalPositioningSystem
	if gsSpec ~= nil then
		self.hltModGuidanceSteeringFound = true
	end

	self.hltAction[headlandTurn.REDUCESPEED] = self.hltModSpeedControlFound and self.hltUseSpeedControl
	self.hltAction[headlandTurn.RAISEIMPLEMENT] = self.hltUseRaiseImplement
	self.hltAction[headlandTurn.STOPGPS] = self.hltModGuidanceSteeringFound and self.hltUseGuidanceSteering
end

function headlandTurn:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key.."#turnSpeed", self.hltTurnSpeed)
	setXMLBool(xmlFile, key.."#isActive", self.hltIsActive)
	setXMLBool(xmlFile, key.."#useSpeedControl", self.hltUseSpeedControl)
	setXMLBool(xmlFile, key.."#useRaiseImplement", self.hltUseRaiseImplement)
--	setXMLBool(xmlFile, key.."#useGuidanceSteering", self.hltUseGuidanceSteering)
	setXMLBool(xmlFile, key.."#turnPlow", self.hltUseTurnPlow)
end

function headlandTurn:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		headlandTurn.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;	
			_, actionEventId = self:addActionEvent(headlandTurn.actionEvents, 'HLT_ACTIVATE', self, headlandTurn.TOGGLESTATE, false, true, false, true, nil)
		end		
	end
end

function headlandTurn:onReadStream(streamId, connection)
--	self.alertMode = streamReadInt8(streamId)
--	self.loud = streamReadInt8(streamId)
end

function headlandTurn:onWriteStream(streamId, connection)
--	streamWriteInt8(streamId, self.alertMode)
--	streamWriteInt8(streamId, self.loud)
end
	
function headlandTurn:onReadUpdateStream(streamId, timestamp, connection)
--	if not connection:getIsServer() then
--		local spec = spec.spec_fillLevelWarning
--		if streamReadBool(streamId) then
--			self.alertMode = streamReadInt8(streamId)
--			self.loud = streamReadInt8(streamId)
--		end;
--	end
end

function headlandTurn:onWriteUpdateStream(streamId, connection, dirtyMask)
--	if connection:getIsServer() then
--		local spec = self.spec_fillLevelWarning
--		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
--			streamWriteInt8(streamId, self.alertMode)
--			streamWriteInt8(streamId, self.loud)
--		end
--	end
end
	
function headlandTurn:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		headlandTurn.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;
			_, actionEventId = self:addActionEvent(headlandTurn.actionEvents, 'HLT_TOGGLESTATE', self, headlandTurn.TOGGLESTATE, false, true, false, true, nil)
		end		
	end
end

function headlandTurn:TOGGLESTATE(actionName, keyStatus, arg3, arg4, arg5)
	local spec = self.spec_headlandTurn
	
	-- anschalten, wenn vollständig inaktiv
	if not self.hltIsActive then
		self.hltActStep = 1
		self.hltIsActive = true
		print("headlandTurn: Activation initiated")
	-- abschalten, wenn vollständig aktiv
	elseif self.hltIsActive and self.hltActStep	== self.hltMaxStep then
		self.hltActStep = -self.hltMaxStep
		print(self.hltActStep)
		print("headlandTurn: Deactivation initiated")
	end
	
--	self:raiseDirtyFlags(spec.dirtyFlag)
end

function headlandTurn:onUpdate(dt)
	if self:getIsActive() and self.hltIsActive and self.hltActStep<self.hltMaxStep then
		print(hltActStep)
		if self.hltAction[math.abs(self.hltActStep)] then 		
			-- Activation
			if self.hltActStep == headlandTurn.REDUCESPEED and self.hltAction[headlandTurn.REDUCESPEED] then headlandTurn:reduceSpeed(self, true); end
			if self.hltActStep == headlandTurn.RAISEIMPLEMENT and self.hltAction[headlandTurn.RAISEIMPLEMENT] then headlandTurn:raiseImplements(self, true, self.hltUseTurnPlow); end
			if self.hltActStep == headlandTurn.STOPGPS and self.hltAction[headlandTurn.STOPGPS] then headlandTurn:stopGPS(self, true); end
			-- Deactivation
			if self.hltActStep == -headlandTurn.STOPGPS and self.hltAction[headlandTurn.STOPGPS] then headlandTurn:stopGPS(self, false); end
			if self.hltActStep == -headlandTurn.RAISEIMPLEMENT and self.hltAction[headlandTurn.RAISEIMPLEMENT] then headlandTurn:raiseImplements(self, false); end
			if self.hltActStep == -headlandTurn.REDUCESPEED and self.hltAction[headlandTurn.REDUCESPEED] then headlandTurn:reduceSpeed(self, false); end		
		end
		
		self.hltActStep = self.hltActStep + 1
		if self.hltActStep == 0 then self.hltIsActive = false; end
	end
end
	
function headlandTurn:reduceSpeed(self, enable)	
	if enable then
		if self.hltUseSpeedControl then
			SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(self.hltTurnSpeed), true, false, false)
		else
			self.hltNormSpeed = self:getCruiseControlSpeed()
			self:setCruiseControlMaxSpeed(self.hltTurnSpeed)
		end
	else
		if self.hltUseSpeedControl then
			SpeedControl.onInputAction(self, "SPEEDCONTROL_SPEED"..tostring(self.hltNormSpeed), true, false, false)
		else
			self:setCruiseControlMaxSpeed(self.hltNormSpeed)
		end
	end
end

function headlandTurn:raiseImplements(self, raise, turnPlow)
    local jointSpec = self.spec_attacherJoints
    for _,attachedImplement in pairs(jointSpec.attachedImplements) do
    	local index = attachedImplement.jointDescIndex
    	local actImplement = attachedImplement.object
		if actImplement ~= nil and actImplement.getAllowsLowering ~= nil then
			if actImplement:getAllowsLowering() or actImplement.spec_pickup ~= nil or actImplement.spec_foldable ~= nil then
				if raise then
					local lowered = actImplement:getIsLowered()
					self.hltImplementsTable[index] = lowered
					if lowered and actImplement.setLoweredAll ~= nil then 
						actImplement:setLoweredAll(false, index)
						lowered = actImplement:getIsLowered()
		 			end
		 			if lowered and actImplement.setLowered ~= nil then
		 				actImplement:setLowered(false)
		 				lowered = actImplement:getIsLowered()
		 			end
		 			if lowered and self.setJointMoveDown ~= nil then
		 				self:setJointMoveDown(index, false)
		 				lowered = actImplement:getIsLowered()
		 			end
		 			if lowered and actImplement.spec_attacherJointControlPlow ~= nil then
		 				local spec = actImplement.spec_attacherJointControl
		 				spec.heightTargetAlpha = spec.jointDesc.upperAlpha
				        actImplement:requestActionEventUpdate()
				    	lowered = actImplement:getIsLowered()
				    end
				    if lowered and actImplement.spec_attacherJointControlCutter~= nil then
		 				local spec = actImplement.spec_attacherJointControl
		 				spec.heightTargetAlpha = spec.jointDesc.upperAlpha
				        actImplement:requestActionEventUpdate()
				    	lowered = actImplement:getIsLowered()
				    end
				    if lowered and actImplement.spec_attacherJointControlCultivator~= nil then
		 				local spec = actImplement.spec_attacherJointControl
		 				spec.heightTargetAlpha = spec.jointDesc.upperAlpha
				        actImplement:requestActionEventUpdate()
				    	lowered = actImplement:getIsLowered()
				    end
		 			if lowered then
		 				print("headlandTurn: Info: Could not raise implement")
		 			end
		 			local plowSpec = actImplement.spec_plow
		 			if plowSpec ~= nil and turnPlow then 
						if plowSpec.rotationPart.turnAnimation ~= nil then
					        if actImplement:getIsPlowRotationAllowed() then
					            actImplement:setRotationMax(not plowSpec.rotationMax)
					        end
					    end
		 			end
		 		else
		 			local wasLowered = self.hltImplementsTable[index]
		 			if wasLowered and actImplement.setLoweredAll ~= nil then
		 				actImplement:setLoweredAll(true, index)
		 				wasLowered = actImplement:getIsLowered()
		 			end
		 			if not wasLowered and actImplement.setLowered ~= nil then
		 				actImplement:setLowered(true)
		 				wasLowered = actImplement:getIsLowered()
		 			end
		 			if not wasLowered and self.setJointMoveDown ~= nil then
		 				self:setJointMoveDown(index, true)
		 				wasLowered = actImplement:getIsLowered()
		 			end
		 			if not wasLowered and actImplement.spec_attacherJointControlPlow ~= nil then
		 				local spec = actImplement.spec_attacherJointControl
		 				spec.heightTargetAlpha = spec.jointDesc.lowerAlpha
				        actImplement:requestActionEventUpdate()
				    	wasLowered = actImplement:getIsLowered()
				    end
				    if not wasLowered and actImplement.spec_attacherJointControlCutter ~= nil then
		 				local spec = actImplement.spec_attacherJointControl
		 				spec.heightTargetAlpha = spec.jointDesc.lowerAlpha
				        actImplement:requestActionEventUpdate()
				    	wasLowered = actImplement:getIsLowered()
				    end
				    if not wasLowered and actImplement.spec_attacherJointControlCultivator ~= nil then
		 				local spec = actImplement.spec_attacherJointControl
		 				spec.heightTargetAlpha = spec.jointDesc.lowerAlpha
				        actImplement:requestActionEventUpdate()
				    	wasLowered = actImplement:getIsLowered()
				    end
		 			if not wasLowered then
		 				print("headlandTurn: Info: Could not lower implement")
		 			end
		 		end	
		 	end
		end
	end
end

function headlandTurn:stopGPS(self, enable)
	local gsSpec = self.spec_globalPositioningSystem
	if enable then
		print("headlandTurn: stopGPS")
		gsSpec.guidanceSteeringIsActive = false
		self:onSteeringStateChanged(false)
	else
		print("headlandTurn: startGPS")	
		gsSpec.guidanceSteeringIsActive = true
		self:onSteeringStateChanged(true)
	end
end























