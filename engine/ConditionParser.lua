--========================================================--
-- SkillWeaver - Condition Parser (Enhanced Boolean Logic)
--========================================================--

local ADDON_NAME, SkillWeaver = ...
local Parser = {}
SkillWeaver.Engine.ConditionParser = Parser

local SAFE      = function() return SkillWeaver.SafeMode end
local RESTRICT  = function() return SkillWeaver.Restricted end
local FULL      = function() return SkillWeaver.FullEngine end

local UnitPower      = UnitPower
local UnitPowerMax   = UnitPowerMax
local UnitHealth     = UnitHealth
local UnitHealthMax  = UnitHealthMax
local UnitExists     = UnitExists
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime
local UnitAffectingCombat = UnitAffectingCombat
local GetUnitSpeed = GetUnitSpeed

------------------------------------------------------------
-- Utility: Trim whitespace
------------------------------------------------------------
local function trim(s)
    return s and s:gsub("^%s*(.-)%s*$", "%1") or s
end

------------------------------------------------------------
-- Token Resolver (Values)
------------------------------------------------------------
function Parser.ResolveToken(token)
    token = trim(token)
    if not token then return nil end

    -- Boolean literals
    if token == "true" then return true end
    if token == "false" then return false end

    -- Numeric literal
    local num = tonumber(token)
    if num then return num end

    --------------------------------------------------------
    -- Resources
    --------------------------------------------------------
    if token == "focus"      then return UnitPower("player", 2) end
    if token == "energy"     then return UnitPower("player", 3) end
    if token == "rage"       then return UnitPower("player", 1) end
    if token == "runicpower" then return UnitPower("player", 5) end
    if token == "mana"       then return UnitPower("player", 0) end
    if token == "insanity"   then return UnitPower("player", 13) end
    if token == "maelstrom"  then return UnitPower("player", 11) end
    if token == "holypower"  then return UnitPower("player", 9) end
    if token == "chi"        then return UnitPower("player", 4) end
    if token == "combo" or token == "combo_points" then
        return UnitPower("player", Enum.PowerType.ComboPoints)
    end

    --------------------------------------------------------
    -- Movement
    --------------------------------------------------------
    if token == "moving" then
        local speed = GetUnitSpeed("player")
        return (speed > 0) and 1 or 0
    end

    --------------------------------------------------------
    -- Combat state
    --------------------------------------------------------
    if token == "in_combat" then
        return UnitAffectingCombat("player") and 1 or 0
    end
    if token == "not_in_combat" then
        return UnitAffectingCombat("player") and 0 or 1
    end

    --------------------------------------------------------
    -- Target health percent
    --------------------------------------------------------
    if token == "target:health" then
        if not UnitExists("target") then return 0 end
        local h = UnitHealth("target")
        local m = UnitHealthMax("target")
        if m == 0 then return 0 end
        return (h / m) * 100
    end

    --------------------------------------------------------
    -- Player health percent
    --------------------------------------------------------
    if token == "health" or token == "player:health" then
        local h = UnitHealth("player")
        local m = UnitHealthMax("player")
        if m == 0 then return 0 end
        return (h / m) * 100
    end

    --------------------------------------------------------
    -- Buff / Debuff
    --------------------------------------------------------
    if token:find("buff:") == 1 then
        local buff = token:sub(6)
        if AuraUtil and AuraUtil.FindAuraByName then
            return AuraUtil.FindAuraByName(buff, "player") and 1 or 0
        end
        return 0
    end

    if token:find("debuff:") == 1 then
        local dbuff = token:sub(8)
        if AuraUtil and AuraUtil.FindAuraByName then
            return AuraUtil.FindAuraByName(dbuff, "target") and 1 or 0
        end
        return 0
    end
    
    -- Heroism/Bloodlust detection
    if token == "heroism" or token == "bloodlust" then
        -- Check for any lust buff (Heroism, Bloodlust, Time Warp, etc.)
        local lustBuffs = {
            "Heroism", "Bloodlust", "Time Warp", "Ancient Hysteria", 
            "Primal Rage", "Drums of Rage", "Feral Hide Drums"
        }
        for _, buffName in ipairs(lustBuffs) do
            if UnitBuff("player", buffName) then
                return 1
            end
        end
        return 0
    end
    
    -- Talent detection: talent(SpellName)
    if token:find("talent%(") == 1 then
        local talentName = token:match("talent%((.+)%)")
        if talentName and SkillWeaver.TalentDetector then
            return SkillWeaver.TalentDetector:HasTalent(talentName) and 1 or 0
        end
        return 0
    end

    --------------------------------------------------------
    -- Cooldown: cooldown:SpellName
    --------------------------------------------------------
    if token:find("cooldown:") == 1 then
        local spell = token:sub(10)
        local start, dur = GetSpellCooldown(spell)
        if not start then return 0 end
        local remain = (start + dur) - GetTime()
        return remain > 0 and remain or 0
    end
    
    --------------------------------------------------------
    -- Interrupt Check: should_interrupt
    --------------------------------------------------------
    if token == "should_interrupt" then
        if not UnitExists("target") or not UnitCanAttack("player", "target") then
            return 0
        end
        
        local name, _, _, _, _, endTime, _, _, interruptible = UnitCastingInfo("target")
        if not name then
            name, _, _, _, _, endTime, _, interruptible = UnitChannelInfo("target")
        end
        
        if not name or not interruptible then
            return 0
        end
        
        -- Check if this spell is in our interrupt database
        local zone = GetInstanceInfo() or GetZoneText()
        local targetName = UnitName("target")
        
        if SkillWeaver.Interrupts and SkillWeaver.Interrupts[zone] then
            local mobData = SkillWeaver.Interrupts[zone][targetName]
            if mobData then
                -- Check priority first
                if mobData.priority then
                    for _, spell in ipairs(mobData.priority) do
                        if name:find(spell) then
                            return 1 -- Must kick
                        end
                    end
                end
                -- Check optional
                if mobData.optional then
                    for _, spell in ipairs(mobData.optional) do
                        if name:find(spell) then
                            return 1 -- Kick if available
                        end
                    end
                end
            end
        end
        
        -- Fallback: kick anything interruptible if not in database
        return 1
    end
    
    --------------------------------------------------------
    -- Enemy Count: enemies
    --------------------------------------------------------
    if token == "enemies" then
        -- Count nearby enemies in combat with player
        local count = 0
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
                -- Check if they're close enough (< 10 yards for most AOE)
                if CheckInteractDistance(unit, 3) then  -- 3 = 10 yards
                    count = count + 1
                end
            end
        end
        return count
    end
    
    --------------------------------------------------------
    -- Healing Tokens
    --------------------------------------------------------
    
    -- allies_below_health:X - Count allies below X% health
    if token:find("allies_below_health:") == 1 then
        local threshold = tonumber(token:sub(21))
        if not threshold then return 0 end
        
        local count = 0
        if IsInRaid() then
            for i = 1, 40 do
                local unit = "raid" .. i
                if UnitExists(unit) and not UnitIsDead(unit) then
                    local hp = UnitHealth(unit)
                    local maxHp = UnitHealthMax(unit)
                    if maxHp > 0 and (hp / maxHp * 100) < threshold then
                        count = count + 1
                    end
                end
            end
        elseif IsInGroup() then
            for i = 1, 4 do
                local unit = "party" .. i
                if UnitExists(unit) and not UnitIsDead(unit) then
                    local hp = UnitHealth(unit)
                    local maxHp = UnitHealthMax(unit)
                    if maxHp > 0 and (hp / maxHp * 100) < threshold then
                        count = count + 1
                    end
                end
            end
        end
        
        -- Include player
        local playerHp = UnitHealth("player")
        local playerMaxHp = UnitHealthMax("player")
        if playerMaxHp > 0 and (playerHp / playerMaxHp * 100) < threshold then
            count = count + 1
        end
        
        return count
    end
    
    -- lowest_ally_health - Health % of lowest health ally
    if token == "lowest_ally_health" then
        if SkillWeaver.HealingHelper then
            local _, percent = SkillWeaver.HealingHelper:GetLowestHealthAlly()
            return percent or 100
        end
        return 100
    end
    
    -- needs_dispel - Target has dispellable debuff
    if token == "needs_dispel" then
        if not UnitExists("target") or not UnitIsFriend("player", "target") then
            return 0
        end
        
        -- Check for Magic debuffs (Priest can dispel Magic)
        for i = 1, 40 do
            local name, _, _, debuffType = UnitDebuff("target", i)
            if not name then break end
            if debuffType == "Magic" or debuffType == "Disease" then
                return 1
            end
        end
        return 0
    end
    
    -- target_health - Target's health %
    if token == "target_health" then
        if not UnitExists("target") then return 100 end
        local hp = UnitHealth("target")
        local maxHp = UnitHealthMax("target")
        if maxHp > 0 then
            return (hp / maxHp) * 100
        end
        return 100
    end

    return nil
end

------------------------------------------------------------
-- Boolean Logic Parser
------------------------------------------------------------

-- Helper to evaluate a simple comparison (A > B) or single value
local function EvaluateSimple(expr)
    expr = trim(expr)
    if not expr or expr == "" then return true end

    -- Check for comparison operators
    local left, op, right = expr:match("([^><=~]+)([><=~]+)(.+)")
    
    if left and op and right then
        local lVal = Parser.ResolveToken(trim(left))
        local rVal = Parser.ResolveToken(trim(right))
        
        if lVal == nil or rVal == nil then return false end
        
        if op == ">"  then return lVal > rVal end
        if op == "<"  then return lVal < rVal end
        if op == ">=" then return lVal >= rVal end
        if op == "<=" then return lVal <= rVal end
        if op == "==" then return lVal == rVal end
        if op == "~=" then return lVal ~= rVal end
    else
        -- Single boolean value or check (e.g. "true", "buff:X")
        local val = Parser.ResolveToken(expr)
        if val == true then return true end
        if val == false then return false end
        if type(val) == "number" then return val ~= 0 end
        return false
    end
    return false
end

-- Split by OR, then AND
local function EvaluateBoolean(cond)
    if not cond or cond == "" then return true end
    
    -- Handle Parentheses recursively
    -- Find innermost parens
    while cond:find("%b()") do
        local inner = cond:match("%(([^()]+)%)")
        local result = EvaluateBoolean(inner)
        -- Replace (inner) with result
        cond = cond:gsub("%(" .. inner:gsub("([^%w])", "%%%1") .. "%)", tostring(result))
    end

    -- Handle OR
    if cond:find(" or ") then
        local parts = {}
        for part in cond:gmatch("[^o]+r?") do -- naive split, better to use explicit split
             -- Lua pattern matching for " or " is tricky without split function
             -- Let's do a manual split
        end
        
        -- Simple split by " or "
        local start = 1
        while true do
            local s, e = cond:find(" or ", start)
            if not s then
                if EvaluateBoolean(cond:sub(start)) then return true end
                break
            end
            local part = cond:sub(start, s-1)
            if EvaluateBoolean(part) then return true end
            start = e + 1
        end
        return false
    end

    -- Handle AND
    if cond:find(" and ") then
        local start = 1
        while true do
            local s, e = cond:find(" and ", start)
            if not s then
                if not EvaluateBoolean(cond:sub(start)) then return false end
                break
            end
            local part = cond:sub(start, s-1)
            if not EvaluateBoolean(part) then return false end
            start = e + 1
        end
        return true
    end

    -- Handle NOT
    if cond:find("not ") == 1 then
        return not EvaluateBoolean(cond:sub(5))
    end

    return EvaluateSimple(cond)
end

------------------------------------------------------------
-- Public Evaluate
------------------------------------------------------------
function Parser.Evaluate(cond)
    if SAFE() then
        -- Midnight Safe Mode: almost always true
        if cond == "false" or cond == "never" then return false end
        return true
    end

    local success, result = pcall(EvaluateBoolean, cond)
    if not success then
        -- Fallback on error
        return false 
    end
    return result
end

function SkillWeaver.Engine:CheckConditions(c)
    return Parser.Evaluate(c)
end

return Parser

    --------------------------------------------------------
    -- Resource Forecasting
    --------------------------------------------------------
    -- Predict rage in X seconds
    if token:find("rage_in%(") == 1 then
        local seconds = tonumber(token:match("rage_in%((%d+)%)"))
        if seconds then
            local current = UnitPower("player", Enum.PowerType.Rage)
            local predicted = current + (2 * seconds)  -- ~2 rage/sec
            return math.min(predicted, 100)
        end
        return 0
    end
    
    -- Predict energy in X seconds  
    if token:find("energy_in%(") == 1 then
        local seconds = tonumber(token:match("energy_in%((%d+)%)"))
        if seconds then
            local current = UnitPower("player", Enum.PowerType.Energy)
            local predicted = current + (10 * seconds)  -- 10 energy/sec
            return math.min(predicted, 100)
        end
        return 0
    end
    
    -- Resource deficit
    if token == "rage_deficit" then
        return 100 - UnitPower("player", Enum.PowerType.Rage)
    end
    
    if token == "energy_deficit" then
        return 100 - UnitPower("player", Enum.PowerType.Energy)
    end
    
    --------------------------------------------------------
    -- Combat Context
    --------------------------------------------------------
    -- Combat duration
    if token == "combat_time" then
        if SkillWeaver.CombatTracker then
            return SkillWeaver.CombatTracker:GetCombatTime()
        end
        return 0
    end
    
    -- Time to die
    if token == "time_to_die" or token == "ttd" then
        if SkillWeaver.CombatTracker then
            return SkillWeaver.CombatTracker:GetTimeToDie()
        end
        return 999
    end
    
    -- PvP talent check
    if token:find("pvptalent%(") == 1 then
        local talentName = token:match("pvptalent%((.+)%)")
        if talentName and SkillWeaver.TalentDetector then
            return SkillWeaver.TalentDetector:HasPvPTalent(talentName) and 1 or 0
        end
        return 0
    end
