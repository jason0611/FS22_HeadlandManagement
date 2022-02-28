--
-- Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 2.1.0.0 RC3
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
	"alarmVolumeTitle",
	"alarmVolumeSetting",
	"alarmVolumeTT",
		
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
	
	"gpsAutoTrigger",
	"gpsAutoTriggerTitle",
	"gpsAutoTriggerSubTitle",
	"gpsAutoTriggerSetting",
	"gpsAutoTriggerTT",
	"gpsAutoTriggerOffsetTitle",
	"gpsAutoTriggerOffsetSetting",
	"gpsAutoTriggerOffsetTT",
	"gpsAutoTriggerOffsetWidth",
	"gpsAutoTriggerOffsetWidthTitle",
	"gpsAutoTriggerOffsetWidthInput",
	"gpsAutoTriggerOffsetWidthTT",
	"gpsEnableDirSwitchSetting",
	"gpsDisableDirSwitchTitle",
	"gpsDirSwitchTT",
	"gpsResumeTitle",
	"gpsResumeSetting",
	"gpsResumeTT",
	
	"sectionDiffControl",
	"vehicleControl",
	"diffControlOnOffTitle",
	"diffControlOnOffSetting",
	"diffLockTT",
	
	"debug",
	"debugTitle",
	"debugSetting",
	"debugTT",
	"debugFlagTitle",
	"debugFlagSetting",
	"debugFlagTT"
}

-- constructor
function HeadlandManagementGui:new()
	local gui = YesNoDialog:new(nil, HeadlandManagementGui_mt)
	gui:registerControls(HeadlandManagementGui.CONTROLS)
	dbgprint("HeadlandManagementGui created", 2)
	return gui
end

-- set current values
function HeadlandManagementGui.setData(self, vehicleName, spec, gpsEnabled, debug)
	dbgprint("HeadlandManagementGui: setData", 2)
	self.spec = spec
	self.gpsEnabled = gpsEnabled
	
	dbgprint_r(self.spec)
		
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
	self.speedControlOnOffSetting:setState(self.spec.useSpeedControl and 1 or 2)
	
	self.speedControlUseSCModTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlMod"))
	self.speedControlUseSCModSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.speedControlUseSCModSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.speedControlUseSCModSetting:setState(self.spec.useModSpeedControl and self.spec.modSpeedControlFound and 1 or 2)
	self.speedControlUseSCModSetting:setDisabled(not self.spec.useSpeedControl or not self.spec.modSpeedControlFound)
	self.speedControlUseSCModSetting:setVisible(self.spec.modSpeedControlFound)
	
	self.speedControlTurnSpeedTitle1:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedSetting"))
	local speedTable = {}
	for n=1,40 do
		speedTable[n] = tostring(n)
	end
	self.speedControlTurnSpeedSetting1:setTexts(speedTable)
	self.speedControlTurnSpeedSetting1:setState(not self.spec.useModSpeedControl and self.spec.turnSpeed or 5)
	local disableSpeedcontrolMod
	if not self.spec.modSpeedControlFound then
		disableSpeedcontrolMod = true
	else 
		disableSpeedcontrolMod = not self.spec.useModSpeedControl or not self.spec.useSpeedControl
	end
	self.speedControlTurnSpeedSetting1:setDisabled(not disableSpeedcontrolMod or not self.spec.useSpeedControl)
	
	self.speedControlTurnSpeedTitle2:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModSetting"))
	self.speedControlTurnSpeedSetting2:setTexts({"1","2","3"})
	self.speedControlTurnSpeedSetting2:setState(self.spec.useModSpeedControl and self.spec.turnSpeed or 1)
	self.speedControlTurnSpeedSetting2:setDisabled(disableSpeedcontrolMod or not self.spec.modSpeedControlFound)
	self.speedControlTurnSpeedSetting2:setVisible(self.spec.modSpeedControlFound)

	-- AlertMode
	self.alarmControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_alarmControl"))
	self.alarmTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_beep"))
	self.alarmSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.alarmSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.alarmSetting:setState(self.spec.beep and 1 or 2)
	
	self.alarmVolumeTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_beepVol"))
	local values={}
	for i=1,10 do values[i] = tostring(i*10).." %" end 
	self.alarmVolumeSetting:setTexts(values)
	self.alarmVolumeSetting:setState(self.spec.beepVol)
	self.alarmVolumeSetting:setDisabled(not self.spec.beep)
	
	-- Implement control
	self.implementControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_implementControl"))
	
	self.raiseTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_raise"))
	
	self.raiseSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.raiseSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_both"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_seq"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	local raiseState = 5
	if self.spec.useRaiseImplementF and self.spec.useRaiseImplementB then raiseState = 1 end
	if self.spec.useRaiseImplementF and self.spec.useRaiseImplementB and self.spec.waitOnTrigger then raiseState = 2 end
	if self.spec.useRaiseImplementF and not self.spec.useRaiseImplementB then raiseState = 3 end
	if not self.spec.useRaiseImplementF and self.spec.useRaiseImplementB then raiseState = 4 end
	self.raiseSetting:setState(raiseState)
	
	self.turnPlowTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plow"))
	self.turnPlowSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowFull"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowCenter"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowOff")
	})
	local plowState
	if self.spec.useTurnPlow and not self.spec.useCenterPlow then plowState = 1; end
	if self.spec.useTurnPlow and self.spec.useCenterPlow then plowState = 2; end
	if not self.spec.useTurnPlow then plowState = 3; end
	self.turnPlowSetting:setState(plowState)
	self.turnPlowSetting:setDisabled(raiseState == 5)

	self.stopPtoTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_pto"))
	self.stopPtoSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_both"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	local ptoState = 4
	if self.spec.useStopPTOF and self.spec.useStopPTOB then ptoState = 1; end
	if self.spec.useStopPTOF and not self.spec.useStopPTOB then ptoState = 2; end
	if not self.spec.useStopPTOF and self.spec.useStopPTOB then ptoState = 3; end
	self.stopPtoSetting:setState(ptoState)
		
	self.ridgeMarkerTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_ridgeMarker"))
	self.ridgeMarkerSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.ridgeMarkerSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.ridgeMarkerSetting:setState(self.spec.useRidgeMarker and 1 or 2)
	self.ridgeMarkerSetting:setDisabled(raiseState == 5)
	
	-- GPS control
	self.gpsControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsControl"))
	self.gpsOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsSetting"))
	self.gpsOnOffSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsOnOffSetting:setState(self.spec.useGPS and 1 or 2)
	self.gpsOnOffSetting:setDisabled(not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound)
	self.gpsOnOffSetting:setVisible(self.spec.modGuidanceSteeringFound or self.spec.modVCAFound)
		
	self.gpsSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsType"))
	self.gpsSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	
	self.showGPS = true
	
	-- gpsSetting: 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right
	local lastGPSSetting = self.spec.gpsSetting
	if not self.spec.modGuidanceSteeringFound and self.spec.gpsSetting > 1 then self.spec.gpsSetting = self.spec.gpsSetting - 1 end
	
	if self.spec.modGuidanceSteeringFound and self.spec.modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR")
		})
	end
	if self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
		})
		if self.spec.gpsSetting > 2 then self.spec.gpsSetting = 1 end
	end
	if not self.spec.modGuidanceSteeringFound and self.spec.modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR")
		})
		if self.spec.gpsSetting == 2 then self.spec.gpsSetting = 1 end
	end
	if not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound then
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
		})
		self.showGPS = false
		self.spec.gpsSetting = 1
	end
	self.gpsSetting:setState(self.spec.gpsSetting)
	
	local gpsDisabled
	if not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound then
		gpsDisabled = true
	else
		gpsDisabled = not self.spec.useGPS
	end
	self.gpsSetting:setDisabled(gpsDisabled or not self.showGPS)
	self.gpsSetting:setVisible(self.spec.modGuidanceSteeringFound or self.spec.modVCAFound)
	
	-- VCA direction switching
	self.gpsDisableDirSwitchTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_vcaDirSwitch"))
	self.gpsEnableDirSwitchSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsEnableDirSwitchSetting:setState(self.spec.vcaDirSwitch and 1 or 2)
	self.gpsEnableDirSwitchSetting:setDisabled(not self.spec.modVCAFound or lastGPSSetting < 4)
	self.gpsEnableDirSwitchSetting:setVisible(self.spec.modVCAFound)
	
	-- Headland automatic
	self.gpsAutoTrigger:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSetting"))
	self.gpsAutoTriggerSubTitle:setText(string.format(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSubTitle"),self.spec.vehicleLength,self.spec.vehicleWidth,self.spec.maxTurningRadius))
	self.gpsAutoTriggerTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSetting"))
	self.gpsAutoTriggerSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	local triggerTexts = ({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on")
	})
	if self.spec.modGuidanceSteeringFound then triggerTexts[3] = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs") end
	self.gpsAutoTriggerSetting:setTexts(triggerTexts)
	
	local triggerSetting = 1
	if self.spec.useHLMTriggerF or self.spec.useHLMTriggerB then 
		triggerSetting = 2
	elseif self.spec.modGuidanceSteeringFound and self.spec.useGuidanceSteeringTrigger then 
		triggerSetting = 3 
	end
	self.gpsAutoTriggerSetting:setState(triggerSetting)
	
	self.gpsAutoTriggerOffsetTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetSetting"))
	self.gpsAutoTriggerOffsetSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsAutoTriggerOffsetSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back")
	})	
	local offsetSetting = 1
	if triggerSetting == 3 and self.spec.useGuidanceSteeringOffset then 
		offsetSetting = 2 
	elseif triggerSetting == 2 and self.spec.useHLMTriggerB then 
		offsetSetting = 2
	end
	self.gpsAutoTriggerOffsetSetting:setState(offsetSetting)
	self.gpsAutoTriggerOffsetSetting:setDisabled(triggerSetting == 1 or (triggerSetting == 3 and self.gpsEnabled))
	
	self.gpsAutoTriggerOffsetWidthTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetWidth"))
	self.gpsAutoTriggerOffsetWidthInput:setText(tostring(self.spec.headlandDistance))
	self.gpsAutoTriggerOffsetWidthInput.onEnterPressedCallback = HeadlandManagementGui.onWidthInput
	self.gpsAutoTriggerOffsetWidthInput:setDisabled(triggerSetting ~= 2)
	
	self.gpsResumeTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_autoResume"))
	self.gpsResumeSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsResumeSetting:setState(self.spec.autoResume and 1 or 2)
	
	-- Vehicle control
	self.vehicleControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_vehicleControl"))
	
	-- Diff control
	self.diffControlOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_diffLock"))
	self.diffControlOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.diffControlOnOffSetting:setState(self.spec.useDiffLock and 1 or 2)
	self.diffControlOnOffSetting:setDisabled(not self.spec.modVCAFound)
	self.diffControlOnOffSetting:setVisible(self.spec.modVCAFound)
	
	-- CrabSteering control
	self.crabSteeringTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_crabSteering"))
	self.crabSteeringSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_csDirect"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_csTwoStep"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	local csState = 2
	if self.spec.useCrabSteering and not self.spec.useCrabSteeringTwoStep then csState = 1; end
	if self.spec.useCrabSteering and self.spec.useCrabSteeringTwoStep then csState = 2; end
	if not self.spec.useCrabSteering then csState = 3; end
	self.crabSteeringSetting:setState(csState)
	self.crabSteeringSetting:setDisabled(not self.spec.crabSteeringFound)
	self.crabSteeringSetting:setVisible(self.spec.crabSteeringFound)
	
	-- Debug
	self.debug:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_debug"))
	self.debugTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_debugTitle"))
	self.debugSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.debugSetting:setState(debug and 1 or 2)
	
	self.debugFlagTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_debugFlagTitle"))
	self.debugFlagSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.debugFlagSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.debugFlagSetting:setState(self.spec.debugFlag and 1 or 2)
	self.debugFlagSetting:setDisabled(raiseState ~= 2)
	
	-- Set ToolTip-Texts
	self.alarmTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_alarmTT"))
	self.alarmVolumeTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_beepVolTT"))
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
	self.gpsAutoTriggerOffsetWidthTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetWidthTT"))
	self.speedControlTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlTT"))
	self.speedControlModTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModTT"))
	self.speedSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedSettingTT"))
	self.speedControlModSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModSettingTT"))
	self.gpsDirSwitchTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_VCADirSwitchTT"))
	self.gpsResumeTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoResumeTT"))
	self.debugTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_debugTT"))
	self.debugFlagTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_debugFlagTT"))
end

-- check logical dependencies
function HeadlandManagementGui:logicalCheck()
	dbgprint("HeadlandManagementGui: logicalCheck", 3)
	
	local useBeep = self.alarmSetting:getState() == 1
	self.alarmVolumeSetting:setDisabled(not useBeep)
	
	local useSpeedControl = self.speedControlOnOffSetting:getState() == 1
	self.speedControlUseSCModSetting:setDisabled(not useSpeedControl or not self.spec.modSpeedControlFound) 
	
	local useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	self.speedControlTurnSpeedSetting1:setDisabled(useModSpeedControl or not useSpeedControl)
	self.speedControlTurnSpeedSetting2:setDisabled(not useModSpeedControl or not self.spec.modSpeedControlFound or not useSpeedControl)
	
	local useRaiseImplement = self.raiseSetting:getState() ~= 5	
	self.turnPlowSetting:setDisabled(not useRaiseImplement)
	self.ridgeMarkerSetting:setDisabled(not useRaiseImplement)

	local useGPS = self.gpsOnOffSetting:getState() == 1
	self.gpsOnOffSetting:setDisabled(not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound)
	
	local gpsSetting = self.gpsSetting:getState()
	if not self.spec.modGuidanceSteeringFound and gpsSetting > 1 then
		gpsSetting = gpsSetting + 1
	end
	self.gpsSetting:setDisabled(not useGPS or not self.showGPS)
	self.gpsEnableDirSwitchSetting:setDisabled(not useGPS or not self.spec.modVCAFound or gpsSetting < 4)
	local triggerSetting = self.gpsAutoTriggerSetting:getState()
	self.gpsAutoTriggerOffsetSetting:setDisabled(triggerSetting == 1 or (triggerSetting == 3 and self.gpsEnabled))
	self.gpsAutoTriggerOffsetWidthInput:setDisabled(triggerSetting ~= 2)
	
	self.debugFlagSetting:setDisabled(self.raiseSetting:getState() ~= 2)
end

-- get width input
function HeadlandManagementGui:onWidthInput()
	dbgprint("onWidthInput : "..self.gpsAutoTriggerOffsetWidthInput:getText())
	local inputValue = tonumber(self.gpsAutoTriggerOffsetWidthInput:getText())
	if inputValue ~= nil then self.spec.headlandDistance = inputValue end
	dbgprint("onWidthInput : spec.headlandDistance: "..tostring(self.spec.headlandDistance), 2)
end

-- close gui and send new values to callback
function HeadlandManagementGui:onClickOk()
	dbgprint("onClickOk", 3)
	
	-- speed control
	self.spec.useSpeedControl = self.speedControlOnOffSetting:getState() == 1
	self.spec.useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	if useModSpeedControl then
		turnSpeed = self.speedControlTurnSpeedSetting2:getState()
	else 
		turnSpeed = self.speedControlTurnSpeedSetting1:getState()
	end
	-- raise
	local raiseState = self.raiseSetting:getState()
	if raiseState == 1 then self.spec.useRaiseImplementF = true; self.spec.useRaiseImplementB = true; self.spec.waitOnTrigger = false; end
	if raiseState == 2 then self.spec.useRaiseImplementF = true; self.spec.useRaiseImplementB = true; self.spec.waitOnTrigger = true; end
	if raiseState == 3 then self.spec.useRaiseImplementF = true; self.spec.useRaiseImplementB = false; self.spec.waitOnTrigger = false; end
	if raiseState == 4 then self.spec.useRaiseImplementF = false; self.spec.useRaiseImplementB = true; self.spec.waitOnTrigger = false; end
	if raiseState == 5 then self.spec.useRaiseImplementF = false; self.spec.useRaiseImplementB = false; self.spec.waitOnTrigger = false; end
	-- pto
	self.spec.useStopPTOF = (self.stopPtoSetting:getState() == 1 or self.stopPtoSetting:getState() == 2)
	self.spec.useStopPTOB = (self.stopPtoSetting:getState() == 1 or self.stopPtoSetting:getState() == 3)
	-- plow
	local plowState = self.turnPlowSetting:getState()
	self.spec.useTurnPlow = (plowState < 3)
	self.spec.useCenterPlow = (plowState == 2)
	-- ridgemarker
	self.spec.useRidgeMarker = self.ridgeMarkerSetting:getState() == 1
	-- crab steering
	self.spec.csState = self.crabSteeringSetting:getState()
	self.spec.useCrabSteering = (self.spec.csState ~= 3)
	self.spec.useCrabSteeringTwoStep = (self.spec.csState == 2)
	-- gps
	self.spec.useGPS = self.gpsOnOffSetting:getState() == 1
	self.spec.gpsSetting = self.gpsSetting:getState()
	-- 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right
	if self.spec.gpsSetting > 1 and not self.spec.modGuidanceSteeringFound then
		self.spec.gpsSetting = self.spec.gpsSetting + 1
	end
	-- headland automatic
	local triggerSetting = self.gpsAutoTriggerSetting:getState()
	local offsetSetting = self.gpsAutoTriggerOffsetSetting:getState()
	if triggerSetting == 1 then
		self.spec.useGuidanceSteeringTrigger = false
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = false
	elseif triggerSetting == 2 and offsetSetting == 1 then
		self.spec.useGuidanceSteeringTrigger = false
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = true
		self.spec.useHLMTriggerB = false
	elseif triggerSetting == 2 and offsetSetting == 2 then
		self.spec.useGuidanceSteeringTrigger = false
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = true
	elseif triggerSetting == 3 and offsetSetting == 1 then
		self.spec.useGuidanceSteeringTrigger = true
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = false
	elseif triggerSetting == 3 and offsetSetting == 2 then
		self.spec.useGuidanceSteeringTrigger = true
		self.spec.useGuidanceSteeringOffset = true
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = false
	end
	-- VCA dir siwtch
	self.spec.vcaDirSwitch = self.gpsEnableDirSwitchSetting:getState() == 1
	-- Autoresume
	self.spec.autoResume = self.gpsResumeSetting:getState() == 1
	self.spec.autoResumeOnTrigger = self.spec.autoResume and (self.spec.useHLMTriggerF or self.spec.useHLMTriggerB)
	-- diffs
	self.spec.useDiffLock = self.diffControlOnOffSetting:getState() == 1
	-- beep
	self.spec.beep = self.alarmSetting:getState() == 1
	self.spec.beepVol = self.alarmVolumeSetting:getState()
	-- debug
	local debug = self.debugSetting:getState() == 1
	self.spec.debugFlag = self.debugFlagSetting:getState() == 1

	dbgprint("gpsSetting (GUI): "..tostring(self.spec.gpsSetting), 3)
	self:close()
	self.callbackFunc(self.target, self.spec, debug)
end

-- just close gui
function HeadlandManagementGui:onClickBack()
	dbgprint("onClickBack", 3)
	self:close()
end
