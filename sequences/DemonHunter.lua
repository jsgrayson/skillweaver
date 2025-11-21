local ADDON_NAME, SkillWeaver = ...

-- Demon Hunter Sequences
-- Covers: Havoc (577), Vengeance (581)

local DH_HAVOC = "DEMONHUNTER_577"
local DH_VENGEANCE = "DEMONHUNTER_581"

SkillWeaver.Sequences[DH_HAVOC] = {
    ["Raid"] = {
        ["Balanced"] = { -- Default
            type = "Priority",
            st = {
                { command = "/cast The Hunt", conditions = "true" },
                { command = "/cast Eye Beam", conditions = "true" },
                { command = "/cast Immolation Aura", conditions = "true" },
                { command = "/cast Blade Dance", conditions = "fury >= 15" },
                { command = "/cast Chaos Strike", conditions = "fury >= 40" },
                { command = "/cast Demon's Bite", conditions = "true" },
                { command = "/cast Felblade", conditions = "true" },
                { command = "/cast Sigil of Flame", conditions = "true" },
            },
            aoe = {
                { command = "/cast The Hunt", conditions = "true" },
                { command = "/cast Eye Beam", conditions = "true" },
                { command = "/cast Immolation Aura", conditions = "true" },
                { command = "/cast Blade Dance", conditions = "true" },
                { command = "/cast Chaos Strike", conditions = "fury >= 40" },
                { command = "/cast Sigil of Flame", conditions = "true" },
            },
            steps = {}
        },
        ["Aldrachi Reaver"] = { -- Single Target / Glaive Focus
            type = "Priority",
            st = {
                { command = "/cast The Hunt", conditions = "true" },
                { command = "/cast Eye Beam", conditions = "true" },
                { command = "/cast Essence Break", conditions = "prev_gcd:Eye Beam" }, -- Combo
                { command = "/cast Blade Dance", conditions = "buff:Essence Break" }, -- Priority during EB
                { command = "/cast Chaos Strike", conditions = "buff:Essence Break" },
                { command = "/cast Reaver's Glaive", conditions = "true" }, -- Hero Talent
                { command = "/cast Immolation Aura", conditions = "true" },
                { command = "/cast Blade Dance", conditions = "fury >= 15" },
                { command = "/cast Chaos Strike", conditions = "fury >= 40" },
                { command = "/cast Demon's Bite", conditions = "true" },
            },
            aoe = {
                { command = "/cast Eye Beam", conditions = "true" },
                { command = "/cast Essence Break", conditions = "prev_gcd:Eye Beam" },
                { command = "/cast Blade Dance", conditions = "true" },
                { command = "/cast Reaver's Glaive", conditions = "true" },
                { command = "/cast Immolation Aura", conditions = "true" },
                { command = "/cast Chaos Strike", conditions = "fury >= 40" },
            },
            steps = {}
        },
        ["Fel-Scarred"] = { -- Single Target / Fel Devastation Focus
            type = "Priority",
            st = {
                -- Priority 1: SURVIVAL & UTILITY
                { command = "/cast Disrupt", conditions = "should_interrupt and range <= 20" }, -- Interrupt
                { command = "/cast Fel Eruption", conditions = "should_interrupt and cooldown:Disrupt > 0 and talent(Fel Eruption) and range <= 30" }, -- Backup stun interrupt
                { command = "/cast Consume Magic", conditions = "debuff_type == magic and dispellable" }, -- Purge/heal combo
                { command = "/cast Blur", conditions = "health < 45" }, -- 50% DR for 10s
                { command = "/cast Netherwalk", conditions = "health < 25" }, -- Immunity
                { command = "/cast Darkness", conditions = "health < 35 or (in_group and raid_health < 50)" }, -- 20% miss chance (8yd)
                
                -- Cooldowns (Coordinate with Metamorphosis)
                { command = "/cast Metamorphosis", conditions = "cooldown:Eye Beam == 0 or heroism or target_health < 20 and range <= 40" }, -- With Eye Beam ready
                { command = "/cast The Hunt", conditions = "(buff:Metamorphosis or cooldown:Metamorphosis > 40) and range <= 50" }, -- During Meta or if Meta on long CD
                { command = "/cast Eye Beam", conditions = "range <= 40" },
                { command = "/cast Fel Devastation", conditions = "talent(Fel Devastation) and range <= 20" }, -- Fel-Scarred talent
                
                -- Fury Management (Dump before cap at 120)
                { command = "/cast Immolation Aura", conditions = "(charges:Immolation Aura > 1 or buff:Metamorphosis) and range <= 8" }, -- Dump charges or during Meta
                { command = "/cast Blade Dance", conditions = "(fury >= 105 or buff:Metamorphosis) and range <= 8" }, -- Dump at 105+ or during Meta (becomes Death Sweep)
                { command = "/cast Chaos Strike", conditions = "(fury >= 100 or buff:Metamorphosis) and range <= 8" }, -- Dump at 100+ or during Meta (becomes Annihilation)
                
                -- Fury Generation
                { command = "/cast Felblade", conditions = "fury < 60 and range <= 15" }, -- Generate when low
                { command = "/cast Demon's Bite", conditions = "fury < 80 and range <= 8" }, -- Standard generator
                
                -- Finishers
                { command = "/cast Blade Dance", conditions = "range <= 8" },
                { command = "/cast Chaos Strike", conditions = "range <= 8" },
            },
            aoe = {
                { command = "/cast Disrupt", conditions = "should_interrupt and range <= 20" },
                { command = "/cast Blur", conditions = "health < 50 or enemies_nearby >= 5" },
                { command = "/cast Darkness", conditions = "in_group and enemies_nearby >= 4" },
                { command = "/cast Eye Beam", conditions = "range <= 40" },
                { command = "/cast Fel Devastation", conditions = "range <= 20" },
                { command = "/cast Immolation Aura", conditions = "range <= 8" },
                { command = "/cast Blade Dance", conditions = "range <= 8" }, -- AoE priority
                { command = "/cast Chaos Strike", conditions = "fury >= 60 and range <= 8" },
                { command = "/cast Fel Rush", conditions = "fury < 50 and range > 10" }, -- Mobility + Fury gen
            },
            steps = {}
        }
    }
}

-- Vengeance placeholder
SkillWeaver.Sequences[DH_VENGEANCE] = {
    ["Raid"] = {
        ["Balanced"] = {
            type = "Priority",
            st = {
                { command = "/cast Demon Spikes", conditions = "charges:Demon Spikes > 0 and buff:Demon Spikes == 0" },
                { command = "/cast Spirit Bomb", conditions = "souls >= 4" },
                { command = "/cast Soul Cleave", conditions = "pain >= 40" },
                { command = "/cast Immolation Aura", conditions = "true" },
                { command = "/cast Sigil of Flame", conditions = "true" },
                { command = "/cast Fracture", conditions = "true" },
                { command = "/cast Shear", conditions = "true" },
            },
            aoe = {
                { command = "/cast Spirit Bomb", conditions = "souls >= 4" },
                { command = "/cast Immolation Aura", conditions = "true" },
                { command = "/cast Soul Cleave", conditions = "pain >= 50" },
                { command = "/cast Sigil of Flame", conditions = "true" },
            },
            steps = {}
        }
    }
}
