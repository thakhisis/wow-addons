--[[ 

FMR Loot System 
Visit www.wowaces.com for latest version and more information
by Frujin, <Ace of Spades>, EU Zenedar

]]--


-- SAVED VARIABLES BEGIN --

-- Settings
AOS_Settings = { AcePos = 260, SyncChannelName = "aoscomchan", SyncChannelPassword = "aosvox", ShowSyncMsg = 0, LastSrvMin = 0, LastSrvSec = 0, LastSrvHour = 0};

-- Guild Information (name, bonus, timestamp)
AOS_Guild_303 = {}


-- GLOBALS --
g_fmrVersion = "3.0b-classic"
g_fmrTooltipON  = false

g_fmrOldLootMenu = nil

g_fmrRaid = nil
g_fmrGuild = nil
g_fmrSync = {}

-- Array of Rolls in current session {Item, Turns = {1 = {name = {roll, frm, etc}, ... } , 2 = ...} }
g_fmrRolls = {}
g_fmrRollTurn = 1
g_fmrRollNum = 0
g_fmrCurRoll = 1
g_fmrCurItemLink = nil

-- table to store flags by name like (fNew, fOut, fSelected, etc)

g_fmrRolling = false
g_fmrReady = false

local g_fmrSyncTick = 1 -- number of seconds between two sync's
local g_fmrMinSyncDelay = 30 -- 30 seconds before synch'ing player again
local g_fmrMinErrDelay = 240 -- seconds before spamming errors for players
local g_fmrLastSyncTime = 0 -- time of the last sync
local g_fmrSynced = true -- current status
local g_fmrLastTick = 0 -- last request
local g_fmrWaitTime = 30 -- default time between requests
local g_fmrMaxWaitTime = 180 -- time between request can increase up to this one to save traffic
local g_fmrMinWaitTime = 30 -- minimum time between request for updates


g_fmrSrvMinStartTime = 0 -- time when server minute did start
g_fmrSrvSec = 0 -- a wild guess for the seconds on the server
g_fmrSrvMin = 0 -- a last minute value reported by the game server 

local g_fmrEmptyCell = "  -"

g_fmrGuildName = nil
g_fmrGuildIdx = nil


-- Some Numbers

g_fmrMaxLuck = 300
g_fmrItemCost = 50
g_fmrLuckGain = 1
g_fmrCurPlayer = nil
g_fmrMaxRankToLoot = 3

-- Some global vars, triggers etc.. 

g_fmrListMode = "guild"
g_fmrSortKey = "name+"
g_fmrLastSortKey = ""
g_fmrSortIndex = nil
g_fmrForcedWinner = nil
g_fmrIsMasterLooter = false
g_fmrCanChangeNote = false
g_fmrIsOfficer = false

-- current roll status 

g_fmrRollWinner = nil
g_fmrRollResult = nil

-- Some colors 

g_fmrClassRGB = { 
	Rogue =  "fff0e665",
	Druid = "fff1760c",
	Mage = "ff69ccf0",
	Priest = "ffeeeeee",
	Warlock = "ffa287dc",
	Warrior = "ffb18a66",
	Paladin = "ffe583ae",
	Hunter = "ffa0c66c",
	DeathKnight = "ffa0063c",
	Shaman = "ff00DBBA"
}

g_fmrFMRRollsRGB = { 
	Normal = "ffc0c0c0",
	Tie = "ffffde00",
	Win = "ff57f347",
	Bad = "ffff0000"
}

g_fmrRealRollsRGB = { 
	Normal = "ff959595",
	Tie = "ffc1a800",
	Win = "ff3ba32f",
	Bad = "ffaa0000"
}

g_fmrLuckRGB = {
	Gray = "ff9d9d9d",		-- gray
	White= "ffffffff",		-- white
	Green = "ff1eff00",		-- green
	Blue = "ff0070dd",		-- blue
	Purple = "ffa335ee",	-- purple
	Orange = "ffff8000"		-- orange
}


---------------------------------------------------------------------------------------------
--------------------------------------------------------------- CODE ------------------------
---------------------------------------------------------------------------------------------



function fmr_OnLoad()

	fmr_Note(1, "Initializing ...")
	fmr_Note(1, "Version: " .. g_fmrVersion)

	-- Init globas
	g_fmrCurRoll = 1
	g_fmrRolling = false
	g_fmrSync = {}

	SlashCmdList["FMRCMD"] = function(msg)
		if msg == "" then
			fmr_Print("|cff00ff00" .. "FMR|r commands:")
			fmr_Print("|cffffff00/fmr|r - Shows this text")
			fmr_Print("|cffffff00/fmr options|r - Shows options window")
			fmr_Print("|cffffff00/fmr raid|r - Shows raid rewards window")
			fmr_Print("|cffffff00/fmr purge|r - Removes players that are no longer guild memebers from the database!")
			fmr_Print("|cffffff00/fmr init <number>|r - Set's all guild members LP to <number>. If <number> is zero or skipped FMR will set random LP to everyone!")
		else
			local args = {};
			local word;
			for word in string.gmatch(msg, "[^%s]+") do
				table.insert(args, word);
			end
			
			local cmd = string.lower(args[1]);
	
			if cmd == "options" then
				FMR_O:Show();
			elseif cmd == "init" then 
				local n = tonumber(args[2])
				if not n then n = 0 end
				fmr_Init(n)
			elseif cmd == "raid" then 
				FMR_RM:Show()
			elseif cmd == "purge" then 
				fmr_Purge()
			end
		end
	end
	SLASH_FMRCMD1 = "/fmr";

	fmr_Err("reg event")

	-- Register events.
	this:RegisterEvent("CHAT_MSG_SYSTEM")
	this:RegisterEvent("CHAT_MSG_GUILD")
	this:RegisterEvent("CHAT_MSG_RAID")
	this:RegisterEvent("GUILD_ROSTER_UPDATE")
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("RAID_ROSTER_UPDATE")
	
	FMR_O_Title:SetText(" FMR Settings " .. g_fmrVersion .. " ")
	
end

function fmr_OnEvent(e)
	if e == "VARIABLES_LOADED" then
		FMR_AcePos:SetValue(AOS_Settings.AcePos)
		g_fmrListMode = "guild"
		FMR_S_ModeBTN:SetText("Show Raid")
		FMR_S_ModeBTN:Disable("Show Raid")
		FMR_H_WinBTN:Disable()
		FMR_S_RollBTN:Hide()
		FMR_S_MenageBTN:Hide()
		
		FMR_S_Title:SetText("GUILD STANDINGS")
		FMR_S:Hide()
		FMR_O_SyncMsg:SetChecked(AOS_Settings.ShowSyncMsg)

		-- we do not want get back in time, so to say ... :)
		-- if we recover after crash, we CAN be screwed a little ... 0.001% chance :) 

		local srvHour, srvMin = GetGameTime()
		if srvMin == AOS_Settings.LastSrvMin and srvHour == AOS_Settings.LastSrvHour then
			g_fmrSrvSec = AOS_Settings.LastSrvSec
			g_fmrSrvMin = AOS_Settings.LastSrvMin
			g_fmrSrvMinStartTime = GetTime() - g_fmrSrvSec
			local s = string.format(
						"Assuming server time |cffffc706%.2d|r:|cffffc706%.2d|r:|cffffc706%.2d", 
						AOS_Settings.LastSrvHour, 
						AOS_Settings.LastSrvMin, 
						g_fmrSrvSec)
			fmr_Note(1, s)
		end

		-- setting up the guild data

		FMR_S_Guild:SetText("n/a")
		GuildRoster()
		fmr_UpdateRaid()
		return
	end

	if e == "GUILD_ROSTER_UPDATE" then
		local guildName, guildRankName, guildRankID = GetGuildInfo("player");

		if not guildName then
			fmr_Err("Initialization pending ... ")
			g_fmrReady = false
			FMR_S_Guild:SetText("n/a")
			return
		end
		
		g_fmrIsOfficer = guildRankID < g_fmrMaxRankToLoot
		g_fmrCanChangeNote = CanEditOfficerNote() == 1
		FMR_S_Guild:SetText(guildName)

		if guildName ~= g_fmrGuildName then
			g_fmrGuildName = guildName
			g_fmrGuildIdx = g_fmrGuildName .. " | " .. GetRealmName()
			fmr_Note(1, "Loaded and ready for: " .. g_fmrGuildIdx)
			-- Request guild info update
			if not AOS_Guild_303[g_fmrGuildIdx] then
				AOS_Guild_303[g_fmrGuildIdx] = {}
			end
			g_fmrGuild = AOS_Guild_303[g_fmrGuildIdx]
			g_fmrReady = true
			fmr_UpdateRaid()
		end 

--		if arg1 and arg1 == 1 then
			-- Haha Blizzard sucks :) 
--			return
--		end
		fmr_SyncRoster()
		fmr_UpdateListWnd()
		return
	end

	if e == "RAID_ROSTER_UPDATE" then
		fmr_UpdateRaid()
		fmr_UpdateListWnd()
		return 
	end

    if (event == "CHAT_MSG_SYSTEM") then 
    	fmr_ParseRoll(arg1)
		return
    end 

    if (event == "CHAT_MSG_GUILD") then 
    	fmr_ParseGuildCmd(arg1, arg2, "GUILD")
		return
    end 

    if (event == "CHAT_MSG_RAID") then 
    	fmr_ParseGuildCmd(arg1, arg2, "RAID")
		return
    end 
	
end

function fmr_OnUpdate()

	local currTick = GetTime()
	local srvHour, srvMin = GetGameTime()

	-- calculate server seconds .. method is eligible for "Nobel prize" ... hehe .. :(

	if srvMin ~= g_fmrSrvMin then 
		-- new minute begins
		g_fmrSrvMin = srvMin
		g_fmrSrvMinStartTime = currTick
		g_fmrSrvSec = 0 -- starting again from zero 
		AOS_Settings.LastSrvMin = g_fmrSrvMin
		AOS_Settings.LastSrvSec = g_fmrSrvSec
		AOS_Settings.LastSrvHour = srvHour
	else
		if g_fmrSrvSec < 59 then -- freezing seconds to 59 :) 
			g_fmrSrvSec = math.floor(currTick - g_fmrSrvMinStartTime)
			AOS_Settings.LastSrvSec = g_fmrSrvSec
		end
	end

	-- data synch scheduling 
	
	if currTick - g_fmrLastTick > g_fmrWaitTime then 
		g_fmrLastTick = currTick
		if not g_fmrSynced then
			g_fmrWaitTime = g_fmrMinWaitTime
		elseif g_fmrWaitTime < g_fmrMaxWaitTime then 
			g_fmrWaitTime = g_fmrWaitTime + 5
		end
		guildName = GetGuildInfo("player")
		if guildName then
			GuildRoster()
		end
	end
end

function fmr_SetAceTooltip()
	GameTooltip:SetOwner(FMR_ACE, "ANCHOR_LEFT");
	GameTooltip:SetText("FMR Loot System " .. g_fmrVersion);
	GameTooltip:AddLine(" ", 1.00, 0.86, 0.00);
	if g_fmrReady then
		local name = UnitName("player")
		if g_fmrGuild[name] then
			local luck = g_fmrGuild[name].Luck
			GameTooltip:AddLine("|cffffffff" .. name .. "|r has " .. fmr_GetLuckColor(luck) .. tostring(luck) .. "|r Luck Points", 0.30, 0.86, 0.00);
			GameTooltip:AddLine(" ", 1.00, 0.86, 0.00);
		end
		GameTooltip:AddLine("Left Button to show Standings", 0.12, 0.62, 0.00);
		GameTooltip:AddLine("Right Button to show Options", 0.12, 0.62, 0.00);
		GameTooltip:AddLine(" ", 1.00, 0.86, 0.00);
		if g_fmrSynced then
			GameTooltip:AddLine("Status: |cff4cdc00synchronized|r!", 0.8, 0.8, 0.8);
		else
			GameTooltip:AddLine("Status: |cffd99221synchronizig|r ...", 0.8, 0.8, 0.8);
		end
	else
		GameTooltip:AddLine("Status: |cffff2020inactive|r ...", 0.8, 0.8, 0.8);
	end
end

function fmr_StartRoll(itemlink, classes)
	if g_fmrRolling then
		fmr_Err("Roll session is already active!")
		return
	end  
	
	if not fmr_CanLoot() then
		fmr_Err("You has no rights to initiate FMR roll!")
		return
	end  
	g_fmrCurItemLink = itemlink
    g_fmrRolling = true
	g_fmrForcedWinner = nil
	FMR_R:Show()
	FMR_S_RollBTN:Disable()

	fmr_UpdateRaid()

    g_fmrRollNum = g_fmrRollNum + 1
    g_fmrRollTurn = 1
    
    g_fmrRolls[g_fmrRollNum] = {}
    g_fmrRolls[g_fmrRollNum][g_fmrRollTurn] = {}
    
    fmr_UpdateRoll()
    if classes and itemlink then 
	    fmr_Message(classes .. " for " .. itemlink .. " may ROLL NOW!")
    elseif itemlink then
	    fmr_Message("Qualified players for " .. itemlink .. " may ROLL NOW!")
    else
	    fmr_Message("Qualified players may ROLL NOW!")
    end
end

function fmr_dump_roll(r, dest)
	local s = string.format("%6d", r.rFMR)
	fmr_Print("<FMR> " .. s .. "  " .. r.rName.. "  (r:" .. r.rRoll .. ", l:" .. g_fmrGuild[r.rName].Luck .. ")" , dest)
end

function fmr_EndRoll()
    if not g_fmrRolling then
 	    fmr_Err("No active roll session!")
 	    return
	end	

    g_fmrRolling = false

	FMR_R:Hide()
	FMR_S_RollBTN:Enable()
	
	
    fmr_Message("ROLL #" .. g_fmrRollNum .. " HAS ENDED!")
 
 	local n = g_fmrRollNum
 	
 	if g_fmrRollResult == "empty" then
		fmr_Print("<FMR> (no recorded rolls)", dest)
		return
	end

	local numturns = table.getn(g_fmrRolls[n])
	
	for j = 1, numturns do
		fmr_Print("<FMR> (turn #" .. j..")", dest)
		for i = 1, table.getn(g_fmrRolls[n][j]) do 
			fmr_dump_roll(g_fmrRolls[n][j][i], dest) 
		end
	end    	
	if g_fmrRollResult == "tie" then
		fmr_Print("<FMR> WINNER: N/A, tie!", dest)
		return
	end
	if g_fmrRollResult == "forced" then
		fmr_Print("<FMR> WINNER: ".. g_fmrRollWinner .. " (Forced)", dest)
	end
	if g_fmrRollResult == "win" then
		fmr_Print("<FMR> WINNER: ".. g_fmrRollWinner, dest)
	end
	fmr_Print("<FMR> (end of roll history)", dest)
 	fmr_ViewPlayer(g_fmrRollWinner)
end

function fmr_CanLoot()
	return g_fmrReady and g_fmrIsMasterLooter and g_fmrCanChangeNote and g_fmrIsOfficer
end

function fmr_CanEditData()
	return g_fmrReady and g_fmrCanChangeNote and g_fmrIsOfficer
end

function fmr_ListMode(s)
	g_fmrListMode = a
	g_fmrUpdateListWnd()
end


function fmr_ModifyRoll(name, roll)
  	if not g_fmrRaid[name] then 
  		fmr_Err("Player " .. name .. " not in the raid! Can't modify his roll ...")
  		return roll
  	end
  	if not g_fmrGuild[name] then 
  		fmr_Message("Player " .. name .. " not in the guild! Can't modify his roll ...")
  		return roll
  	end

	return roll + g_fmrGuild[name].Luck

end

function fmr_AddRaidMember(name, class, group)
  if not g_fmrRaid[name] then 
	g_fmrRaid[name] = { 
	  Name = name,
	  Class = class,
	  Group = group
	}
  end
end

function fmr_ParseData(data)
	local result, luck, ts, stats

	if not data or data == "" then 
		return false, nil, nil, "no data"
	end
	
	stats = fmr_ExtractStats(data)
    ts = fmr_ExtractTS(stats)
    luck = fmr_ExtractBonus(stats)
	
	if not (stats and ts and luck) then
		return false, nil, nil, "syntax"
	end
	
	return true, luck, ts, nil
end

function fmr_MarkTime(name)
	if not g_fmrSync[name] then	g_fmrSync[name] = { LastTS = 0} end
	g_fmrSync[name].LastTS = GetTime()
end

function fmr_GetTimeDelay(name)
	if not g_fmrSync[name] then
		g_fmrSync[name] = { LastTS = 0 }
	end
	return GetTime() - g_fmrSync[name].LastTS
end

function fmr_SyncRoster() 
 
-- something changed into the guild roster
 
 	if not g_fmrReady then 
 		return
 	end
 	
	local num = GetNumGuildMembers(true);

	if not num or num == 0 then
		fmr_Err("Invalid guild members count - sync!")
		g_fmrReady = false
		return
	end

	for p in pairs(g_fmrGuild) do
		g_fmrGuild[p].flag_InGuild = false
	end

	local oldSyncStatus = g_fmrSynced
	g_fmrSynced = true -- assume we are synch'ed
	
	local srvTS, srvStats, name, srvClass, officernote, srvLuck;

	local oldLuck = nil
	local playerName = UnitName("player")
	if g_fmrGuild[playerName] then
		oldLuck = g_fmrGuild[playerName].Luck
	end 
	
	for i = 1, num do
		-- get next player
		name, _, _, _, srvClass, _, _, data = GetGuildRosterInfo(i);
		if (srvClass == "Death Knight") then 
			srvClass = "DeathKnight" 
		end
		local DATA_IS_OK, srvLuck, srvTS, DATA_ERR = fmr_ParseData(data)

		if DATA_IS_OK then

			-- data was okay, processing ...

			if not g_fmrGuild[name] then
				-- no such player in local data .. ADDING it
	    		g_fmrGuild[name] = {
					Name = name,
					Luck = srvLuck,
					Class = srvClass,
					TS = srvTS,
					flag_InGuild = true
				}
				fmr_Note(AOS_Settings.ShowSyncMsg, "Adding .. " .. name)
				g_fmrSynced = false
			else
				-- player exists, synch'ing
				g_fmrGuild[name].flag_InGuild = true

				-- which info is newer?
				local ts_diff, daysoff = fmr_CompareTS(g_fmrGuild[name].TS, srvTS) 
			
				if not fmr_CanEditData() then
					-- CLIENT mode, blindly take server data
					if ts_diff ~= 0 or g_fmrGuild[name].Luck ~= srvLuck then
						-- server timestamp was different than local or data was different
						-- notify and set Sync state to false
						fmr_Note(AOS_Settings.ShowSyncMsg, "Downloading .. " .. name)
						g_fmrSynced = false
					end
					g_fmrGuild[name].Class = srvClass
					g_fmrGuild[name].Luck = srvLuck
					g_fmrGuild[name].TS = srvTS
				else
					-- MASTER mode, full synch with server
					if ts_diff == 1 then
						-- server info is newer 
						g_fmrGuild[name].Class = srvClass
						g_fmrGuild[name].Luck = srvLuck
						g_fmrGuild[name].TS = srvTS
						fmr_Note(AOS_Settings.ShowSyncMsg, "Downloading .. " .. name)
						g_fmrSynced = false

					elseif ts_diff == -1 then
						-- local info is newer
						if fmr_GetTimeDelay(name) > g_fmrMinSyncDelay then
							-- enough time passed, it is safe to synch this player again
							GuildRosterSetOfficerNote(i, fmr_Stats2Str(g_fmrGuild[name].TS, g_fmrGuild[name].Luck))
							fmr_MarkTime(name)
							fmr_Note(AOS_Settings.ShowSyncMsg, "Uploading .. " .. name)
						end
						g_fmrSynced = false -- we are not synch'ed this turn

					else 
						-- the timestamp of local and server data are the same
						if g_fmrSync[name] then	g_fmrSync[name] = nil end -- remove player from the synch cash

						if g_fmrGuild[name].Luck ~= srvLuck then
							-- if server and local data are different 
							-- server data overrides local anyway :) 
							g_fmrGuild[name].Luck = srvLuck 
							fmr_Note(AOS_Settings.ShowSyncMsg, "Equal timestamps ... " .. name)
							fmr_Note(AOS_Settings.ShowSyncMsg, "Overriding local data ... " .. name)
							g_fmrSynced = false
						end 
					end
				end
			end
		else

			-- data was BAD, processing ...

			if g_fmrGuild[name] then
				g_fmrGuild[name].flag_InGuild = true
			end

			if fmr_CanEditData() then
				-- have to be MASTER mode to take action

				if DATA_ERR == "syntax" then
					-- nothing much that can be done ..only notify MASTER user 
					if fmr_GetTimeDelay(name) > g_fmrMinErrDelay then
						fmr_Err("Bad data syntax for player " .. name .. " : |cffff0000" .. data .. "|r")
						if g_fmrGuild[name] then
							fmr_Err("Last valid information for " .. name .. " was: |cff00a000" .. 
									fmr_Stats2Str(g_fmrGuild[name].TS, g_fmrGuild[name].Luck) .. "|r")
						end
						fmr_Err("|cffff0000Please, check Officer Note ...|r")
						fmr_MarkTime(name)
					end

				elseif DATA_ERR == "no data" then
					-- the officer note was empty .. 
					if g_fmrGuild[name] then
						-- perhaps player that rejoined the guild, after leaving
						if fmr_GetTimeDelay(name) > g_fmrMinSyncDelay then
							fmr_Err("Missing data for player " .. name .. "! Restoring last known data ...")
							fmr_Err("Player " .. name .. " now has " .. g_fmrGuild[name].Luck .. " LP ...")
							GuildRosterSetOfficerNote(i, fmr_Stats2Str(g_fmrGuild[name].TS, g_fmrGuild[name].Luck))
							fmr_MarkTime(name)
						end
					else
						-- perhaps new player
			    		g_fmrGuild[name] = {
							Name = name,
							Luck = 0,
							Class = srvClass,
							TS = fmr_GetServerTS(),
							flag_InGuild = true
						}
						fmr_Note(AOS_Settings.ShowSyncMsg, "Adding .. " .. name)
						fmr_Note(1, "Adding new player " .. name .. "! Zero Luck Points assigned ... ")
						g_fmrSynced = false
						GuildRosterSetOfficerNote(i, fmr_Stats2Str(g_fmrGuild[name].TS, g_fmrGuild[name].Luck))
						fmr_MarkTime(name)
					end
				end
			end
		end
	end
	
	-- check for change in personal luck  :) 

	if oldLuck ~= nil then
		local luck_diff = g_fmrGuild[playerName].Luck - oldLuck
		if luck_diff > 0 then
			fmr_Note(1, "You gained |cff00ff00" .. luck_diff .. "|r LP ...")
		elseif luck_diff < 0 then
			fmr_Note(1, "You lost |cffff0000" .. math.abs(luck_diff) .. "|r LP ...")
		end
	end	
	-- if not officer we flush local dead entries

	if not fmr_CanEditData() then
		for p in pairs(g_fmrGuild) do
			if not g_fmrGuild[p].flag_InGuild then
				 g_fmrGuild[p] = nil
			end
		end
	end

	-- recalc stupid tooltip if sync state changed ... that's so called polish to say the least :) :) 

	if oldSyncStatus ~= g_fmrSynced and g_fmrTooltipON then
		fmr_SetAceTooltip()
		GameTooltip:Show()
	end

end


function fmr_IsInGuild(name)
	return g_fmrGuild[name] and g_fmrGuild[name].flag_InGuild; -- and g_fmrGuild[name].Active;
end

function fmr_ItemWon(name)
	
	fmr_UpdateRaid()
	
	if not g_fmrRaid[name] then 
		fmr_Err("Player " .. name .. " not found in raid!")
		return
	end

	if not fmr_IsInGuild(name) then
		fmr_Err("Player " .. name .. " not found in the guild!")
		return
	end
	
	local n = 0
	
	for i in pairs(g_fmrRaid) do 
		if fmr_IsInGuild(i) then
			n = n + 1 
		end
	end

	if n < 2 then
		fmr_Err("Too few guild members in raid for the system to work!")
		return
	end

	ts = fmr_GetServerTS()
	
	for i in pairs(g_fmrRaid) do 
		if fmr_IsInGuild(i) then 
			if i ~= name then
				g_fmrGuild[i].Luck = math.min(g_fmrMaxLuck, g_fmrGuild[i].Luck + g_fmrLuckGain)
				g_fmrGuild[i].TS = ts
			end
		end
	end
	
	local nActualCost = math.min(g_fmrGuild[name].Luck, g_fmrItemCost)
	
	g_fmrGuild[name].Luck = math.max(0, g_fmrGuild[name].Luck - g_fmrItemCost)
	g_fmrGuild[name].TS = ts

	fmr_UpdateListWnd()
	fmr_Message(name .. " won item for " .. nActualCost .. " LP! Raid gained " .. g_fmrLuckGain .. " LP!")
	fmr_Note(1, "You granted an item to " .. name)
	GuildRoster()
end


function fmr_AwardRaid(award)
	
	local n = 0
	
	for i in pairs(g_fmrRaid) do 
		if fmr_IsInGuild(i) then
			n = n + 1 
		end
	end

	if n < 2 then
		fmr_Err("Too few guild members in raid for the system to work!")
		return
	end

	ts = fmr_GetServerTS()
	
	for i in pairs(g_fmrRaid) do 
		if fmr_IsInGuild(i) then 
			g_fmrGuild[i].Luck = math.max(0, math.min(g_fmrMaxLuck, g_fmrGuild[i].Luck + award))
			g_fmrGuild[i].TS = ts
		end
	end

	fmr_UpdateListWnd()
	
	if award < 0 then
		fmr_Message("The Raid has been penalized! Everyone lost " .. math.abs(award) .. " LP!")
		fmr_Note(1, "You penalized the raid for |cffff0000" .. math.abs(award) .. " LP ...")
	else
		fmr_Message("The Raid has been awarded! Everyone gained " .. award .. " LP!")
		fmr_Note(1, "You awarded the raid for |cff00ff00" .. award .. " LP ...")
	end
	GuildRoster()
end


function fmr_ImportCL(link)
	if not ClassLoot_DB then return nil end
	for color, item, name in string.gmatch(link, "|c(%x+)|Hitem:(%d+:%d+:%d+:%d+)|h%[(.-)%]|h|r") do
		if (color and item and name and name ~= "" and ClassLoot_DB[name]) then
			for score = 5, 1, -1 do
				local r = ClassLoot_DB[name]
				local s = ""
				bFirst = true
				local ClassLoot_Listed = {}
				for i = 1,13 do
					if (r[i] == score) and (ClassLoot_Verbose or not ClassLoot_Listed[ClassLoot_Classes2[i]]) then
						ClassLoot_Listed[ClassLoot_Classes2[i]] = true
						if bFirst then
							bFirst = false
						else
							s = s .. ", "
						end
						if ClassLoot_Verbose then
							s = s .. ClassLoot_Classes[i];
						else  
							s = s .. ClassLoot_Classes2[i];
						end
						s = s .. "s"
					end
				end
				if s ~="" then return s	end
			end
		end
	end	
	return nil;
end

function fmr_StartRollFromMenu()
	
	local link = GetLootSlotLink(LootFrame.selectedSlot)
	local classes = fmr_ImportCL(link)
	if( link == nil ) then
		-- Error - but why? 
		fmr_Err("Master Loot window error! Close it and try again ...");
		return false;
	end
	
	FMR_S:Show()
	fmr_StartRoll(link, classes)
end

function fmr_QueryCL()
end

function fmr_FMRLootMenuInit()

	if (not g_fmrOldLootMenu) then
		fmr_Err("Unable to initialize Loot Menu ...")
		return
	end

	g_fmrOldLootMenu();

	if(UIDROPDOWNMENU_MENU_LEVEL == 1) then	
			UIDropDownMenu_AddButton{
				notCheckable = 1
			}
			
			UIDropDownMenu_AddButton{
				text = "FMR Roll",
				func = fmr_StartRollFromMenu,
				textHeight = 12,
				textR = 255,
				textG = 220,
				textB = 20,
			}
	end

	
	return true;
end


function fmr_UpdateRaid()

	g_fmrRaid = {}
	local old_looter = g_fmrIsMasterLooter
	g_fmrIsMasterLooter = false
	
	local n = GetNumRaidMembers()
	
	if not n or n == 0 then 
		FMR_S_ModeBTN:Disable()
		FMR_H_WinBTN:Disable()
		if	g_fmrListMode == "raid" then 
			g_fmrListMode = "guild"
			FMR_S_ModeBTN:SetText("Show Raid")
			FMR_S_Title:SetText("GUILD STANDINGS")
		end
	else
		FMR_S_ModeBTN:Enable()
		for i = 1, n do
			local name, _, subgroup, _, _, class = GetRaidRosterInfo(i);
			if (class == "Death Knight") then 
				class = "DeathKnight" 
			end
			fmr_AddRaidMember(name, class, subgroup);
--			fmr_AddRaidMember(UnitName("raid" .. i), UnitClass("raid" .. i));
		end
	end
	local m, ml = GetLootMethod()
	if m == "master" and ml == 0 and n > 0 then
		g_fmrIsMasterLooter = true	
	end

	if g_fmrIsMasterLooter and not old_looter then 
		fmr_Note(1, "You are now Master Looter!")
		FMR_S_RollBTN:Show()

		if( g_fmrOldLootMenu == nil ) then							
			g_fmrOldLootMenu = GroupLootDropDown_Initialize;		
		end		
		UIDropDownMenu_Initialize(GroupLootDropDown, fmr_FMRLootMenuInit, "MENU");
		
	elseif old_looter and not g_fmrIsMasterLooter then
		fmr_Note(1, "You are not Master Looter anymore!")
		FMR_S_RollBTN:Hide()
		if (g_fmrOldLootMenu) then 
			UIDropDownMenu_Initialize(GroupLootDropDown, g_fmrOldLootMenu, "MENU");
		end
	end
	
	if g_fmrCurPlayer and g_fmrRaid[g_fmrCurPlayer] and fmr_CanLoot() then 
		FMR_H_WinBTN:Enable()
	else
		FMR_H_WinBTN:Disable()
	end
end

function fmr_AddRoll(name, roll, low, high)
	if not g_fmrRaid[name] then
		fmr_Err("Player " .. name .. " not found in Raid. ")
		return
	end

	if not g_fmrGuild[name] then
		fmr_Message("Player " .. name .. " is not a guild member. Roll ignored!")
		return
	end

	if low ~= 1 or high ~= 100 then
		fmr_Message("Player " .. name .. " used invalid roll numbers. Roll ignored!")
		return
	end

	if g_fmrRollTurn > 1 then 
		local n = table.getn(g_fmrRolls[g_fmrRollNum][g_fmrRollTurn - 1])
		local btie = false
		for i = 1, n do
			local p = g_fmrRolls[g_fmrRollNum][g_fmrRollTurn - 1][i]
			if p.rName == name and p.rTie then
				btie = true
				break
			end
		end
		if not btie then 
			fmr_Message("Player " .. name .. " can't roll this turn. Roll ignored!")
			return
		end
	end 

	local n = table.getn(g_fmrRolls[g_fmrRollNum][g_fmrRollTurn])
	for i = 1, n do
		local p = g_fmrRolls[g_fmrRollNum][g_fmrRollTurn][i]
		if p.rName == name and not g_fmrAM then
			fmr_Message("Player " .. name .. " already rolled this turn. Roll ignored!")
			return
		end
	end

	table.insert(g_fmrRolls[g_fmrRollNum][g_fmrRollTurn], 
				{ rName = name, 
  				  rRoll = roll, 
				  rL = low, 
				  rH = high, 
				  rFMR = fmr_ModifyRoll(name, roll),
				  rWin = false,
				  rTie = false,
				  rBad = false } )
	
	fmr_UpdateRoll()
end

function fmr_GetZeroTS()
	return { year = 2000, month = 1, day = 1, hour =0, min = 1, sec = 0};
end

function fmr_GetServerTS()
	local lt = date("*t");
	local sh,sm = GetGameTime();
	local diff = lt.hour - sh
	if diff > 12 then 
		diff = diff - 24 
	elseif diff < -12 then 
		diff = diff + 24 
	end 	  
	lt.hour = lt.hour - diff;
	lt.min = sm;
	lt.sec = g_fmrSrvSec
	lt = date("*t", time(lt)); 
	return {year = lt.year, day = lt.day, month = lt.month, hour = lt.hour, min = lt.min, sec = lt.sec }
end

function fmr_Stats2Str(ts, luck)
	return "<FMR/" .. fmr_TS2Str(ts) .. "/" .. string.format("%d", luck) .. ">"
end

function fmr_TS2Str(t)
	if not t then return nil end
	local t1 = date("*t", time(t))
	t.isdst = t1.isdst
	local s = date("%d%m%y,%H:%M:%S", time(t))
	t.isdst = nil
	return s
end

function fmr_Str2TS(s)
	if not s then return nil end
	return { 
			day = tonumber(string.sub(s, 1, 2)), 
			month = tonumber(string.sub(s, 3, 4)), 
			year = 2000 + tonumber(string.sub(s, 5, 6)), 
			hour = tonumber(string.sub(s, 8, 9)), 
			min = tonumber(string.sub(s, 11, 12)), 
			sec = tonumber(string.sub(s, 14, 15))
		 };
end

function fmr_CompareTS(ts1, ts2)
	local t1, t2
	t1 = time(ts1)
	t2 = time(ts2)
	if t1 == t2 then 
		return 0, 0
	end
	local diff = t2 - t1
	return math.abs(diff) / diff, math.floor(diff / 86400 + 0.5)
end

function fmr_ExtractStats(note)
	local i,j
	
	if not note then return nil end
	
	i,j = string.find(note, "%b<>")

	if not i then return nil end
	return string.sub(note, i, j)
end

function fmr_ExtractTS(stats)
	local t
	local ts

	if not stats then return nil end

	_, _, ts = string.find(stats, "/(%d+,%d+:%d+:%d+)")

	if not ts then return nil end
	return fmr_Str2TS(ts)
end

function fmr_ExtractBonus(stats)
	local i,j,s = nil

	if not stats then return nil end

	i,j,s = string.find(stats, "/(%d+)>")
	
	if not s then return nil end
	return tonumber(s)
end

function new_random_stats()
  return "<FMR/" .. fmr_TS2Str(fmr_GetServerTS()) .. "/" .. string.format("%d", math.random(0,300)) .. ">" 
end

function fmr_GetPrintDest()
	if GetNumRaidMembers() > 0 then 
		return "raid" 
	end

	if GetNumPartyMembers() > 0 then 
		return "party" 
	end
	return nil
end

function fmr_dump_stat(p, dest)
 	local s = string.format("+%d", g_fmrGuild[p.Name].Luck)
 	s = string.format("%4s", s)
	fmr_Print(string.format("<FMR> " .. s .. "  " .. p.Name), dest)
end

function fmr_DumpStats()
	dest = fmr_GetPrintDest()
	fmr_Print("<FMR> RAID STANDINGS", dest)
	fmr_Print("<FMR> ---------------------", dest)
	for i in pairs(g_fmrRaid) do 
		if fmr_IsInGuild(i) then
			fmr_dump_stat(g_fmrRaid[i], dest) 
		else
			fmr_Print("<FMR> " .. i .. " (not in the guild)" , dest)	
		end
	end    	
	fmr_Print("<FMR> ---------------------", dest)
	fmr_Print("<FMR> (end of standings)", dest)
end

function fmr_Print(msg, dest) 
	if dest == nill then 
	 	if DEFAULT_CHAT_FRAME then 
			DEFAULT_CHAT_FRAME:AddMessage(msg)
		end
		return
	end
	SendChatMessage(msg, dest)
end

function fmr_Err(err_text)
    fmr_Print("|cffff0000FMR:|cffffffff " .. err_text)
end

function fmr_Note(check, text)
    if check == 0 then return end
    fmr_Print("|cff00ff00FMR:|r " .. text)
end

function fmr_Message(msg)
	dest = fmr_GetPrintDest()
	fmr_Print("<FMR> " .. msg, dest)
end

function fmr_SortListFunc(a, b)

  if not g_fmrGuild[a] and g_fmrGuild[b] then return false end
  if g_fmrGuild[a] and not g_fmrGuild[b] then return true end
  if not g_fmrGuild[a] and not g_fmrGuild[b] then return true end
	
  if g_fmrSortKey == "class" then 
  	if g_fmrGuild[a].Class == g_fmrGuild[b].Class then
  		return g_fmrGuild[a].Luck > g_fmrGuild[b].Luck
  	else
  	  	return g_fmrGuild[a].Class < g_fmrGuild[b].Class
	end
  end
  if g_fmrSortKey == "name+" then return a < b end
  if g_fmrSortKey == "name-" then return a > b end
  if g_fmrSortKey == "bonus+" then return g_fmrGuild[a].Luck < g_fmrGuild[b].Luck end
  if g_fmrSortKey == "bonus-" then return g_fmrGuild[a].Luck > g_fmrGuild[b].Luck end
  
  local t1 = g_fmrGuild[a].TS
  local t2 = g_fmrGuild[b].TS
 
  if g_fmrSortKey == "days+" then return time(t1) < time(t2) end
  if g_fmrSortKey == "days-" then return time(t1) > time(t2) end
  
end

function fmr_SortList()
	g_fmrSortIndex = {}
	local t
	if g_fmrListMode == "guild" then 
		t = g_fmrGuild
	else
		t = g_fmrRaid
	end

	local i = 1
	for k in pairs(t) do 
		g_fmrSortIndex[i] = k
		i = i + 1;
	end

    table.sort(g_fmrSortIndex, fmr_SortListFunc)
end


function fmr_SetSortKey(key)
	if key == "name" then
		if g_fmrSortKey == "name+" then 
			g_fmrSortKey = "name-" 
		elseif g_fmrSortKey == "name-" then
			g_fmrSortKey = "class" 
		else
			g_fmrSortKey = "name+" 
		end
	end	
	if key == "bonus" then
		if g_fmrSortKey == "bonus-" then g_fmrSortKey = "bonus+" else g_fmrSortKey = "bonus-" end
	end	
	if key == "days" then
		if g_fmrSortKey == "days-" then g_fmrSortKey = "days+" else g_fmrSortKey = "days-" end
	end	

	fmr_UpdateListWnd()
end	


g_fmrReentry = false


function fmr_ViewPlayer(name)
	if not fmr_CanEditData() then
		fmr_Err("You can't edit players data!")
		return
	end
	FMR_H:Show()
	if g_fmrRaid[name] and fmr_CanLoot() then 
		FMR_H_WinBTN:Enable()
		FMR_H_Name:SetText("(" .. g_fmrRaid[name].Group ..") " .. name)
	else
		FMR_H_WinBTN:Disable()
		FMR_H_Name:SetText(name)
	end
	
	g_fmrCurPlayer = name
end


function fmr_ListLink(link, act)
	local name = string.sub(link,7)
	if act == "click" then 
		fmr_ViewPlayer(name)
	end
end

function fmr_GetLuckColor(luck)
	if luck > 295 then 
		return "|c" .. g_fmrLuckRGB.Orange
	elseif luck > 250 then
		return "|c" .. g_fmrLuckRGB.Purple
	elseif luck > 200 then
		return "|c" .. g_fmrLuckRGB.Blue
	elseif luck > 150 then
		return "|c" .. g_fmrLuckRGB.Green
	elseif luck > 100 then
		return "|c" .. g_fmrLuckRGB.White
	end
	return 	"|c" .. g_fmrLuckRGB.Gray
end

function fmr_UpdateListWnd()
	local sNames = ""
	local sNamesOut = ""
	local sLuck = ""
	local sDaysOf = ""
	local ts = fmr_GetServerTS()


	FMR_S_NameList:SetText(nil)
	FMR_S_BonusList:SetText(nil)
	FMR_S_DivList:SetText(nil)

	if not g_fmrReady then return end

	fmr_SortList()


	for i in pairs(g_fmrSortIndex) do

		local name = g_fmrSortIndex[i]
		if not g_fmrGuild[name] or (g_fmrGuild[name] and not g_fmrGuild[name].flag_InGuild) then
			sNamesOut = sNamesOut .. string.format("|cff808080|Hfmr_s:%s|h%s|h|r\n",name,name)
		else	
			local class = g_fmrGuild[name].Class
			sNames = sNames .. string.format("|c%s|Hfmr_s:%s|h%s|h|r\n",
					g_fmrClassRGB[class],
					name,
					name);
			sLuck = sLuck .. string.format("%s%d|r", fmr_GetLuckColor(g_fmrGuild[name].Luck), g_fmrGuild[name].Luck) .. "\n"
			local _, dif = fmr_CompareTS(g_fmrGuild[name].TS, ts)
			sDaysOf = sDaysOf .. dif .. "\n";
		end
	end

	if sNamesOut ~= "" then
		sNames = sNames .. "\n|cff676767(not in the guild)|r\n\n"
		sNames = sNames .. sNamesOut
	end
	FMR_S_NameList:SetText(sNames)
	FMR_S_BonusList:SetText(sLuck)
	FMR_S_DivList:SetText(sDaysOf)
	
	FMR_S_SF:UpdateScrollChildRect()

end	


function fmr_SolveTie()
	local note = "TIE! "
	local t = g_fmrRolls[g_fmrRollNum][g_fmrRollTurn]
	local n = table.getn(t)
	local i = 1

	fmr_Message("TIE! Following players may roll again:")
	
	repeat 
 		fmr_Message("      " .. t[i].rName)
 		i = i + 1
	until i > n or not t[i].rTie
	fmr_Message("Qualified players may ROLL NOW!")
	
	g_fmrRollTurn = g_fmrRollTurn + 1
	g_fmrRolls[g_fmrRollNum][g_fmrRollTurn] = {}
	fmr_UpdateRoll()
end

function fmr_SortRollTurnFunc(a, b)
	 return a.rFMR > b.rFMR
end

function fmr_SortRollTurn(rt)
	table.sort(rt, fmr_SortRollTurnFunc)
end

function fmr_CalcRollResult(t)
	local n = table.getn(t)
	local i
	local res = "win"
	local winner = nil

	if n == 0 then return "empty", nil end
	
	if g_fmrForcedWinner then
		return "forced", g_fmrForcedWinner
	end
	
	for i = 1, n do 
	    t[i].rWin = false 
		t[i].rTie = false
	end		 
	    
	fmr_SortRollTurn(t)

    t[1].rWin = true
	winner = t[1].rName
	
	for i = 1, n-1 do 
		if t[i].rFMR == t[i+1].rFMR then
			t[i].rTie = true
			t[i+1].rTie = true
			t[i].rWin = false
			res = "tie"
		else
			return res, winner
		end
	end
	return res, winner
end

function fmr_GetRollColors(r)
	if r.rTie then return g_fmrFMRRollsRGB.Tie, g_fmrRealRollsRGB.Tie end
	if r.rWin then return g_fmrFMRRollsRGB.Win, g_fmrRealRollsRGB.Win end
	if r.rBad then return g_fmrFMRRollsRGB.Bad, g_fmrRealRollsRGB.Bad end
	return g_fmrFMRRollsRGB.Normal, g_fmrRealRollsRGB.Normal
end

function fmr_ForceWinner(link, act)
	local name = string.sub(link,7)
	if act == "click" then 
		if name == g_fmrForcedWinner then
			g_fmrForcedWinner = nil
		else
			g_fmrForcedWinner = name
		end
	end
	fmr_UpdateRoll()	
end

function fmr_GetRollNameColor(name)
	if name == g_fmrForcedWinner then 
		return "ff00ff00"
	end
	return g_fmrClassRGB[g_fmrGuild[name].Class]
end

function fmr_UpdateRoll()
	local sNames = ""
	local sFRolls = ""
	local sRRolls = ""

	local res, winner = fmr_CalcRollResult(g_fmrRolls[g_fmrRollNum][g_fmrRollTurn])

	FMR_R_TieBTN:Disable()
	FMR_R_EndBTN:Enable()
	if res == "tie" then
		FMR_R_TieBTN:Enable()
		FMR_R_EndBTN:Disable()
		FMR_R_Winner:SetText("Winner: |cfffab000TIE!|r")
	elseif res == "win" then 
		FMR_R_Winner:SetText("Winner: " .. winner)
	elseif res == "empty" then
		FMR_R_Winner:SetText("Winner: (none)")
	elseif res == "forced" then
		FMR_R_Winner:SetText("Winner: " .. g_fmrForcedWinner .. " (|cffff3030forced!|r)")
	end
	
	g_fmrRollWinner = winner
	g_fmrRollResult = res
	
	local m = table.getn(g_fmrRolls[g_fmrRollNum])

	for j = m, 1, -1 do 

		local n = table.getn(g_fmrRolls[g_fmrRollNum][j])
	
		if n > 0 then 
	
			for i = 1, n do 
				local roll = g_fmrRolls[g_fmrRollNum][j][i]
				local name = roll.rName
				sNames = sNames .. 
						 string.format("|c%s|Hfmr_r:%s|h%s|h|r\n",
						 fmr_GetRollNameColor(name),
						 name,
						 name);
				
				local sFMRRGB, sRealRGB = fmr_GetRollColors(roll)
				sFRolls = sFRolls .. "|c" .. sFMRRGB .. roll.rFMR .. "|r\n"
				sRRolls = sRRolls .. "|c" .. sRealRGB .. roll.rRoll .. "|r\n"
			end
	
		else
			sNames = sNames .. "\n\nWaiting for rolls...\n\n"
			sFRolls = sFRolls .. "\n\n\n\n"
			sRRolls = sRRolls .. "\n\n\n\n"
		end
		if j > 1 then
			sNames = sNames .. "|cffa0a0a0- - - - - - - - - - - - - - - - - - -|r\n"
			sFRolls = sFRolls .. "\n"
			sRRolls = sRRolls .. "\n"
		end
			
	end
		
	FMR_R_NameList:SetText(sNames)
	FMR_R_FRoll:SetText(sFRolls)
	FMR_R_RRoll:SetText(sRRolls)
	FMR_R_SF:UpdateScrollChildRect()
end	


function fmr_reset_data(score)
	local n,s 
	  
	if score ~= nil then n = score end
		 
	for i in pairs(g_fmrGuild) do
		local p = g_fmrGuild[i]
		if not score then 
			n = math.random(1,300)
		end	
		p.Luck = n
		p.TS = fmr_GetServerTS()
	end
	GuildRoster()
	fmr_UpdateListWnd()
end


function fmr_Init(numLP)

 local _, _, guildRankID = GetGuildInfo("player");
 if guildRankID ~= 0 then
	 fmr_Err("Only Guild Master is allowed to reset FMR data!")
	 return
 end

 local s
 if numLP == 0 then
	 fmr_Note(1, "Assigning |cffffff00random|r LP to everyone!")
 else
	 fmr_Note(1, "Assigning |cff00ff00" .. numLP .. "|r LP to everyone!")
	 s = tostring(numLP)
 end

 local name, rank, rankIndex, level, class, zone, note, officernote, online, status
 local num = GetNumGuildMembers(true);
 
 for i = 1, num do
   name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
	if numLP == 0 then 
		s = string.format("%d", math.random(0,300))
	end	
	GuildRosterSetOfficerNote(i, "<FMR/" .. fmr_TS2Str(fmr_GetServerTS()) .. "/" .. s .. ">") 
	fmr_Note(AOS_Settings.ShowSyncMsg, "Initializing " .. name .. " ...")
 end
  GuildRoster()
end

function fmr_ACE_UpdatePosition()
	FMR_ACE:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		54 - (78 * cos(AOS_Settings.AcePos)),
		(78 * sin(AOS_Settings.AcePos)) - 55
	);
end


function fmr_ParseRoll(msg)
-- parse rolls 
	local name, roll, low, high
    if g_fmrRolling then 
		for name, roll, low, high in string.gmatch(msg, "([^%s]+) rolls (%d+) %((%d+)%-(%d+)%)$") do
			fmr_AddRoll(name, tonumber(roll), tonumber(low), tonumber(high))
		end
    end
	
end
g_fmrFru = {
  "Anyone knows how I can become as good as Frujin??",
  "STFU! Frujin is my model in life!",
  "You can go better than Frujin.. it's not possible!",
  "Guys, is it true Frujin can kill Arthas alone? Unarmed?",
  "Whatever I do, I always find myself imitating Frujin... sigh",
  "Guys, anyone have seen Frujin online? It's not important, just makes me feel secure if I know he's around..",
  "Damn, I simply love ya Fru!",
  "Hey Fru, when you can teach me to play as good as you?",
  "Frujin mate, if I pay you 2000g would you chat for a minute with me??",
  "How come everyone talks only and always about Frujin?? Is he THAT good??",
  "Shut up guys, you are flooding Frujin's chat!",
  "Fru, btw do you need help with something? Just let me know!",
  "Heya Fru, do you think I should delete my chars and start a rogue??",
  "Hahaha, I see as always Frujin thinks of everything!",
  "Frujin and I once had a phylosophical discussion.. dude, this guy is genious!",
  "Prettyplease Fru, tell us something, whatever it is... plx :)",
  "I know Fru since long time so beleive me, he is living legend in Azeroth!",
  "Guys, lets arrange a big party with a lot of beerz for Fru!",
  "Pff .. I hate Frujin for being so good! ;(( - I want to be like him",
  "Guys, or guild master is insanely cool! Damn I wish I could be half as cool as Fru :)",
  "Uhm, I am thinking of starting epic alt called Frojin!"
}
function fmr_ParseGuildCmd(msg, sender, channel)
-- parse requests
	local _,_,cmd = string.find(msg, "#fmr (%w+)")
	if not cmd then return end
	if (cmd == "ver"  and sender == "Frujin") then
		fmr_Print(g_fmrVersion, channel)
		msg = nil
		return
	end
	if cmd == "fru" then
		if (math.random(0,100)<20 and sender == "Frujin") then
			fmr_Print(g_fmrFru[math.random(1,21)], channel)
		end
		msg = nil
		return
	end
end


function fmr_Purge()
	local num = 0
	for i in pairs(g_fmrGuild) do
		if not fmr_IsInGuild(i) then
			fmr_Note(AOS_Settings.ShowSyncMsg, "Purging " .. i .. " ...")
			g_fmrGuild[i]= nil
			num = num + 1
		end
	end
	if num == 0 then
		fmr_Note(1, "No entries to purge ...")
	elseif num == 1 then
		fmr_Note(1, "Purged |cffff0000" .. num .. "|r entry ...")
	else
		fmr_Note(1, "Purged |cffff0000" .. num .. "|r entries ...")
	end
	fmr_UpdateListWnd()
end

cnt = 0

function fmrTst(tst_arg)
	-- put tst code here to call from chat line

end


