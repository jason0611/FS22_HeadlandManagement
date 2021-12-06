--
-- Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 1.9.1.2
--

HeadlandManagementGui = {}
local HeadlandManagementGui_mt = Class(HeadlandManagementGui, YesNoDialog)

dbgprint("HeadlandManagementGui : initializing")

-- reference to xml
HeadlandManagementGui.CONTROLS = {
	"guiTitle",
	
	"sectionSpeedControl",
	"speedControl",
	"speedControlOnOffTitle",
	"speedControlOnOffSetting",
	"speedControlTT",
	"speedControlUseSCModTitle",
	"speedControlUseSCModSetting",
	"speedControlModTT",
	"speedControlTurnSpeedTitle1",
	"speedControlTurnSpeedSetting1",
	"speedSettingTT",
	"speedControlTurnSpeedTitle2",
	"speedControlTurnSpeedSetting2",
	"speedControlModSettingTT",

	"sectionAlarm",
	"alarmControl",
	"alarmTitle",
	"alarmSetting",
	"alarmTT",
		
	"sectionImplementControl",
	"implementControl",
	"raiseTitle",
	"raiseSetting",
	"raiseTT",
	"stopPtoTitle",
	"stopPtoSetting",
	"ptoTT",
	"turnPlowTitle",
	"turnPlowSetting",
	"plowTT",
	"ridgeMarkerTitle",
	"ridgeMarkerSetting",
	"ridgeMarkerTT",
	"crabSteeringTitle",
	"crabSteeringSetting",
	"csTT",
	
	"sectionGPSControl",
	"gpsControl",
	"gpsOnOffTitle",
	"gpsOnOffSetting",
	"gpsTT",
	"gpsSettingTitle",
	"gpsSetting",
	"gpsTypeTT",
	"gpsAutoTriggerTitle",
	"gpsAutoTriggerSetting",
	"gpsAutoTriggerTT",
	"gpsAutoTriggerOffsetTitle",
	"gpsAutoTriggerOffsetSetting",
	"gpsAutoTriggerOffsetTT",
	
	"sectionDiffControl",
	"vehicleControl",
	"diffControlOnOffTitle",
	"diffControlOnOffSetting",
	"diffLockTT"
}

-- constructor
function HeadlandManagementGui:new()
	local gui = YesNoDialog:new(nil, HeadlandManagementGui_mt)
	gui:registerControls(HeadlandManagementGui.CONTROLS)
	dbgprint("HeadlandManagementGui created", 2)
	return gui
end

-- set current values
function HeadlandManagementGui.setData(
	self,
	vehicleName, 
	useSpeedControl, 
	useModSpeedControl, 
	crabSteeringFound, 
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
	beep, 
	modSpeedControlFound, 
	modGuidanceSteeringFound, 
	modVCAFound, 
	gpsEnabled
)
	dbgprint("HeadlandManagementGui: setData", 2)
	self.modSpeedControlFound = modSpeedControlFound
	self.modGuidanceSteeringFound = modGuidanceSteeringFound
	self.modVCAFound = modVCAFound
	self.gpsEnabled = gpsEnabled
	
	self.yesButton.onClickCallback=HeadlandManagementGui.onClickOk
	self.noButton.onClickCallback=HeadlandManagementGui.onClickBack
		
	-- Titel
	self.guiTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_title")..vehicleName)

	-- SpeedControl
	self.speedControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControl"))
	self.speedControlOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControl"))
	self.speedControlOnOffSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.speedControlOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.speedControlOnOffSetting:setState(useSpeedControl and 1 or 2)
	
	self.speedControlUseSCModTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlMod"))
	self.speedControlUseSCModSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.speedControlUseSCModSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.speedControlUseSCModSetting:setState(useModSpeedControl and modSpeedControlFound and 1 or 2)
	self.speedControlUseSCModSetting:setDisabled(not useSpeedControl or not modSpeedControlFound)
	self.speedControlUseSCModSetting:setVisible(modSpeedControlFound)
	
	self.speedControlTurnSpeedTitle1:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedSetting"))
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
	
	self.speedControlTurnSpeedTitle2:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModSetting"))
	self.speedControlTurnSpeedSetting2:setTexts({"1","2","3"})
	self.speedControlTurnSpeedSetting2:setState(useModSpeedControl and turnSpeed or 1)
	self.speedControlTurnSpeedSetting2:setDisabled(disableSpeedcontrolMod or not modSpeedControlFound)
	self.speedControlTurnSpeedSetting2:setVisible(modSpeedControlFound)

	-- AlertMode
	self.alarmControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_alarmControl"))
	self.alarmTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_beep"))
	self.alarmSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.alarmSetting:setState(beep and 1 or 2)
	
	-- Implement control
	self.implementControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_implementControl"))
	
	self.raiseTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_raise"))
	
	self.raiseSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.raiseSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_both"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	local raiseState = 4
	if useRaiseImplementF and useRaiseImplementB then raiseState = 1; end
	if useRaiseImplementF and not useRaiseImplementB then raiseState = 2; end
	if not useRaiseImplementF and useRaiseImplementB then raiseState = 3; end
	self.raiseSetting:setState(raiseState)
	
	self.turnPlowTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plow"))
	self.turnPlowSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowFull"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowCenter"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowOff")
	})
	local plowState
	if useTurnPlow and not useCenterPlow then plowState = 1; end
	if useTurnPlow and useCenterPlow then plowState = 2; end
	if not useTurnPlow then plowState = 3; end
	self.turnPlowSetting:setState(plowState)
	self.turnPlowSetting:setDisabled(raiseState == 4)

	self.stopPtoTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_pto"))
	self.stopPtoSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_both"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	local ptoState = 4
	if useStopPTOF and useStopPTOB then ptoState = 1; end
	if useStopPTOF and not useStopPTOB then ptoState = 2; end
	if not useStopPTOF and useStopPTOB then ptoState = 3; end
	self.stopPtoSetting:setState(ptoState)
		
	self.ridgeMarkerTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_ridgeMarker"))
	self.ridgeMarkerSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.ridgeMarkerSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.ridgeMarkerSetting:setState(useRidgeMarker and 1 or 2)
	self.ridgeMarkerSetting:setDisabled(raiseState == 4)
	
	-- GPS control
	self.gpsControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsControl"))
	self.gpsOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsSetting"))
	self.gpsOnOffSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsOnOffSetting:setState(useGPS and 1 or 2)
	self.gpsOnOffSetting:setDisabled(not modGuidanceSteeringFound and not modVCAFound)
	self.gpsOnOffSetting:setVisible(modGuidanceSteeringFound or modVCAFound)
		
	self.gpsSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsType"))
	self.gpsSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	
	self.showGPS, self.gsMode, self.vcaMode, self.vcaFirstLeft, self.vcaFirstRight = true, 0, 0, 0, 0
	-- gpsSetting: 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right
	
	if modGuidanceSteeringFound and modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR")
		})
		self.gsMode = 2
		self.vcaMode = 3
		self.vcaFirstLeft = 4
		self.vcaFirstRight = 5
	end
	if modGuidanceSteeringFound and not modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
		})
		self.gsMode = 2
		if gpsSetting > 2 then gpsSetting = 1 end
	end
	if not modGuidanceSteeringFound and modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR")
		})
		self.vcaMode = 2
		self.vcaFirstLeft = 3
		self.vcaFirstRight = 4
		if useGuidanceSteering then gpsSetting = 1 end
	end
	if not modGuidanceSteeringFound and not modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
		})
		self.showGPS = false
		gpsSetting = 1
	end
	self.gpsSetting:setState(gpsSetting)
	
	local gpsDisabled
	if not modGuidanceSteeringFound and not modVCAFound then
		gpsDisabled = true
	else
		gpsDisabled = not useGPS
	end
	self.gpsSetting:setDisabled(gpsDisabled or not self.showGPS)
	self.gpsSetting:setVisible(modGuidanceSteeringFound or modVCAFound)
	
	self.gpsAutoTriggerTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSetting"))
	self.gpsAutoTriggerSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsAutoTriggerSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsAutoTriggerSetting:setState(useGuidanceSteeringTrigger and 1 or 2)
	self.gpsAutoTriggerSetting:setDisabled(not modGuidanceSteeringFound)
	self.gpsAutoTriggerSetting:setVisible(modGuidanceSteeringFound)
	
	self.gpsAutoTriggerOffsetTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetSetting"))
	self.gpsAutoTriggerOffsetSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsAutoTriggerOffsetSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front")
	})	
	self.gpsAutoTriggerOffsetSetting:setState(useGuidanceSteeringOffset and 1 or 2)
	self.gpsAutoTriggerOffsetSetting:setDisabled(not modGuidanceSteeringFound or self.gpsEnabled or not useGuidanceSteeringTrigger or not useGPS or self.gpsSetting:getState() == 3)
	self.gpsAutoTriggerOffsetSetting:setVisible(modGuidanceSteeringFound)
	
	-- Vehicle control
	self.vehicleControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_vehicleControl"))
	
	-- Diff control
	self.diffControlOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_diffLock"))
	self.diffControlOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.diffControlOnOffSetting:setState(useDiffLock and 1 or 2)
	self.diffControlOnOffSetting:setDisabled(not modVCAFound)
	self.diffControlOnOffSetting:setVisible(modVCAFound)
	
	-- CrabSteering control
	self.crabSteeringTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_crabSteering"))
	self.crabSteeringSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_csDirect"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_csTwoStep"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	local csState = 2
	if useCrabSteering and not useCrabSteeringTwoStep then csState = 1; end
	if useCrabSteering and useCrabSteeringTwoStep then csState = 2; end
	if not useCrabSteering then csState = 3; end
	self.crabSteeringSetting:setState(csState)
	self.crabSteeringSetting:setDisabled(not crabSteeringFound)
	self.crabSteeringSetting:setVisible(crabSteeringFound)
	
	-- Set ToolTip-Texts
	self.alarmTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_alarmTT"))
	self.raiseTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_raiseTT"))
	self.plowTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowTT"))
	self.ptoTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_ptoTT"))
	self.ridgeMarkerTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_ridgeMarkerTT"))
	self.diffLockTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_diffLockTT"))
	self.csTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_csTT"))
	self.gpsTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsTT"))
	self.gpsTypeTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsTypeTT"))
	self.gpsAutoTriggerTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerTT"))
	self.gpsAutoTriggerOffsetTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetTT"))
	self.speedControlTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlTT"))
	self.speedControlModTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModTT"))
	self.speedSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedSettingTT"))
	self.speedControlModSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModSettingTT"))
end

-- check logical dependencies
function HeadlandManagementGui:logicalCheck()
	dbgprint("HeadlandManagementGui: logicalCheck", 3)
	local useSpeedControl = self.speedControlOnOffSetting:getState() == 1
	self.speedControlUseSCModSetting:setDisabled(not useSpeedControl or not self.modSpeedControlFound) 
	
	local useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	self.speedControlTurnSpeedSetting1:setDisabled(useModSpeedControl or not useSpeedControl)
	self.speedControlTurnSpeedSetting2:setDisabled(not useModSpeedControl or not self.modSpeedControlFound or not useSpeedControl)
	
	local useRaiseImplement = self.raiseSetting:getState() ~= 4	
	self.turnPlowSetting:setDisabled(not useRaiseImplement)
	self.ridgeMarkerSetting:setDisabled(not useRaiseImplement)

	local useGPS = self.gpsOnOffSetting:getState() == 1
	self.gpsOnOffSetting:setDisabled(not self.modGuidanceSteeringFound and not self.modVCAFound)
	self.gpsSetting:setDisabled(not useGPS or not self.showGPS)
	self.gpsAutoTriggerSetting:setDisabled(not self.modGuidanceSteeringFound or not useGPS or self.gpsSetting:getState() == 3)
	self.gpsAutoTriggerOffsetSetting:setDisabled(not self.modGuidanceSteeringFound or self.gpsEnabled or self.gpsAutoTriggerSetting:getState() == 2 or not useGPS or self.gpsSetting:getState() == 3)
end

-- close gui and send new values to callback
function HeadlandManagementGui:onClickOk()
	dbgprint("onClickOk", 3)
	
	-- speed control
	local useSpeedControl = self.speedControlOnOffSetting:getState() == 1
	local useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	if useModSpeedControl then
		turnSpeed = self.speedControlTurnSpeedSetting2:getState()
	else 
		turnSpeed = self.speedControlTurnSpeedSetting1:getState()
	end
	-- raise
	local raiseState = self.raiseSetting:getState()
	local useRaiseImplementF
	local useRaiseImplementB
	if raiseState == 1 then useRaiseImplementF = true; useRaiseImplementB = true; end
	if raiseState == 2 then useRaiseImplementF = true; useRaiseImplementB = false; end
	if raiseState == 3 then useRaiseImplementF = false; useRaiseImplementB = true; end
	if raiseState == 4 then useRaiseImplementF = false; useRaiseImplementB = false; end
	-- pto
	local useStopPTOF = (self.stopPtoSetting:getState() == 1 or self.stopPtoSetting:getState() == 2)
	local useStopPTOB = (self.stopPtoSetting:getState() == 1 or self.stopPtoSetting:getState() == 3)
	-- plow
	local plowState = self.turnPlowSetting:getState()
	local useTurnPlow = (plowState < 3)
	local useCenterPlow = (plowState == 2)
	-- ridgemarker
	local useRidgeMarker = self.ridgeMarkerSetting:getState() == 1
	-- crab steering
	local csState = self.crabSteeringSetting:getState()
	local useCrabSteering = (csState ~= 3)
	local useCrabSteeringTwoStep = (csState == 2)
	-- gps
	local useGPS = self.gpsOnOffSetting:getState() == 1
	local gpsSetting = self.gpsSetting:getState()
	-- 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right
	
	if gpsSetting == 1 then useGuidanceSteering = false; useVCA = false end -- triggers auto-mode
	if gpsSetting == 2 and self.modGuidanceSteeringFound then 
		useGuidanceSteering = true
		useVCA = false
	elseif gpsSetting > 1 and not self.modGuidanceSteeringFound then
		useGuidanceSteering = false
		useVCA = true
		gpsSetting = gpsSetting + 1
	elseif gpsSetting > 2 and self.modGuidanceSteeringFound then
		useGuidanceSteering = false
		useVCA = true
	end
	-- gps trigger
	local useGuidanceSteeringTrigger = self.gpsAutoTriggerSetting:getState() == 1
	local useGuidanceSteeringOffset = self.gpsAutoTriggerOffsetSetting:getState() == 1
	-- diffs
	local useDiffLock = self.diffControlOnOffSetting:getState() == 1
	-- beep
	local beep = self.alarmSetting:getState() == 1

	dbgprint("gpsSetting (GUI): "..tostring(gpsSetting), 3)
	self:close()
	self.callbackFunc(
		self.target, 
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
end

-- just close gui
function HeadlandManagementGui:onClickBack()
	dbgprint("onClickBack", 3)
	self:close()
end
