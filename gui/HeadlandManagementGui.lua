--
-- Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede
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
	"inputbindingsTitle",
	"inputbindingsSetting",
	"inputbindingsTT",
		
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
	"emptyBalersSetting",
	"emptyBalersSettingTitle",
	"emptyBalersSettingTT",
	"crabSteeringTitle",
	"crabSteeringSetting",
	"csTT",
	
	"sectionContourControl",
	"contourControl",
	"contourOnOffTitle",
	"contourOnOffSetting",
	"contourOnOffTT",
	"contourSettingTitle",
	"contourSetting",
	"contourSettingTT",
	"contourWidthSetting",
	"contourWidthSettingTitle",
	"contourWidthSettingTT",
	"contourWidthChangeSetting",
	"contourWidthChangeSettingTitle",
	"contourWidthChangeSettingTT",
	
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
function HeadlandManagementGui.setData(self, vehicleName, spec, gpsEnabled, debug, showKeys)
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
	self.speedControlUseSCModSetting:setState((self.spec.useModSpeedControl and (self.spec.modSpeedControlFound or self.spec.modECCFound)) and 1 or 2)
	self.speedControlUseSCModSetting:setDisabled(not self.spec.useSpeedControl or (not self.spec.modSpeedControlFound and not self.spec.modECCFound))
	self.speedControlUseSCModSetting:setVisible(self.spec.modSpeedControlFound or self.spec.modECCFound)
	
	self.speedControlTurnSpeedTitle1:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedSetting"))
	local speedTable = {} --create speedTable with -10..-1,1..40
	for n=1,10 do
		speedTable[n] = tostring(n-11)
	end
	for n=1,40 do
		speedTable[n+10] = tostring(n)
	end
	self.speedControlTurnSpeedSetting1:setTexts(speedTable)
	local turnSpeedSetting
	if self.spec.turnSpeed < 0 then 
		turnSpeedSetting = math.floor(self.spec.turnSpeed) + 11
	else
		turnSpeedSetting = math.floor(self.spec.turnSpeed) + 10
	end
	self.speedControlTurnSpeedSetting1:setState(not self.spec.useModSpeedControl and turnSpeedSetting or 15)
	local disableSpeedcontrolMod
	if not self.spec.modSpeedControlFound and not self.spec.modECCFound then
		disableSpeedcontrolMod = true
	else 
		disableSpeedcontrolMod = not self.spec.useModSpeedControl or not self.spec.useSpeedControl
	end
	self.speedControlTurnSpeedSetting1:setDisabled(not disableSpeedcontrolMod or not self.spec.useSpeedControl)
	
	self.speedControlTurnSpeedTitle2:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_speedControlModSetting"))
	self.speedControlTurnSpeedSetting2:setTexts({"1","2","3"})
	self.speedControlTurnSpeedSetting2:setState(self.spec.useModSpeedControl and self.spec.turnSpeed or 1)
	self.speedControlTurnSpeedSetting2:setDisabled(disableSpeedcontrolMod) -- or (not self.spec.modSpeedControlFound and not self.spec.modECCFound))
	self.speedControlTurnSpeedSetting2:setVisible(self.spec.modSpeedControlFound or self.spec.modECCFound)

	-- General Settings
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
	
	self.inputbindingsTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_keys"))
	self.inputbindingsSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.inputbindingsSetting:setState(showKeys and 1 or 2)
	
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
	
	self.emptyBalersSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_emptyBaler"))
	self.emptyBalersSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.emptyBalersSetting:setState(self.spec.stopEmptyBaler and 1 or 2)
	self.emptyBalersSetting:setDisabled(true)
	
	-- Contour Guidance control
	self.contourControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourControl"))
	
	self.contourOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourOnOff"))
	
	self.contourOnOffSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.contourOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contour_On1Pass"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contour_OnMPass")
	})
	local contourOnOffSetting = 1
	if self.spec.contour ~= 0 then
		if self.spec.contourMultiMode then 
			contourOnOffSetting = 3
		else
			contourOnOffSetting = 2
		end
	end	
	self.contourOnOffSetting:setState(contourOnOffSetting)
	
	self.contourSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourSetting"))
	self.contourSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.contourSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contour_nextRight"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contour_nextLeft"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contour_alwaysRight"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contour_alwaysLeft")
	})
	self.contourSetting:setDisabled(contourOnOffSetting == 1)
	local contourMode = 1 
	if self.spec.contour > 0 then contourMode = 2 end
	if self.spec.contourNoSwap then contourMode = contourMode + 2 end
	self.contourSetting:setState(contourMode)
	
	self.contourWidthSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourWidthSetting"))
	self.contourWidthSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.contourWidthSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
		tostring(math.floor(self.spec.vehicleWidth * 0.5)).." m",
		tostring(math.floor(self.spec.vehicleWidth * 1.5)).." m",
		tostring(math.floor(self.spec.vehicleWidth * 2.5)).." m",
		tostring(math.floor(self.spec.vehicleWidth * 3.5)).." m"
	})
	self.contourWidthSetting:setDisabled(contourOnOffSetting == 1)
	local widthMode = 1
	if self.spec.contourWidth == math.floor(self.spec.vehicleWidth * 0.5) then widthMode = 2 end
	if self.spec.contourWidth == math.floor(self.spec.vehicleWidth * 1.5) then widthMode = 3 end
	if self.spec.contourWidth == math.floor(self.spec.vehicleWidth * 2.5) then widthMode = 4 end
	if self.spec.contourWidth == math.floor(self.spec.vehicleWidth * 3.5) then widthMode = 5 end
	self.contourWidthSetting:setState(widthMode)
	
	self.contourWidthChangeSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourWidthChangeSetting"))
	self.contourWidthChangeSettingTitle.onClickCallback = HeadlandManagementGui.logicalCheck
	self.contourWidthChangeSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.contourWidthChangeSetting:setDisabled(contourOnOffSetting == 1 or widthMode == 1)
	self.contourWidthChangeSetting:setState(self.spec.contourWidthAdation == true and 1 or 2)
		
	-- GPS control
	self.gpsControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsControl"))
	self.gpsOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsSetting"))
	self.gpsOnOffSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsOnOffSetting:setState(self.spec.useGPS and 1 or 2)
	self.gpsOnOffSetting:setDisabled(not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and not self.spec.modEVFound or self.spec.useEVTrigger)
	self.gpsOnOffSetting:setVisible(self.spec.modGuidanceSteeringFound or self.spec.modVCAFound or self.spec.modEVFound)
		
	self.gpsSettingTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsType"))
	self.gpsSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	
	self.showGPS = true
	
	-- gpsSetting: 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right, 6: ev-mode, 7: ev-mode autoturn
	local lastGPSSetting = self.spec.gpsSetting
	self.gpsVariant = 0
	
	if self.spec.modGuidanceSteeringFound and self.spec.modVCAFound and not self.spec.modEVFound then -- 1 1 0
		if self.spec.gpsSetting >= 6 then self.spec.gpsSetting = 1 end
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR")
		})
		self.gpsVariant = 6
	end
	if self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and not self.spec.modEVFound then -- 1 0 0
		if self.spec.gpsSetting ~= 2 then self.spec.gpsSetting = 1 end
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
		})
		self.gpsVariant = 4
	end
	if not self.spec.modGuidanceSteeringFound and self.spec.modVCAFound and not self.spec.modEVFound then -- 0 1 0
		if self.spec.gpsSetting >= 6 then self.spec.gpsSetting = 1 end
		if self.spec.gpsSetting > 1 then self.spec.gpsSetting = self.spec.gpsSetting - 1 end
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR")
		})
		self.gpsVariant = 2
	end
	if not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and not self.spec.modEVFound then -- 0 0 0
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
		})
		self.showGPS = false
		self.spec.gpsSetting = 1
	end
	if self.spec.modGuidanceSteeringFound and self.spec.modVCAFound and self.spec.modEVFound then -- 1 1 1
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev_auto")
		})
		self.gpsVariant = 7
	end
	if self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and self.spec.modEVFound then -- 1 0 1
		if self.spec.gpsSetting > 2 and self.spec.gpsSetting < 6 then self.spec.gpsSetting = 1 end
		if self.spec.gpsSetting >= 6 then self.spec.gpsSetting = self.spec.gpsSetting - 3 end
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev_auto")
		})
		self.gpsVariant = 5
	end
	if not self.spec.modGuidanceSteeringFound and self.spec.modVCAFound and self.spec.modEVFound then -- 0 1 1
		if self.spec.gpsSetting > 1 then self.spec.gpsSetting = self.spec.gpsSetting - 1 end
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vca"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaL"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_vcaR"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev_auto")
		})
		self.gpsVariant = 3
	end
	if not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and self.spec.modEVFound then -- 0 0 1
		if self.spec.gpsSetting > 1 and self.spec.gpsSetting < 6 then self.spec.gpsSetting = 1 end
		if self.spec.gpsSetting >= 6 then self.spec.gpsSetting = self.spec.gpsSetting - 4 end
		self.gpsSetting:setTexts({
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_auto"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev"),
			g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev_auto")
		})
		self.gpsVariant = 1
	end
	self.gpsSetting:setState(self.spec.gpsSetting)
	
	local gpsDisabled
	if not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and not self.spec.modEVFound then
		gpsDisabled = true
	else
		gpsDisabled = not self.spec.useGPS
	end
	self.gpsSetting:setDisabled(gpsDisabled or not self.showGPS or self.spec.useEVTrigger)
	self.gpsSetting:setVisible(self.spec.modGuidanceSteeringFound or self.spec.modVCAFound or self.spec.modEVFound)
	
	-- VCA direction switching
	self.gpsDisableDirSwitchTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_vcaDirSwitch"))
	self.gpsEnableDirSwitchSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsEnableDirSwitchSetting:setState(self.spec.vcaDirSwitch and 1 or 2)
	self.gpsEnableDirSwitchSetting:setDisabled(not self.spec.modVCAFound or lastGPSSetting < 4 or lastGPSSetting >= 6)
	self.gpsEnableDirSwitchSetting:setVisible(self.spec.modVCAFound)
	
	-- Headland automatic
	self.gpsAutoTrigger:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSetting"))
	self.gpsAutoTriggerSubTitle:setText(string.format(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSubTitle"),self.spec.vehicleLength,self.spec.vehicleWidth,self.spec.maxTurningRadius))
	self.gpsAutoTriggerTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerSetting"))
	self.gpsAutoTriggerSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	local triggerAnz = 2
	local triggerTexts = ({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on")
	})
	if self.spec.modGuidanceSteeringFound then 
		triggerAnz = triggerAnz + 1
		triggerTexts[triggerAnz] = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_gs") 
	end
	--if self.spec.modEVFound then 
	--	triggerAnz = triggerAnz + 1
	--	triggerTexts[triggerAnz] = g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gps_ev") 
	--end
	self.gpsAutoTriggerSetting:setTexts(triggerTexts)
	self.gpsAutoTriggerSetting:setDisabled(self.spec.useEVTrigger)
	
	local triggerSetting = 1
	triggerAnz = 2
	
	if self.spec.useHLMTriggerF or self.spec.useHLMTriggerB then 
		triggerSetting = 2
	end
	
	if self.spec.modGuidanceSteeringFound then
		triggerAnz = triggerAnz + 1 
		if self.spec.useGuidanceSteeringTrigger then triggerSetting = triggerAnz end
	end
	--if self.spec.modEVFound then
	--	triggerAnz = triggerAnz + 1
	--	if self.spec.useEVTrigger then triggerSetting = triggerAnz end
	--end
	self.gpsAutoTriggerSetting:setState(triggerSetting)
	
	self.gpsAutoTriggerOffsetTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetSetting"))
	self.gpsAutoTriggerOffsetSetting.onClickCallback = HeadlandManagementGui.logicalCheck
	self.gpsAutoTriggerOffsetSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_front"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_back")
	})	
	local offsetSetting = 1
	if self.spec.modGuidanceSteeringFound and triggerSetting == 3 and self.spec.useGuidanceSteeringOffset then 
		offsetSetting = 2 
	elseif triggerSetting == 2 and self.spec.useHLMTriggerB then 
		offsetSetting = 2
	end
	self.gpsAutoTriggerOffsetSetting:setState(offsetSetting)
	self.gpsAutoTriggerOffsetSetting:setDisabled(triggerSetting == 1 or (triggerSetting == 3 and self.gpsEnabled) or (triggerSetting == 3 and not self.spec.modGuidanceSteeringFound) or triggerSetting == 4 or self.spec.useEVTrigger)
	
	self.gpsAutoTriggerOffsetWidthTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_gpsAutoTriggerOffsetWidth"))
	self.gpsAutoTriggerOffsetWidthInput:setText(tostring(self.spec.headlandDistance))
	self.gpsAutoTriggerOffsetWidthInput.onEnterPressedCallback = HeadlandManagementGui.onWidthInput
	self.gpsAutoTriggerOffsetWidthInput:setDisabled(triggerSetting ~= 2 or self.spec.useEVTrigger)
	
	self.gpsResumeTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_autoResume"))
	self.gpsResumeSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.gpsResumeSetting:setState(self.spec.autoResume and 1 or 2)
	self.gpsResumeSetting:setDisabled((not self.spec.modGuidanceSteeringFound and triggerSetting == 3) or triggerSetting == 4 or self.spec.useEVTrigger)
	
	-- Vehicle control
	self.vehicleControl:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_vehicleControl"))
	
	-- Diff control
	self.diffControlOnOffTitle:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_diffLock"))
	self.diffControlOnOffSetting:setTexts({
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_on"),
		g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_off")
	})
	self.diffControlOnOffSetting:setState(self.spec.useDiffLock and 1 or 2)
	self.diffControlOnOffSetting:setDisabled(not self.spec.modVCAFound and not self.spec.modEVFound)
	self.diffControlOnOffSetting:setVisible(self.spec.modVCAFound or self.spec.modEVFound)
	
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
	self.inputbindingsTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_inputbindingsTT"))
	self.alarmVolumeTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_beepVolTT"))
	self.raiseTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_raiseTT"))
	self.plowTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_plowTT"))
	self.ptoTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_ptoTT"))
	self.ridgeMarkerTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_ridgeMarkerTT"))
	self.emptyBalersSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_emptyBalersSettingTT"))
	self.diffLockTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_diffLockTT"))
	self.csTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_csTT"))
	self.contourOnOffTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourOnOffTT"))
	self.contourSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourSettingTT"))
	self.contourWidthSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourWidthSettingTT"))
	self.contourWidthChangeSettingTT:setText(g_i18n.modEnvironments[HeadlandManagement.MOD_NAME]:getText("hlmgui_contourWidthChangeSettingTT"))
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
	self.speedControlUseSCModSetting:setDisabled(not useSpeedControl or (not self.spec.modSpeedControlFound and not self.spec.modECCFound)) 
	
	local useModSpeedControl = self.speedControlUseSCModSetting:getState() == 1
	self.speedControlTurnSpeedSetting1:setDisabled(useModSpeedControl or not useSpeedControl)
	self.speedControlTurnSpeedSetting2:setDisabled(not useModSpeedControl or (not self.spec.modSpeedControlFound and not self.spec.modECCFound) or not useSpeedControl)
	
	local useRaiseImplement = self.raiseSetting:getState() ~= 5	
	self.turnPlowSetting:setDisabled(not useRaiseImplement)
	self.ridgeMarkerSetting:setDisabled(not useRaiseImplement)
	
	local contourOnOffSetting = self.contourOnOffSetting:getState()
	local widthSetting = self.contourWidthSetting:getState()
	self.contourSetting:setDisabled(contourOnOffSetting == 1)
	self.contourWidthSetting:setDisabled(contourOnOffSetting == 1)
	self.contourWidthChangeSetting:setDisabled(contourOnOffSetting == 1 or widthSetting == 1)

	local useGPS = self.gpsOnOffSetting:getState() == 1
	local triggerSetting = self.gpsAutoTriggerSetting:getState()
	--local useEVTrigger = (triggerSetting == 3 and not self.spec.modGuidanceSteeringFound) or (triggerSetting == 4 and self.spec.modGuidanceSteeringFound)
	self.gpsOnOffSetting:setDisabled(not self.spec.modGuidanceSteeringFound and not self.spec.modVCAFound and not self.spec.modEVFound or useEVTrigger)
	
	local gpsSetting = self.gpsSetting:getState()
	if not self.spec.modGuidanceSteeringFound and gpsSetting > 1 then
		gpsSetting = gpsSetting + 1
	end
	self.gpsSetting:setDisabled(not useGPS or not self.showGPS)
	
	self.gpsEnableDirSwitchSetting:setDisabled(not useGPS or not self.spec.modVCAFound or gpsSetting < 4 or gpsSetting > 5)
	
	self.gpsAutoTriggerOffsetSetting:setDisabled(triggerSetting == 1 or (triggerSetting == 3 and self.gpsEnabled))
	
	self.gpsAutoTriggerOffsetWidthInput:setDisabled(triggerSetting ~= 2)
	
	--self.gpsResumeSetting:setDisabled(useEVTrigger)
	
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
	if self.spec.useModSpeedControl then
		self.spec.turnSpeed = self.speedControlTurnSpeedSetting2:getState()
	else 
		local turnSpeed = self.speedControlTurnSpeedSetting1:getState()
		if turnSpeed < 11 then 
			self.spec.turnSpeed = turnSpeed - 11
		else 
			self.spec.turnSpeed = turnSpeed - 10
		end
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
	-- stop emptying balers
	self.spec.stopEmptyBaler = self.emptyBalersSetting:getState() == 1
	-- crab steering
	self.spec.csState = self.crabSteeringSetting:getState()
	self.spec.useCrabSteering = (self.spec.csState ~= 3)
	self.spec.useCrabSteeringTwoStep = (self.spec.csState == 2)
	-- contour guidance
	local contour = self.contourOnOffSetting:getState() -- 1: off, 2: 1 row, 3: every row
	local contourMode = self.contourSetting:getState()  -- 1: next right, 2: next left, 3: always right, 4: always left
	self.spec.contour = 0
	self.spec.contourMultiMode = false
	self.spec.contourNoSwap = false
	if contourMode > 2 then
		self.spec.contourNoSwap = true
		contourMode = contourMode - 2
	end
	if contour == 3 then
		self.spec.contourMultiMode = true
	end
	if contour > 1 and contourMode == 1 then
		self.spec.contour = -1
	elseif contour > 1 and contourMode == 2 then
		self.spec.contour = 1
	end
	local widthMode = self.contourWidthSetting:getState()
	if widthMode == 2 then 
		self.spec.contourWidth = math.floor(self.spec.vehicleWidth * 0.5)
		self.spec.contourWidthMeasurement = false
		self.spec.contourTrack = 1
	elseif widthMode == 3 then 
		self.spec.contourWidth = math.floor(self.spec.vehicleWidth * 1.5)
		self.spec.contourWidthMeasurement = false
		self.spec.contourTrack = 2
	elseif widthMode == 4 then 
		self.spec.contourWidth = math.floor(self.spec.vehicleWidth * 2.5)
		self.spec.contourWidthMeasurement = false
		self.spec.contourTrack = 3
	elseif widthMode == 5 then 
		self.spec.contourWidth = math.floor(self.spec.vehicleWidth * 3.5)
		self.spec.contourWidthMeasurement = false	
		self.spec.contourTrack = 4
	else
		self.spec.contourWidth = 0
		self.spec.contourWidthMeasurement = true
		self.spec.contourTrack = 0
	end		
	self.spec.contourWidthAdaption = self.contourWidthChangeSetting:getState() == 1
	-- gps
	self.spec.useGPS = self.gpsOnOffSetting:getState() == 1
	local gpsSetting = self.gpsSetting:getState()
	-- 1: auto-mode, 2: gs-mode, 3: vca-mode, 4: vca-turn-left, 5: vca-turn-right, 6: ev-mode, 7: ev-mode with auto-turn
	self.spec.gpsSetting = 1
	if self.gpsVariant == 1 and gpsSetting >= 2 then self.spec.gpsSetting = gpsSetting + 4 end
	if self.gpsVariant == 2 and gpsSetting > 1 then self.spec.gpsSetting = gpsSetting + 1 end
	if self.gpsVariant == 3 and gpsSetting > 1 then self.spec.gpsSetting = gpsSetting + 1 end
	if self.gpsVariant == 4 then self.spec.gpsSetting = gpsSetting end
	if self.gpsVariant == 5 and gpsSetting < 3 then self.spec.gpsSetting = gpsSetting end
	if self.gpsVariant == 5 and gpsSetting >= 3 then self.spec.gpsSetting = gpsSetting + 3 end
	if self.gpsVariant == 6 then self.spec.gpsSetting = gpsSetting end
	if self.gpsVariant == 7 then self.spec.gpsSetting = gpsSetting end
	-- headland automatic
	local triggerSetting = self.gpsAutoTriggerSetting:getState()
	local offsetSetting = self.gpsAutoTriggerOffsetSetting:getState()
	if triggerSetting == 1 then
		self.spec.useGuidanceSteeringTrigger = false
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = false
		--self.spec.useEVTrigger = false
	elseif triggerSetting == 2 and offsetSetting == 1 then
		self.spec.useGuidanceSteeringTrigger = false
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = true
		self.spec.useHLMTriggerB = false
		--self.spec.useEVTrigger = false
	elseif triggerSetting == 2 and offsetSetting == 2 then
		self.spec.useGuidanceSteeringTrigger = false
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = true
		--self.spec.useEVTrigger = false
	--elseif (triggerSetting == 3 and not self.spec.modGuidanceSteeringFound) or (triggerSetting == 4 and self.spec.modGuidanceSteeringFound) then
	--	self.spec.useGuidanceSteeringTrigger = false
	--	self.spec.useGuidanceSteeringOffset = false
	--	self.spec.useHLMTriggerF = false
	--	self.spec.useHLMTriggerB = false
	--	self.spec.useEVTrigger = true
	elseif triggerSetting == 3 and offsetSetting == 1 then
		self.spec.useGuidanceSteeringTrigger = true
		self.spec.useGuidanceSteeringOffset = false
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = false
		--self.spec.useEVTrigger = false
	elseif triggerSetting == 3 and offsetSetting == 2 then
		self.spec.useGuidanceSteeringTrigger = true
		self.spec.useGuidanceSteeringOffset = true
		self.spec.useHLMTriggerF = false
		self.spec.useHLMTriggerB = false
		--self.spec.useEVTrigger = false
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
	-- showKeys
	local showKeys = self.inputbindingsSetting:getState() == 1
	-- debug
	local debug = self.debugSetting:getState() == 1
	self.spec.debugFlag = self.debugFlagSetting:getState() == 1

	dbgprint("gpsSetting (GUI): "..tostring(self.spec.gpsSetting), 3)
	self:close()
	self.callbackFunc(self.target, self.spec, debug, showKeys)
end

-- just close gui
function HeadlandManagementGui:onClickBack()
	dbgprint("onClickBack", 3)
	self:close()
end
