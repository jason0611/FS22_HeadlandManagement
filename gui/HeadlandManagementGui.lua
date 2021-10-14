--
-- Headland Management for LS 19
--
-- Jason06 / Glowins Modschmiede
-- Version 1.0.1.0
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
	"speedControlTurnSpeedTitle1",
	"speedControlTurnSpeedSetting1",
	"speedControlTurnSpeedTitle2",
	"speedControlTurnSpeedSetting2",

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
	"gpsSettingTitle",
	"gpsSetting",
	"gpsAutoTriggerTitle",
	"gpsAutoTriggerSetting",
	
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
function HeadlandManagementGui:setData(vehicleName, useSpeedControl, useModSpeedControl, turnSpeed, useRaiseImplement, useStopPTO, useTurnPlow, useCenterPlow, useRidgeMarker, useGPS, gpsSetting, useGuidanceSteering, useGuidanceSteeringTrigger, useVCA, useDiffLock, beep, modSpeedControlFound, modGuidanceSteeringFound, modVCAFound)
	
	self.modSpeedControlFound = modSpeedControlFound
	self.modGuidanceSteeringFound = modGuidanceSteeringFound
	self.modVCAFound = modVCAFound
	
	-- Titel
	self.guiTitle:setText(g_i18n:getText("hlmgui_title")..vehicleName)

	-- SpeedControl
	self.speedControlOnOffTitle:setText(g_i18n:getText("hlmgui_speedControl"))
	self.speedControlOnOffSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.speedControlOnOffSetting:setState(useSpeedControl and 1 or 2)
	
	self.speedControlUseSCModTitle:setText(g_i18n:getText("hlmgui_speedControlMod"))
	self.speedControlUseSCModSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.speedControlUseSCModSetting:setState(useModSpeedControl and modSpeedControlFound and 1 or 2)
	self.speedControlUseSCModSetting:setDisabled(not useSpeedControl or not modSpeedControlFound)
	
	self.speedControlTurnSpeedTitle1:setText(g_i18n:getText("hlmgui_speedSetting"))
	local speedTable = {}
	for n=1,40 do
		speedTable[n] = tostring(n)
	end
	self.speedControlTurnSpeedSetting1:setTexts(speedTable)
	self.speedControlTurnSpeedSetting1:setState(not useModSpeedControl and turnSpeed or 5)
	local disableSpeedcontrolMod
	if not modSpeedControlFound then
		disableSpeedcontrolMod = true
	else 
		disableSpeedcontrolMod = not useModSpeedControl or not useSpeedControl
	end
	self.speedControlTurnSpeedSetting1:setDisabled(not disableSpeedcontrolMod or not useSpeedControl)
	
	self.speedControlTurnSpeedTitle2:setText(g_i18n:getText("hlmgui_speedControlModSetting"))
	self.speedControlTurnSpeedSetting2:setTexts({"1","2","3"})
	self.speedControlTurnSpeedSetting2:setState(useModSpeedControl and turnSpeed or 1)
	self.speedControlTurnSpeedSetting2:setDisabled(disableSpeedcontrolMod)

	-- AlertMode
	self.alarmTitle:setText(g_i18n:getText("hlmgui_beep"))
	self.alarmSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.alarmSetting:setState(beep and 1 or 2)
	
	-- Implement control
	self.raiseTitle:setText(g_i18n:getText("hlmgui_raise"))
	self.raiseSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.raiseSetting:setState(useRaiseImplement and 1 or 2)
	
	self.turnPlowTitle:setText(g_i18n:getText("hlmgui_plow"))
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
	self.turnPlowSetting:setDisabled(not useRaiseImplement)

	self.stopPtoTitle:setText(g_i18n:getText("hlmgui_pto"))
	self.stopPtoSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.stopPtoSetting:setState(useStopPTO and 1 or 2)
		
	self.ridgeMarkerTitle:setText(g_i18n:getText("hlmgui_ridgeMarker"))
	self.ridgeMarkerSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.ridgeMarkerSetting:setState(useRidgeMarker and 1 or 2)
	
	-- GPS control
	self.gpsOnOffTitle:setText(g_i18n:getText("hlmgui_gpsSetting"))
	self.gpsOnOffSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.gpsOnOffSetting:setState(useGPS and 1 or 2)
	self.gpsOnOffSetting:setDisabled(not modGuidanceSteeringFound and not modVCAFound)
		
	self.gpsSettingTitle:setText(g_i18n:getText("hlmgui_gpsType"))
	self.gpsSetting:setTexts({
		g_i18n:getText("hlmgui_gps_auto"),
		g_i18n:getText("hlmgui_gps_gs"),
		g_i18n:getText("hlmgui_gps_vca")
	})	
	if useGuidanceSteering and modGuidanceSteeringFound then gpsSetting = 2; end
	if useVCA and modVCAFound then gpsSetting = 3; end

	self.gpsSetting:setState(gpsSetting)
	local gpsDisabled
	if not modGuidanceSteeringFound and not modVCAFound then
		gpsDisabled = true
	else
		gpsDisabled = not useGPS
	end
	self.gpsSetting:setDisabled(gpsDisabled)
	
	self.gpsAutoTriggerTitle:setText(g_i18n:getText("hlmgui_gpsAutoTriggerSetting"))
	self.gpsAutoTriggerSetting:setTexts({
		g_i18n:getText("hlmgui_gps_gs"),
		g_i18n:getText("hlmgui_off"),
	})
	self.gpsAutoTriggerSetting:setState(useGuidanceSteeringTrigger and 1 or 2)
	self.gpsAutoTriggerSetting:setDisabled(not modGuidanceSteeringFound)

	-- Diff control
	self.diffControlOnOffTitle:setText(g_i18n:getText("hlmgui_diffLock"))
	self.diffControlOnOffSetting:setTexts({
		g_i18n:getText("hlmgui_on"),
		g_i18n:getText("hlmgui_off"),
	})
	self.diffControlOnOffSetting:setState(useDiffLock and 1 or 2)
	self.diffControlOnOffSetting:setDisabled(not modVCAFound)
end

-- check logical dependencies
function HeadlandManagementGui:logicalCheck()
	local useSpeedControl = self.speedControlOnOffSetting:getState() == 1
	self.speedControlUseSCModSetting:setDisabled(not useSpeedControl or not self.modSpeedControlFound)
	
	local useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	self.speedControlTurnSpeedSetting1:setDisabled(useModSpeedControl or not useSpeedControl)
	self.speedControlTurnSpeedSetting2:setDisabled(not useModSpeedControl or not self.modSpeedControlFound or not useSpeedControl)
	
	local useRaiseImplement = self.raiseSetting:getState() == 1	
	self.turnPlowSetting:setDisabled(not useRaiseImplement)

	local useGPS = self.gpsOnOffSetting:getState() == 1
	self.gpsOnOffSetting:setDisabled(not self.modGuidanceSteeringFound and not self.modVCAFound)
	self.gpsSetting:setDisabled(not useGPS)

	local gpsSetting = self.gpsSetting:getState()
	if gpsSetting == 2 and not self.modGuidanceSteeringFound then gpsSetting = 3; end
	if gpsSetting == 3 and not self.modVCAFound then gpsSetting = 1; end
	self.gpsSetting:setState(gpsSetting)
	self.gpsAutoTriggerSetting:setDisabled(not useGPS or gpsSetting == 3)
end

-- close gui and send new values to callback
function HeadlandManagementGui:onClickOk()
	local useSpeedControl = self.speedControlOnOffSetting:getState() == 1
	local useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	if useModSpeedControl then
		turnSpeed = self.speedControlTurnSpeedSetting2:getState()
	else 
		turnSpeed = self.speedControlTurnSpeedSetting1:getState()
	end
	local useRaiseImplement = self.raiseSetting:getState() == 1
	local useStopPTO = self.stopPtoSetting:getState() == 1
	local plowState = self.turnPlowSetting:getState()
	local useTurnPlow = (plowState < 3)
	local useCenterPlow = (plowState == 2)
	local useRidgeMarker = self.ridgeMarkerSetting:getState() == 1
	local useGPS = self.gpsOnOffSetting:getState() == 1
	local gpsSetting = self.gpsSetting:getState()
	if gpsSetting == 1 then useGuidanceSteering = false; useVCA = false; end
	if gpsSetting == 2 then useGuidanceSteering = true; useVCA = false; end
	if gpsSetting == 3 then useGuidanceSteering = false; useVCA = true; end
	local useGuidanceSteeringTrigger = self.gpsAutoTriggerSetting:getState() == 1
	local useDiffLock = self.diffControlOnOffSetting:getState() == 1
	local beep = self.alarmSetting:getState() == 1

	self:close()
	self.callbackFunc(self.target, useSpeedControl, useModSpeedControl, turnSpeed, useRaiseImplement, useStopPTO, useTurnPlow, useCenterPlow, useRidgeMarker, useGPS, gpsSetting, useGuidanceSteering, useGuidanceSteeringTrigger, useVCA, useDiffLock, beep)
end

-- just close gui
function HeadlandManagementGui:onClickBack()
	self:close()
end
