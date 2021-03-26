--
-- register
--
-- Martin Eller 
-- Version 0.1.1.1
--
-- 
--

if g_specializationManager:getSpecializationByName("headlandManagement") == nil then

  g_specializationManager:addSpecialization("headlandManagement", "headlandManagement", g_currentModDirectory.."headlandManagement.lua", true, nil)

  for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
    
    if
			typeName ~= "woodTruck"
		and	typeName ~= "FBM19_UnimogU1X00.unimogU1600"
		and	typeName ~= "drivableMixerWagon"
		and	typeName ~= "teleHandler"
		and	typeName ~= "woodCrusherTrailerDrivable"
		and	typeName ~= "FS19_EDGE_Roller.EDGE_roller"
		and	typeName ~= "forwarder"
		and	typeName ~= "FS19_electricPalletTruck.palletTruck"
		and	typeName ~= "woodHarvester"
		and	typeName ~= "carFillable"
		and	typeName ~= "FS19_Fendt_250GT.gt"
		and	typeName ~= "FS19_BMW_330d_xDrive_Touring.3_Series"

	and
	
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
end

-- make localizations available
local i18nTable = getfenv(0).g_i18n
for l18nId,l18nText in pairs(g_i18n.texts) do
  i18nTable:setText(l18nId, l18nText)
end
