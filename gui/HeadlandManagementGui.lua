--
-- Headland Management for LS 19
--
-- Martin Eller
-- Version 0.3.0.1
-- 
-- Headlandmanagement GUI for configuration
--

HeadlandManagementGui = {}
local HeadlandManagementGui_mt = Class(HeadlandManagementGui, YesNoDialog)

dbgprint("HeadlandManagementGui : initializing")

-- reference to xml
HeadlandManagementGui.CONTROLS = {
	"guiTitle",
	
	"sectionSpeedControl",
	"speedControlOnOffTitle",
	"speedControlOnOffSetting",
	"speedControlUseSCModTitle",
	"speedControlUseSCModSetting",
	"speedControlTurnSpeedTitle",
	"speedControlTurnSpeedSetting",

	"sectionAlarm",
	"alarmTitle",
	"alarmSetting",
		
	"sectionImplementControl",
	"raiseTitle",
	"raiseSetting",
	"stopPtoTitle",
	"stopPtoSetting",
	"turnPlowTitle",
	"turnPlowSetting",
	"ridgeMarkerTitle",
	"ridgeMarkerSetting",
	
	"sectionGPSControl",
	"gpsOnOffTitle",
	"gpsOnOffSetting",
	"gpsUseGSTitle",
	"gpsUseGSSetting",
	"gpsUseVCATitle",
	"gpsUseVCASetting",
	
	"sectionDiffControl",
	"diffControlOnOffTitle",
	"diffControlOnOffSetting",
}

function HeadlandManagementGui:new()
	local gui = YesNoDialog:new(nil, HeadlandManagementGui_mt)
	gui:registerControls(HeadlandManagementGui.CONTROLS)
	return gui
end

-- set current values
function HeadlandManagementGui:setData(vehicleName, useSpeedControl, useModSpeedControl, turnSpeed, useRaiseImplement, useStopPTO, useTurnPlow, useCenterPlow, useRidgeMarker, useGPS, useGuidanceSteering, useVCA, useDiffLock, beep)
	-- Titel
	self.guiTitle:setText(g_i18n:getText("hlmgui_title")..vehicleName)

	-- SpeedControl
	self.speedControlOnOffTitle:setText("SpeedControl nutzen")
	self.speedControlOnOffSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.speedControlOnOffSetting:setState(useSpeedControl and 1 or 2)
	
	self.speedControlUseSCModTitle:setText("Mod SpeedControl nutzen")
	self.speedControlUseSCModSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.speedControlUseSCModSetting:setState(useModSpeedControl and 1 or 2)
	
	if not useModSpeedControl then
		self.speedControlTurnSpeedTitle:setText("Geschwindigkeit im Vorgewende")
		local speedTable = {}
		for n=1,40 do
			speedTable[n] = tostring(n)
		end
		self.speedControlTurnSpeedSetting:setTexts(speedTable)
		self.speedControlTurnSpeedSetting:setState(turnSpeed or 5)
	else	
		self.speedControlTurnSpeedTitle:setText("Tempomatstufe im Vorgewende")
		self.speedControlTurnSpeedSetting:setTexts({"1","2","3"})
		self.speedControlTurnSpeedSetting:setState(turnSpeed or 1)
	end

	-- AlertMode
	self.alarmTitle:setText("Akustischer Hinweis")
	self.alarmSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.alarmSetting:setState(beep and 1 or 2)
	
	-- Implement control
	self.raiseTitle:setText("Anbaugeräte ausheben")
	self.raiseSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.raiseSetting:setState(useRaiseImplement and 1 or 2)
	
	self.stopPtoTitle:setText("Zapfwelle anhalten")
	self.stopPtoSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.stopPtoSetting:setState(useStopPTO and 1 or 2)
	
	self.turnPlowTitle:setText("Pflug drehen")
	self.turnPlowSetting:setTexts({
		g_i18n:getText("hlmgui_plowFull"),
		g_i18n:getText("hlmgui_plowCenter"),
		g_i18n:getText("hlmgui_plowOff")
	})
	local plowState
	if useTurnPlow and not useCenterPlow then plowState = 1; end
	if useTurnPlow and useCenterPlow then plowState = 2; end
	if not useTurnPlow then plowState = 3; end
	self.turnPlowSetting:setState(plowState)
	
	self.ridgeMarkerTitle:setText("Spurreißer umschalten")
	self.ridgeMarkerSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.ridgeMarkerSetting:setState(useRidgeMarker and 1 or 2)
	
	-- GPS control
	self.gpsOnOffTitle:setText("GPS-Spurführung pausieren")
	self.gpsOnOffSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.gpsOnOffSetting:setState(useGPS and 1 or 2)
		
	self.gpsUseGSTitle:setText("Guidance Steering ansteuern")
	self.gpsUseGSSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.gpsUseGSSetting:setState(useGuidanceSteering and 1 or 2)
	
	self.gpsUseVCATitle:setText("VCA ansteuern")
	self.gpsUseVCASetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.gpsUseVCASetting:setState(useVCA and 1 or 2)

	-- Diff control
	self.diffControlOnOffTitle:setText("Differentialsperren lösen")
	self.diffControlOnOffSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.diffControlOnOffSetting:setState(useDiffLock and 1 or 2)
end

-- trim text if necessary
function HeadlandManagementGui:onTextChanged()
	local text = self.textElement:getText()

	-- trim if too long
	if #text > 10 then
		self.textElement:setText(text:sub(1,10))
	end
end

-- close gui and send new values to callback
function HeadlandManagementGui:onClickOk()
	local UseSpeedControl = self.speedControlOnOffSetting:getState() == 1
	local UseModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	local TurnSpeed = self.speedControlTurnSpeedSetting:getState() == 1
	local UseRaiseImplement = self.raiseSetting:getState() == 1
	local UseStopPTO = self.stopPtoSetting:getState() == 1
	local plowState = self.turnPlowSetting:getState()
	local useTurnPlow = (plowState < 3)
	local useCenterPlow = (plowState == 2)
	local UseRidgeMarker = self.ridgeMarkerSetting:getState() == 1
	local UseGPS = self.gpsOnOffSetting:getState() == 1
	local UseGuidanceSteering = self.gpsUseGSSetting:getState() == 1
	local UseVCA = self.gpsUseVCASetting:getState() == 1
	local UseDiffLock = self.diffControlOnOffSetting:getState() == 1
	local beep = self.alarmSetting:getState() == 1
	
	self:close()
	self.callbackFunc(self.target, useSpeedControl, useModSpeedControl, turnSpeed, useRaiseImplement, useStopPTO, useTurnPlow, useCenterPlow, useRidgeMarker, useGPS, useGuidanceSteering, useVCA, useDiffLock, beep)
end

-- just close gui
function HeadlandManagementGui:onClickBack()
	self:close()
end
