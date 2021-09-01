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
	"sectionAlarm",
	"alarmTitle",
	"alarmSetting",
	"sectionSpeedControl",
	"speedControlOnOffTitle",
	"speedControlOnOffSetting",
	"speedControlUseSCModTitle",
	"speedControlUseSCModSetting",
	"speedControlNormSpeedTitle",
	"speedControlNormSpeedSetting",
	"speedControlTurnSpeedTitle",
	"speedControlTurnSpeedSetting",
	
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
function HeadlandManagementGui:setData(vehicleName, useSpeedControl, useModSpeedControl, normSpeed, turnSpeed, useRaiseImplement, useStopPTO, useTurnPlow, useRidgeMarker, useGPS, useGuidanceSteering, useVCA, useDiffLock, beep)
	-- Titel
	self.guiTitle:setText(g_i18n:getText("gui_title")..vehicleName)

	-- Hörbarer Alarm
	self.sectionAlarm:setText("Akkustischer Hinweis")
	self.alarmTitle:setText("Alarm")
	self.alarmSetting:setTexts({
		g_i18n:getText("Ein"),
		g_i18n:getText("Aus"),
	})
	self.alarmSetting:setState(beep and 1 or 2, true)
--[[
	self.textTitleElement1:setText(g_i18n:getText("licensePlatesTextTitle1"))
	self.textTitleElement2:setText(g_i18n:getText("licensePlatesTextTitle2"))
	self.textTitleElement3:setText(g_i18n:getText("licensePlatesTextTitle3"))
	self.textElement:setText(text)

	self.symbolColorTitleElement:setText(g_i18n:getText("licensePlatesSymbolColorTitle"))
	self.symbolColorElement:setTexts({
		g_i18n:getText("licensePlatesSymbolColorBlack"),
		g_i18n:getText("licensePlatesSymbolColorGreen"),
		g_i18n:getText("licensePlatesSymbolColorRed")
	})
	self.symbolColorElement:setState(symbolColor)

	self.backgroundColorTitleElement:setText(g_i18n:getText("licensePlatesBackgroundColorTitle"))
	self.backgroundColorElement:setTexts({
		g_i18n:getText("licensePlatesBackgroundColorWhite"),
		g_i18n:getText("licensePlatesBackgroundColorYellow"),
		g_i18n:getText("licensePlatesBackgroundColorRed"),
		g_i18n:getText("licensePlatesBackgroundColorGreen")
	})
	self.backgroundColorElement:setState(backgroundColor)

	self.countryCodeTitleElement:setText(g_i18n:getText("licensePlatesCountryCodeTitle"))
	-- works because gui uses only number as index
	self.countryCodeElement:setTexts(LicensePlates.COUNTRY_CODES)
	self.countryCodeElement:setState(countryCode)

	self.smallPlateFormatTitleElement1:setText(g_i18n:getText("licensePlatesSmallPlateFormatTitle1"))
	self.smallPlateFormatTitleElement2:setText(g_i18n:getText("licensePlatesSmallPlateFormatTitle2"))
	self.smallPlateFormatTitleElement3:setText(g_i18n:getText("licensePlatesSmallPlateFormatTitle3"))
	self.smallPlateFormatElement:setTexts({
		"5-5",
		"4-6"
	})
	self.smallPlateFormatElement:setState(useFormat46 and 2 or 1, true)
	--]]
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
	local UseSpeedControl
	local UseModSpeedControl
	local NormSpeed
	local TurnSpeed
	local UseRaiseImplement
	local UseStopPTO
	local UseTurnPlow
	local UseRidgeMarker
	local UseGPS
	local UseGuidanceSteering
	local UseVCA
	local UseDiffLock
	local beep = self.alarmSetting:getIsChecked()
	--[[
	local isVisible = self.visibilityElement:getIsChecked()
	local text = self.textElement:getText()
	local symbolColor = self.symbolColorElement:getState()
	local backgroundColor = self.backgroundColorElement:getState()
	local countryCode = self.countryCodeElement:getState()
	local useFormat46 = self.smallPlateFormatElement:getIsChecked()
	--]]
	self:close()
	self.callbackFunc(useSpeedControl, useModSpeedControl, normSpeed, turnSpeed, useRaiseImplement, useStopPTO, useTurnPlow, useRidgeMarker, useGPS, useGuidanceSteering, useVCA, useDiffLock, beep)
end

-- just close gui
function HeadlandManagementGui:onClickBack()
	self:close()
end
