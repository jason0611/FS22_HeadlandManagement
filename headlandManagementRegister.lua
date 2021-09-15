--
-- register
--
-- Martin Eller 
-- Version 0.5.0.0
--
-- 
--
--[[
if g_specializationManager:getSpecializationByName("headlandManagement") == nil then
    g_specializationManager.addSpecialization('headlandManagement', 'headlandManagement', 'headlandManagement', Utils.getFilename('headlandManagement.lua', g_currentModDirectory))
end
]]
    

function addHLMconfig(xmlFile, superfunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
    local configurations = superfunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
	dbgprint("addHLMconfig : Name: "..storeItem.xmlFilename.." / Kat: "..storeItem.categoryName)

	local category = storeItem.categoryName
	if 
			category == "TRACTORSS" 
		or	category == "TRACTORSM"
		or	category == "TRACTORSL"
		or	category == "HARVESTERS"
		or	category == "FORAGEHARVESTERS"
		or	category == "BEETVEHICLES"
		or	category == "POTATOVEHICLES"
		or	category == "COTTONVEHICLES"
		or	category == "SPRAYERVEHICLES"
		or	category == "SUGARCANEVEHICLES"
		or	category == "MOWERVEHICLES"
		or	category == "MISCVEHICLES"
		
		and	configurations ~= nil

	then
		configurations["headlandManagement"] = {
        	{name = "Nicht vorhanden", index = 1, isDefault = true,  price = 0, dailyUpkeep = 0, desc = "Kein Vorgewendemanagement"},
        	{name = "Vorhanden", index = 2, isDefault = false, price = 25000, dailyUpkeep = 0, desc = "Vorgewendemanagement eingebaut"}
    	}
	end
	
    return configurations
end

if g_specializationManager:getSpecializationByName("headlandManagement") == nil then
  	g_specializationManager:addSpecialization("headlandManagement", "headlandManagement", g_currentModDirectory.."headlandManagement.lua", true, nil)
end

for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
    
    if
    		SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) 
		and	SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
		and	SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    	and not
    
		(
    		SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations)
		or	SpecializationUtil.hasSpecialization(ConveyorBelt, typeEntry.specializations)
    	)
    
    then
     	g_vehicleTypeManager:addSpecialization(typeName, "headlandManagement")
--		print("headlandManagement registered for "..typeName)
    end
end

if g_configurationManager.configurations["headlandManagement"] == nil then
	g_configurationManager:addConfigurationType("headlandManagement", g_i18n:getText("text_HLM_configuration"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, addHLMconfig)
end

-- make localizations available
local i18nTable = getfenv(0).g_i18n
for l18nId,l18nText in pairs(g_i18n.texts) do
  i18nTable:setText(l18nId, l18nText)
end


