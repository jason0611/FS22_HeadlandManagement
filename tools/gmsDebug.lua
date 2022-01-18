--
-- Glowins Modschmiede: Debug-Tool
-- Author: Jason06 / Glowins Mod-Schmiede
-- V1.5.1.0
--
-- debug level
-- 1 : default
-- 2 : verbose
-- 3 : onScreen
-- 4 : very verbose / table prints to log

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

function GMSDebug:print_r(table, prio, level)
	if prio == nil then prio = 1; end
	if not GMSDebug.state or prio > GMSDebug.level then return; end
	GMSDebug:print("BEGIN OF "..tostring(table).." (Prio "..tostring(prio)..") =================")
	print_r(table, level)
	GMSDebug:print("END OF "..tostring(table).." =================")
end

function GMSDebug:render(text, pos, prio)
	if prio == nil then prio = 3; end
	if not GMSDebug.state or prio > GMSDebug.level then return; end
	if pos == nil then pos = 1; end
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(0.02, 0.83 - pos * 0.02, 0.01, "GMSDebug: "..text)
end

function GMSDebug:renderTable(data, pos, prio)
	if prio == nil then prio = 3; end
	if not GMSDebug.state or prio > GMSDebug.level then return; end
	if pos == nil then pos = 1; end
	local n = 0
	for i, d in pairs(data) do
		if string.sub(tostring(d), 1, 5) ~= "table" then
			renderText(0.50, 0.95 - (pos + n) * 0.02, 0.01, tostring(i)..": "..tostring(d), pos + n, prio)
			n = n + 1
		end
	end
end

function GMSDebug:toggleDebug(prio)
	local level = tonumber(prio)
	if level == nil or level == GMSDebug.level then
		GMSDebug.state = not GMSDebug.state
	else
		GMSDebug.level = level
	end
	print("GMSDebug: New state is "..tostring(GMSDebug.state).." / Prio-Level is "..tostring(GMSDebug.level))
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

function dbgprint_r(table, prio, level)
	GMSDebug:print_r(table, prio, level)
end

function dbgrender(text, pos, prio)
	GMSDebug:render(tostring(text), pos, prio)
end

function dbgrenderTable(data, pos, prio)
	GMSDebug:renderTable(data, pos, prio)
end
