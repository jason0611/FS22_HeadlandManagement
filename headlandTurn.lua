--
-- FillLevel Warning for LS 19
--
-- Martin Eller
-- Version 0.0.0.1
-- 
--

headlandTurn = {}
headlandTurn.MOD_NAME = g_currentModName

function headlandTurn.prerequisitesPresent(specializations)
  return true
end

function headlandTurn.registerEventListeners(vehicleType)
--	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onLoad", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", headlandTurn)--  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", headlandTurn)
--  SpecializationUtil.registerEventListener(vehicleType, "onReadStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", headlandTurn)
--	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", headlandTurn)
end

function headlandTurn:onLoad(savegame)
--	local spec = self.spec_fillLevelWarning
--	self.RULaktive = false
--	self.BeepAktive1 = false
--    self.lastBeep = 0
--    self.thisBeep = 0
--	self.attacheble = hasXMLProperty(self.xmlFile, "vehicle.attachable")
--	self.brand = getXMLString (self.xmlFile, "vehicle.storeData.brand")
--	self.loud = 1
--    self.beepIntervall = 2000
--    
--    spec.dirtyFlag = self:getNextDirtyFlag()
--
----[[
--	alertMode:
--		+1 : Alert if vehicle gets full
--		 0 : Alert disabled
--		-1 : Alert if vehicle gets empty
----]]
--	self.alertMode = 0
--
--    fillType_DIESEL = g_fillTypeManager:getFillTypeIndexByName("DIESEL")
--    fillType_DEF = g_fillTypeManager:getFillTypeIndexByName("DEF")
--    fillType_AIR = g_fillTypeManager:getFillTypeIndexByName("AIR")
end

function headlandTurn:onPostLoad(savegame)
--	local spec = self.spec_fillLevelWarning
--	if spec == nil then return end
--	
--	if savegame ~= nil then	
--		local xmlFile = savegame.xmlFile
--		local key = savegame.key .. ".headlandTurn"
--		
--		self.alertMode = Utils.getNoNil(getXMLInt(xmlFile, key.."#alertMode"), self.alertMode)
--		self.loud = Utils.getNoNil(getXMLInt(xmlFile, key.."#alertUnmuted"), self.loud)
--		
--		print("FillLevelWarning: Loaded data for "..self:getName()..": AlertMode = "..tostring(self.alertMode).." / Unmuted = "..tostring(self.loud))
--	end
end

function headlandTurn:saveToXMLFile(xmlFile, key)
--	setXMLInt(xmlFile, key.."#alertMode", self.alertMode)
--	setXMLInt(xmlFile, key.."#alertUnmuted", self.loud)
end

function headlandTurn:onRegisterActionEvents(isActiveForInput)
--	if self.isClient then
--		headlandTurn.actionEvents = {} 
--		if self:getIsActiveForInput(true) then 
--			local actionEventId;
--			_, actionEventId = self:addActionEvent(headlandTurn.actionEvents, 'FLW_TOGGLESOUND', self, headlandTurn.TOGGLE_SOUND, false, true, false, true, nil)
--			_, actionEventId = self:addActionEvent(headlandTurn.actionEvents, 'FLW_TOGGLEMODE', self, headlandTurn.TOGGLE_MODE, false, true, false, true, nil)
--		end		
--	end
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
	
--[[
function headlandTurn:TOGGLE_MODE(actionName, keyStatus, arg3, arg4, arg5)
	local spec = self.spec_fillLevelWarning
	if self.alertMode == 1 then
		self.alertMode = -1
	elseif self.alertMode == 0 then
		self.alertMode = 1
	else
		self.alertMode = 0
	end
	self:raiseDirtyFlags(spec.dirtyFlag)
end
]]


function headlandTurn:onUpdate(dt)
--	
--	if self:getIsActive() and not self.attacheble then
--        local fillLevel,pickUpAlert = headlandTurn:getFillLevel(self)
--				
--		fillLevel = fillLevel * self.alertMode
--		if fillLevel<0 then 
--			fillLevel = fillLevel + 1	-- if decreasing mode: fillLevel=100%-fillLevel
--		end
--		
--		if self.alertMode ~= 0 and self:getIsActiveForInput() then
--			local modeText, muteText
--			if self.alertMode == 1 then
--				modeText = "Befüllung"
--			else
--				modeText = "Entleerung"
--			end
--			if self.loud == 0 then
--				muteText = "-- stumm geschaltet"
--			else
--				muteText = ""
--			end
--			g_currentMission:addExtraPrintText("Füllstandswarnung aktiv ("..modeText..") "..muteText)
--		end
--	 
--        if pickUpAlert then -- if pickUpAlert set, then trigger beep, but only if mode is active
--			fillLevel = math.abs(self.alertMode)
--		end
--		
--		if fillLevel> 0 then
--            self.thisBeep = self.thisBeep + dt
--				
--            if ((fillLevel>= 0.5) and (not self.BeepAktive1)) or ((fillLevel>= 0.9) and (self.thisBeep-self.lastBeep > self.beepIntervall)) then
--                if self:getIsEntered() then
--                	if fillLevel==1 then 
--                		self.beepIntervall = 1000 
--                	else 
--                		self.beepIntervall = 2000 
--                	end
--                    if self.brand == "AGCO" or self.brand == "FENDT" or self.brand == "MASSEYFERGUSON" or self.brand == "CHALLENGER" then
--                        playSample(AGCOBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                    elseif self.brand == "CLAAS" then
--                        playSample(ClaasBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                    elseif self.brand == "GRIMME" then
--                        playSample(GrimmeBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                    elseif self.brand == "HOLMER" then
--                        playSample(HolmerBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                    elseif self.brand == "JOHNDEERE" then
--                        playSample(JohnDeereSound ,self.loud ,self.loud*5 ,1 ,0 ,0)
--                    elseif self.brand == "NEWHOLLAND" or self.brand == "CASEIH" then
--                        playSample(NewHollandSound ,self.loud ,self.loud ,1 ,0 ,0)
--                    elseif self.brand == "ROPA" then
--                        playSample(RopaSound ,self.loud ,self.loud ,1 ,0 ,0)
--                    end
--                end
--                self.BeepAktive1 = true
--                self.lastBeep = self.thisBeep
--            end
--        
--            if fillLevel< 0.5 then
--                self.BeepAktive1 = false
--                self.lastBeep = 0
--                self.loud = 1
--            end
--
--            if not self.RULaktive and not pickUpAlert then
--                if fillLevel>= 0.8 then
--                    self:setBeaconLightsVisibility(true)
--                    if self:getIsEntered() then
--                        if self.brand == "AGCO" or self.brand == "FENDT" or self.brand == "MASSEYFERGUSON" or self.brand == "CHALLENGER" then
--                            playSample(AGCOBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        elseif self.brand == "CLAAS" then
--                            playSample(ClaasBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        elseif self.brand == "GRIMME" then
--                            playSample(GrimmeBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        elseif self.brand == "HOLMER" then
--                            playSample(HolmerBeepSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        elseif self.brand == "JOHNDEERE" then
--                            playSample(JohnDeereSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        elseif self.brand == "NEWHOLLAND" or self.brand == "CASEIH" then
--                            playSample(NewHollandSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        elseif self.brand == "ROPA" then
--                            playSample(RopaSound ,self.loud ,self.loud ,1 ,0 ,0)
--                        end
--                    end
--                self.RULaktive = true
--                end
--            else
--                if fillLevel< 0.8 then
--                    self:setBeaconLightsVisibility(false)
--                    self.RULaktive = false
--                end
--            end
--        end
--		g_inputBinding:setActionEventText(headlandTurn.actionEventId, Vehicle.togglesound)
--	end
end

