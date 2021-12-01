--
-- Register Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede 
-- Version 1.9.0.1
--

function addHLMconfig(xmlFile, superfunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
    local configurations, defaultConfigurationIds = superfunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
	dbgprint("addHLMconfig : Kat: "..storeItem.categoryName.." / ".."Name: "..storeItem.xmlFilename, 2)

	local category = storeItem.categoryName
	if 
		(	category == "TRACTORSS" 
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
		or 	category == "JOHNDEEREPACK"
		)
		and	configurations ~= nil

	then
		configurations["HeadlandManagement"] = {
        	{name = g_i18n:getText("text_HLM_notInstalled_short"), index = 1, isDefault = true,  isSelectable = true, price = 0, dailyUpkeep = 0, desc = g_i18n:getText("text_HLM_notInstalled")},
        	{name = g_i18n:getText("text_HLM_installed_short"), index = 2, isDefault = false, isSelectable = true, price = 3000, dailyUpkeep = 0, desc = g_i18n:getText("text_HLM_installed")}
    	}
    	dbgprint("addHLMconfig : Configuration HeadlandManagement added", 2)
    	dbgprint_r(configurations["HeadlandManagement"], 3)
	end
	
    return configurations, defaultConfigurationIds
end

if g_specializationManager:getSpecializationByName("HeadlandManagement") == nil then
  	g_specializationManager:addSpecialization("HeadlandManagement", "HeadlandManagement", g_currentModDirectory.."headlandManagement.lua", true, nil)
  	dbgprint("Specialization 'HeadlandManagement' added", 2)
end

for typeName, typeEntry in pairs(g_vehicleTypeManager.types) do
    if
    		SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) 
		and	SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
		and	SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    	and not SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations)
    
    then
     	g_vehicleTypeManager:addSpecialization(typeName, "HeadlandManagement")
		dbgprint("registered for "..typeName)
    end
end

if g_configurationManager.configurations["HeadlandManagement"] == nil then
	g_configurationManager:addConfigurationType("HeadlandManagement", g_i18n:getText("text_HLM_configuration"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	dbgprint("Configuration 'HeadlandManagement' defined", 2)
	StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, addHLMconfig)
end


