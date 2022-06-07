--
-- Register Headland Management for LS 22
--
-- Jason06 / Glowins Modschmiede 
-- Version 2.1.1.8 beta
--

local specName = g_currentModName..".HeadlandManagement"

if g_specializationManager:getSpecializationByName("HeadlandManagement") == nil then
  	g_specializationManager:addSpecialization("HeadlandManagement", "HeadlandManagement", g_currentModDirectory.."headlandManagement.lua", nil)
  	dbgprint("Specialization 'HeadlandManagement' added", 2)
end

for typeName, typeEntry in pairs(g_vehicleTypeManager.types) do
    if
    		SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) 
		and	SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
		and	SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    	and not SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations)
    
    then
     	g_vehicleTypeManager:addSpecialization(typeName, specName)
		dbgprint(specName.." registered for "..typeName)
    end
end

