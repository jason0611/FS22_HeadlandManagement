--
-- Glowins Modschmiede: Debug-Tool
-- Author: Jason06 / Glowins Mod-Schmiede
-- V1.3.1.0
--

GMSDebug = {}
GMSDebug.modName = "Unknown Mod"
GMSDebug.state = false
GMSDebug.consoleCommands = false

function GMSDebug:init(modName, dbg, dbgLevel)
	GMSDebug.modName = modName
	GMSDebug.state = (dbg == true)
	if dbgLevel == nil then 
		GMSDebug.level = 1
	else	
		GMSDebug.level = dbgLevel
	end
end

function GMSDebug:enableConsoleCommands(command)
	if command==nil then return; end
	addConsoleCommand(command, "Glowins Mod Smithery: Toggle Debug settings", "toggleDebug", GMSDebug)
	--addConsoleCommand("gmsPrint", "Glowins Mod Smithery: Debug printing", "consolePrint", GMSDebug)
	GMSDebug:print("Debug Console Commands added: "..command)
end

function GMSDebug:print(text, prio)
	if prio == nil then prio = 1; end
	if not GMSDebug.state or prio > GMSDebug.level then return; end
	print(GMSDebug.modName.." :: Prio "..tostring(prio).." :: "..tostring(text))
end

function GMSDebug:print_r(table, prio)
	if prio == nil then prio = 1; end
	if not GMSDebug.state or prio > GMSDebug.level then return; end
	GMSDebug:print("BEGIN OF "..tostring(table).." =================", prio)
	print_r(table)
	GMSDebug:print("END OF "..tostring(table).." =================", prio)
end

function GMSDebug:render(text, pos, prio)
	if prio == nil then prio = 1; end
	if not GMSDebug.state or prio > GMSDebug.level then return; end
	if pos == nil then pos = 1; end
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(0, 0.95 - pos * 0.05, 0.03, "GMSDebug: "..text)
end

function GMSDebug:toggleDebug(prio)
	GMSDebug.state = not GMSDebug.state
	GMSDebug.level = tonumber(prio) or 1
	print("GMSDebug: New state is "..tostring(GMSDebug.state).." / Prio-Level is "..tostring(GMSDebug.level)))
end


function GMSDebug:consolePrint(object)
	print(GMSDebug.modName.." :: BEGIN of "..tostring(object).." =================")
	print_r(object)
	print(GMSDebug.modName.." :: END of "..tostring(object).." =================")
end

--

function dbgprint(text, prio)
	GMSDebug:print(text, prio)
end

function dbgprint_r(table, prio)
	GMSDebug:print_r(table, prio)
end

function dbgrender(text, pos, prio)
	GMSDebug:render(tostring(text), pos, prio)
end
