--
-- FillLevel Warning for LS 19
--
-- Martin Eller
-- Version 0.0.0.1
-- 
--

headlandTurn = {}
headlandTurn.MOD_NAME = g_currentModName

headlandTurn.REDUCESPEED = 1
headlandTurn.RAISEFRONTIMPLEMENT = 2
headlandTurn.RAISEBACKIMPLEMENT = 3
headlandTurn.STOPGPS = 4

function headlandTurn.prerequisitesPresent(specializations)
  return true
end

function headlandTurn.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", headlandTurn)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", headlandTurn)
--  SpecializationUtil.registerEventListener(vehicleType, "onReadStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", headlandTurn)
end

function headlandTurn:onLoad(savegame)
	local spec = self.spec_headlandTurn
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	self.hltTurnSpeed = 5
	self.hltIsActive = false
	
	self.hltActStep = 0
	self.hltMaxStep = 4
	
	self.hltAction = {}

	self.hltNormSpeed = 0
	
	self.hltModSpeedControlFound = false
	self.hltUseSpeedControl = true
	
	self.hltModGuidanceSteeringFound = false
	self.hltUseGuidanceSteering = true
end

function headlandTurn:onPostLoad(savegame)
	local spec = self.spec_headlandTurn
	if spec == nil then return end

	if savegame ~= nil then	
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".headlandTurn"
	
		self.hltTurnSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key.."#hltTurnSpeed"), self.hltTurnSpeed)
		self.hltIsActive = Utils.getNoNil(getXMLBool(xmlFile, key.."#hltIsActive"), self.hltIsActive)
	
		print("HeadlandTurn: Loaded data for "..self:getName()..": hltTurnSpeed = "..tostring(self.hltTurnSpeed).." / hltIsActive = "..tostring(self.hltIsActive))
	end
	
	-- Check if Mod SpeedControl exists
	if SpeedControl ~= nil and SpeedControl.onInputAction ~= nil then 
		self.hltModSpeedControlFound = true 
		self.hltUseSpeedControl = true
		self.hltTurnSpeed = 1
		self.hltNormSpeed = 2
		print("headlandTurn: Mod SpeedControl found!")
	end
	
	-- Check if Mod GuidanceSteering exists
	if GlobalPositioningSystem ~= nil and GlobalPositioningSystem.actionEventEnableSteering ~= nil then
		self.hltModGuidanceSteeringFound = true
		print("headlandTurn: Mod GuidanceSteering found!")
	end

	self.hltAction[headlandTurn.REDUCESPEED] = self.hltModSpeedControlFound and self.hltUseSpeedControl
	self.hltAction[headlandTurn.RAISEFRONTIMPLEMENT] = false
	self.hltAction[headlandTurn.RAISEBACKIMPLEMENT] = false
	self.hltAction[headlandTurn.STOPGPS] = self.hltModGuidanceSteeringFound and self.hltUseGuidanceSteering
end

function headlandTurn:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key.."#hltTurnSpeed", self.hltTurnSpeed)
	setXMLBool(xmlFile, key.."#hltIsActive", self.hltIsActive)
end

function headlandTurn:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		headlandTurn.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;	
			_, actionEventId = self:addActionEvent(headlandTurn.actionEvents, 'HLT_ACTIVATE', self, headlandTurn.TOGGLESTATE, false, true, false, true, nil)
			print("headlandTurn: Event registered")
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

	if self:getIsActive() then

	end
	
	if self:getIsActive() and self.hltIsActive and self.hltActStep<self.hltMaxStep then
		
		if self.hltAction[math.abs(self.hltActStep)] then 		
			-- Activation
			if self.hltActStep == headlandTurn.REDUCESPEED and self.hltAction[headlandTurn.REDUCESPEED] then headlandTurn:reduceSpeed(self, true); end
			if self.hltActStep == headlandTurn.RAISEFRONTIMPLEMENT and self.hltAction[headlandTurn.RAISEFRONTIMPLEMENT] then headlandTurn:raiseFrontImplement(self, true); end
			if self.hltActStep == headlandTurn.RAISEBACKIMPLEMENT and self.hltAction[headlandTurn.RAISEBACKIMPLEMENT] then headlandTurn:raiseBackImplement(self, true); end
			if self.hltActStep == headlandTurn.STOPGPS and self.hltAction[headlandTurn.STOPGPS] then headlandTurn:stopGPS(self, true); end
		
			-- Deactivation
			if self.hltActStep == -headlandTurn.STOPGPS and self.hltAction[headlandTurn.STOPGPS] then headlandTurn:stopGPS(self, false); end
			if self.hltActStep == -headlandTurn.RAISEBACKIMPLEMENT and self.hltAction[headlandTurn.RAISEBACKIMPLEMENT] then headlandTurn:raiseBackImplement(self, false); end
			if self.hltActStep == -headlandTurn.RAISEFRONTIMPLEMENT and self.hltAction[headlandTurn.RAISEFRONTIMPLEMENT] then headlandTurn:raiseFrontImplement(self, false); end
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

function headlandTurn:raiseFrontImplement(vehicle, enable)
end

function headlandTurn:raiseBackImplement(vehicle, enable)
end

function headlandTurn:stopGPS(vehicle, enable)
	if enable then
		GlobalPositioningSystem.actionEventEnableSteering()
end























