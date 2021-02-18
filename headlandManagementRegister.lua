--
-- register
--
-- Martin Eller 
-- Version 0.0.3.0
--
-- Refactoring
--

if g_specializationManager:getSpecializationByName("headlandManagement") == nil then

  g_specializationManager:addSpecialization("headlandManagement", "headlandManagement", g_currentModDirectory.."headlandManagement.lua", true, nil)

  for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
    
    if    
    		SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) 
    and  	SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
    and  	SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    and not
    (
    		SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations)
    or		SpecializationUtil.hasSpecialization(ConveyorBelt, typeEntry.specializations)
    )
    
    then
      g_vehicleTypeManager:addSpecialization(typeName, "headlandManagement")
      print("headlandManagement registered for "..typeName)
    end
  end
end
