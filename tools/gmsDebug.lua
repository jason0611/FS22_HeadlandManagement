--
-- Glowins Modschmiede: Debug-Tool
-- Author: Jason06 / Glowins Mod-Schmiede
-- V1.2.0.0
--

GMSDebug = {}
GMSDebug.modName = "Unknown Mod"
GMSDebug.state = false
GMSDebug.consoleCommands = false

function GMSDebug:init(modName, forceDbg)
	GMSDebug.modName = modName
	GMSDebug.state = (forceDbg == true)
end

function GMSDebug:enableConsoleCommands(command)
	if command==nil then return; end
	addConsoleCommand(command, "Glowins Mod Smithery: Toggle Debug settings", "toggleDebug", GMSDebug)
	--addConsoleCommand("gmsPrint", "Glowins Mod Smithery: Debug printing", "consolePrint", GMSDebug)
	GMSDebug:print("Debug Console Commands added: "..command)
end

function GMSDebug:print(text)
	if not GMSDebug.state then return; end
	print(GMSDebug.modName.." :: "..tostring(text))
end

function GMSDebug:print_r(table)
	if not GMSDebug.state then return; end
	GMSDebug:print("BEGIN OF "..tostring(table).." =================")
	print_r(table)
	GMSDebug:print("END OF "..tostring(table).." =================")
end

function GMSDebug:render(text, pos)
	if not GMSDebug.state then return; end
	if pos == nil then pos = 0; end
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(0, 0.95 - pos * 0.05, 0.03, "GMSDebug: "..text)
end

function GMSDebug:toggleDebug()
	GMSDebug.state = not GMSDebug.state
	print("GMSDebug: New state is "..tostring(GMSDebug.state))
end


function GMSDebug:consolePrint(object)
	print(GMSDebug.modName.." :: BEGIN of "..tostring(object).." =================")
	print_r(object)
	print(GMSDebug.modName.." :: END of "..tostring(object).." =================")
end

--

function dbgprint(text)
	GMSDebug:print(text)
end

function dbgprint_r(table)
	GMSDebug:print_r(table)
end

function dbgrender(text, pos)
	GMSDebug:render(tostring(text), pos)
end
