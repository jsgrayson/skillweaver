--========================================================--
-- SkillWeaver - Equipment Manager
-- Automatically recommends and equips gear based on Stat Weights
--========================================================--

local EquipmentManager = {}
SkillWeaver.EquipmentManager = EquipmentManager

local StatWeights = require("SkillWeaver.data.StatWeights")

-- WoW API References
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetContainerItemLink = C_Container.GetContainerItemLink
local GetItemStats = C_Item.GetItemStats
local GetInventoryItemLink = GetInventoryItemLink
local EquipItemByName = EquipItemByName
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo

-- Inventory Slots to Manage
local INVENTORY_SLOTS = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot",
    "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
    "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}

-- Map Stat Names to API Keys
local STAT_MAP = {
    ["MainStat"]    = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_INTELLECT_SHORT" },
    ["Haste"]       = { "ITEM_MOD_HASTE_RATING_SHORT" },
    ["Crit"]        = { "ITEM_MOD_CRIT_RATING_SHORT" },
    ["Mastery"]     = { "ITEM_MOD_MASTERY_RATING_SHORT" },
    ["Versatility"] = { "ITEM_MOD_VERSATILITY" }
}

------------------------------------------------------------
-- Helper: Get Current Spec ID
------------------------------------------------------------
local function GetCurrentSpecID()
    local currentSpec = GetSpecialization()
    if currentSpec then
        local id, _ = GetSpecializationInfo(currentSpec)
        return id
    end
    return nil
end

------------------------------------------------------------
-- Core: Calculate Item Score
------------------------------------------------------------
function EquipmentManager:GetItemScore(itemLink, weights)
    if not itemLink or not weights then return 0 end

    local stats = GetItemStats(itemLink)
    if not stats then return 0 end

    local score = 0

    -- Iterate through our defined weights
    for statName, weight in pairs(weights) do
        local apiKeys = STAT_MAP[statName]
        if apiKeys then
            for _, key in ipairs(apiKeys) do
                local statValue = stats[key] or 0
                score = score + (statValue * weight)
            end
        end
    end

    return score
end

------------------------------------------------------------
-- Core: Scan Bags for Best Items
------------------------------------------------------------
function EquipmentManager:GetBestSet(contentType)
    local specID = GetCurrentSpecID()
    if not specID then return nil end

    local weights = StatWeights:GetWeights(specID, contentType)
    if not weights then 
        print("SkillWeaver: No stat weights found for SpecID " .. specID)
        return nil 
    end

    local bestSet = {}
    local bestScores = {}

    -- Initialize slots
    for _, slotName in ipairs(INVENTORY_SLOTS) do
        local slotID = GetInventorySlotInfo(slotName)
        bestSet[slotID] = nil
        bestScores[slotID] = 0
    end

    -- 1. Scan Equipped Items
    for _, slotName in ipairs(INVENTORY_SLOTS) do
        local slotID = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            local score = self:GetItemScore(itemLink, weights)
            bestSet[slotID] = itemLink
            bestScores[slotID] = score
        end
    end

-- Map EquipLoc (from GetItemInfo) to Inventory Slot IDs
local EQUIP_LOC_MAP = {
    ["INVTYPE_HEAD"] = { GetInventorySlotInfo("HeadSlot") },
    ["INVTYPE_NECK"] = { GetInventorySlotInfo("NeckSlot") },
    ["INVTYPE_SHOULDER"] = { GetInventorySlotInfo("ShoulderSlot") },
    ["INVTYPE_CLOAK"] = { GetInventorySlotInfo("BackSlot") },
    ["INVTYPE_CHEST"] = { GetInventorySlotInfo("ChestSlot") },
    ["INVTYPE_ROBE"] = { GetInventorySlotInfo("ChestSlot") },
    ["INVTYPE_WRIST"] = { GetInventorySlotInfo("WristSlot") },
    ["INVTYPE_HAND"] = { GetInventorySlotInfo("HandsSlot") },
    ["INVTYPE_WAIST"] = { GetInventorySlotInfo("WaistSlot") },
    ["INVTYPE_LEGS"] = { GetInventorySlotInfo("LegsSlot") },
    ["INVTYPE_FEET"] = { GetInventorySlotInfo("FeetSlot") },
    ["INVTYPE_FINGER"] = { GetInventorySlotInfo("Finger0Slot"), GetInventorySlotInfo("Finger1Slot") },
    ["INVTYPE_TRINKET"] = { GetInventorySlotInfo("Trinket0Slot"), GetInventorySlotInfo("Trinket1Slot") },
    ["INVTYPE_WEAPON"] = { GetInventorySlotInfo("MainHandSlot"), GetInventorySlotInfo("SecondaryHandSlot") },
    ["INVTYPE_SHIELD"] = { GetInventorySlotInfo("SecondaryHandSlot") },
    ["INVTYPE_2HWEAPON"] = { GetInventorySlotInfo("MainHandSlot") },
    ["INVTYPE_WEAPONMAINHAND"] = { GetInventorySlotInfo("MainHandSlot") },
    ["INVTYPE_WEAPONOFFHAND"] = { GetInventorySlotInfo("SecondaryHandSlot") },
    ["INVTYPE_HOLDABLE"] = { GetInventorySlotInfo("SecondaryHandSlot") },
}

------------------------------------------------------------
-- Core: Scan Bags for Best Items
------------------------------------------------------------
function EquipmentManager:GetBestSet(contentType)
    local specID = GetCurrentSpecID()
    if not specID then return nil end

    local weights = StatWeights:GetWeights(specID, contentType)
    if not weights then 
        print("SkillWeaver: No stat weights found for SpecID " .. specID)
        return nil 
    end

    -- Store all candidate items per slot type
    -- Format: candidates[SlotType] = { { link=itemLink, score=123, bag=bag, slot=slot }, ... }
    local candidates = {}

    -- Helper to add candidate
    local function AddCandidate(itemLink, bag, slot)
        local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
        if equipLoc and EQUIP_LOC_MAP[equipLoc] then
            local score = self:GetItemScore(itemLink, weights)
            
            -- Use the first mapped slot as the "key" for grouping (e.g., all rings group under Finger0)
            local primarySlotID = EQUIP_LOC_MAP[equipLoc][1]
            
            if not candidates[primarySlotID] then candidates[primarySlotID] = {} end
            table.insert(candidates[primarySlotID], { link = itemLink, score = score, bag = bag, slot = slot, equipLoc = equipLoc })
        end
    end

    -- 1. Scan Equipped Items
    for _, slotName in ipairs(INVENTORY_SLOTS) do
        local slotID = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            AddCandidate(itemLink, nil, slotID) -- bag=nil indicates equipped
        end
    end

    -- 2. Scan Bags
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                AddCandidate(itemLink, bag, slot)
            end
        end
    end

    -- 3. Select Best Items
    local bestSet = {} -- [SlotID] = { link, bag, slot }
    
    for primarySlotID, items in pairs(candidates) do
        -- Sort by score descending
        table.sort(items, function(a, b) return a.score > b.score end)
        
        -- Determine target slots for this item type
        -- We look up the equipLoc of the first item to find all valid slots
        local equipLoc = items[1].equipLoc
        local targetSlots = EQUIP_LOC_MAP[equipLoc]
        
        -- Assign top items to slots
        for i, slotID in ipairs(targetSlots) do
            if items[i] then
                bestSet[slotID] = items[i]
            end
        end
    end

    return bestSet, weights
end

------------------------------------------------------------
-- Core: Equip Best Set
------------------------------------------------------------
function EquipmentManager:EquipBestSet(contentType)
    if InCombatLockdown() then
        print("|cffFF0000SkillWeaver:|r Cannot equip gear in combat!")
        return
    end

    local bestSet = self:GetBestSet(contentType)
    if not bestSet then return end

    local equippedCount = 0
    
    for slotID, itemData in pairs(bestSet) do
        local currentLink = GetInventoryItemLink("player", slotID)
        
        -- Check if we need to swap
        if currentLink ~= itemData.link then
            if itemData.bag then
                -- Item is in bag, equip it
                C_Container.PickupContainerItem(itemData.bag, itemData.slot)
                EquipCursorItem(slotID)
                equippedCount = equippedCount + 1
            else
                -- Item is already equipped (but maybe in wrong slot? e.g. ring swap)
                -- If it's equipped in another slot, we might need to swap.
                -- For simplicity, if it's nil (equipped), we assume it's fine unless we are swapping slots.
                -- This logic can be complex for ring swaps. 
                -- Current simple implementation: If bag is nil, it's already on character.
            end
        end
    end

    if equippedCount > 0 then
        print("|cff00FF00SkillWeaver:|r Equipped " .. equippedCount .. " items for " .. contentType .. ".")
    else
        print("|cff00FF00SkillWeaver:|r You are already wearing the best gear for " .. contentType .. ".")
    end
end

return EquipmentManager
