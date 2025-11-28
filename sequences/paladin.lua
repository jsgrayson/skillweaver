local ADDON_NAME, SkillWeaver = ...

-- Paladin Sequences
-- Covers: Holy (65), Protection (66), Retribution (70)

local PALADIN_HOLY = "PALADIN_65"
local PALADIN_PROT = "PALADIN_66"
local PALADIN_RET  = "PALADIN_70"

-- PROTECTION (Tank)
SkillWeaver.Sequences[PALADIN_PROT] = {
    ["Raid"] = {
        ["Balanced"] = {
            type = "Priority",
            st = {
                -- Defensives (Health based, anti-stacking)
                { command = "/cast Ardent Defender", conditions = "health < 30 and buff:Guardian of Ancient Kings == 0" },
                { command = "/cast Guardian of Ancient Kings", conditions = "health < 35 and buff:Ardent Defender == 0" },
                { command = "/cast Word of Glory", conditions = "health < 50 and holypower >= 3" },
                
                -- Core Rotation
                { command = "/cast Shield of the Righteous", conditions = "holypower >= 3" },
                { command = "/cast Judgment", conditions = "true" },
                { command = "/cast Hammer of Wrath", conditions = "true" },
                { command = "/cast Avenger's Shield", conditions = "true" },
                { command = "/cast Blessed Hammer", conditions = "true" },
                { command = "/cast [@player] Consecration", conditions = "moving == 0" },
            },
            aoe = {
                { command = "/cast Ardent Defender", conditions = "health < 30" },
                { command = "/cast Word of Glory", conditions = "health < 50 and holypower >= 3" },
                { command = "/cast Avenger's Shield", conditions = "true" },
                { command = "/cast Shield of the Righteous", conditions = "holypower >= 3" },
                { command = "/cast [@player] Consecration", conditions = "true" },
                { command = "/cast Blessed Hammer", conditions = "true" },
                { command = "/cast Judgment", conditions = "true" },
            },
            steps = {}
        }
    }
}

-- RETRIBUTION (DPS)
SkillWeaver.Sequences[PALADIN_RET] = {
    ["Raid"] = {
        ["Balanced"] = { -- Default
            type = "Priority",
            st = {
                { command = "/cast Rebuke", conditions = "should_interrupt" },
                { command = "/cast Shield of Vengeance", conditions = "health < 60" },
                { command = "/cast Final Verdict", conditions = "holypower >= 3" },
                { command = "/cast Wake of Ashes", conditions = "holypower <= 2" },
                { command = "/cast Judgment", conditions = "true" },
                { command = "/cast Hammer of Wrath", conditions = "true" },
                { command = "/cast Blade of Justice", conditions = "true" },
                { command = "/cast Crusader Strike", conditions = "true" },
            },
            aoe = {
                { command = "/cast Divine Storm", conditions = "holypower >= 3" },
                { command = "/cast Wake of Ashes", conditions = "holypower <= 2" },
                { command = "/cast Judgment", conditions = "true" },
                { command = "/cast Blade of Justice", conditions = "true" },
            },
            steps = {}
        },
        ["Templar"] = { -- Single Target / Hammer of Light Focus
            type = "Priority",
            st = {
                -- Emergency Healing (Ally then Self)
                { command = "/cast [target=mouseover,help,nodead][help] Lay on Hands", conditions = "in_group and ally_health < 15 and range <= 40" },
                { command = "/cast [target=player] Lay on Hands", conditions = "health < 20" },
                { command = "/cast [target=mouseover,help,nodead][help] Word of Glory", conditions = "in_group and ally_health < 30 and holy_power >= 3 and range <= 40" },
                { command = "/cast [target=player] Word of Glory", conditions = "health < 50 and holy_power >= 3" },
                { command = "/cast [target=mouseover,help,nodead][help] Flash of Light", conditions = "in_group and ally_health < 25 and buff:Selfless Healer and range <= 40" },
                
                -- Interrupt & Cleanse
                { command = "/cast Rebuke", conditions = "should_interrupt and range <= 10" },
                { command = "/cast Hammer of Justice", conditions = "should_interrupt and cooldown:Rebuke > 0 and range <= 10" },
                { command = "/cast [target=player] Cleanse", conditions = "debuff_type == poison or debuff_type == disease or movement_impaired" },
                { command = "/cast Shield of Vengeance", conditions = "health < 50" },
                
                -- Cooldowns
                { command = "/cast Crusade", conditions = "heroism or holy_power >= 3" },
                { command = "/cast Hammer of Light", conditions = "true" }, -- Replaces Wake of Ashes when procced
                { command = "/cast Wake of Ashes", conditions = "holy_power <= 2 and range <= 12" },
                { command = "/cast Divine Toll", conditions = "holy_power <= 2" },
                
                -- Finishers
                { command = "/cast Final Verdict", conditions = "holy_power >= 3 and range <= 10" },
                
                -- Generators
                { command = "/cast Hammer of Wrath", conditions = "range <= 30" },
                { command = "/cast Blade of Justice", conditions = "range <= 12" },
                { command = "/cast Templar Slash", conditions = "range <= 8" }, -- Replaces Crusader Strike
                { command = "/cast Judgment", conditions = "range <= 30" },
            },
            aoe = {
                { command = "/cast Rebuke", conditions = "should_interrupt and range <= 10" },
                { command = "/cast Shield of Vengeance", conditions = "health < 50 or enemies_nearby >= 4" },
                { command = "/cast Hammer of Light", conditions = "true" },
                { command = "/cast Divine Storm", conditions = "holy_power >= 3 and range <= 8" },
                { command = "/cast Wake of Ashes", conditions = "holy_power <= 2 and range <= 12" },
                { command = "/cast Divine Toll", conditions = "holy_power <= 2" },
                { command = "/cast Templar Slash", conditions = "range <= 8" },
                { command = "/cast Judgment", conditions = "range <= 30" },
            },
            steps = {}
        },
        ["Herald of the Sun"] = { -- AoE / Dawnlight Focus
            type = "Priority",
            st = {
                { command = "/cast Crusade", conditions = "heroism or holypower >= 3" },
                { command = "/cast Wake of Ashes", conditions = "true" }, -- Applies Dawnlight
                { command = "/cast Divine Toll", conditions = "holypower <= 2" },
                { command = "/cast Final Verdict", conditions = "holypower >= 3" },
                { command = "/cast Hammer of Wrath", conditions = "true" },
                { command = "/cast Judgment", conditions = "true" },
                { command = "/cast Blade of Justice", conditions = "true" },
                { command = "/cast Crusader Strike", conditions = "true" },
            },
            aoe = {
                { command = "/cast Wake of Ashes", conditions = "true" },
                { command = "/cast Divine Toll", conditions = "holypower <= 2" },
                { command = "/cast Divine Storm", conditions = "holypower >= 3" }, -- Spreads Dawnlight
                { command = "/cast Judgment", conditions = "true" },
                { command = "/cast Blade of Justice", conditions = "true" },
                { command = "/cast Crusader Strike", conditions = "true" },
            },
            steps = {}
        }
    }
}

-- HOLY (Healer)
-- Controller Friendly: Falls back to [target=target] or [target=player] if no mouseover
SkillWeaver.Sequences[PALADIN_HOLY] = {
    ["Raid"] = {
        ["Balanced"] = {
            type = "Priority",
            st = {
                -- Emergency
                { command = "/cast [target=mouseover,help,nodead][help][target=player] Lay on Hands", conditions = "health < 15" },
                
                -- Spenders
                { command = "/cast [target=mouseover,help,nodead][help][target=player] Word of Glory", conditions = "holypower >= 3" },
                
                -- Generators / Core
                { command = "/cast [target=mouseover,help,nodead][help][target=player] Holy Shock", conditions = "true" },
                { command = "/cast Judgment", conditions = "true" },
                { command = "/cast Hammer of Wrath", conditions = "true" },
                { command = "/cast Crusader Strike", conditions = "true" },
                { command = "/cast [@player] Consecration", conditions = "moving == 0" },
            },
            aoe = {
                { command = "/cast [target=mouseover,help,nodead][help][target=player] Light of Dawn", conditions = "holypower >= 3" },
                { command = "/cast Holy Prism", conditions = "true" },
                { command = "/cast [target=mouseover,help,nodead][help][target=player] Holy Shock", conditions = "true" },
                { command = "/cast Judgment", conditions = "true" },
            },
            steps = {}
        }
    }
}
