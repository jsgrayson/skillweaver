--========================================================--
-- SkillWeaver - Stock Manager
-- Warns when consumables (Potions, Flasks, Food) are low
--========================================================--

local ADDON_NAME, SkillWeaver = ...
local StockManager = {}
SkillWeaver.StockManager = StockManager

-- Configuration
StockManager.Threshold = 5 -- Warn if below this amount

-- Item IDs to track (Generic list, can be expanded)
local TRACKED_ITEMS = {
    [211880] = "Algari Healing Potion", -- TWW Potion
    [5512] = "Healthstone",
    -- Add Flasks/Food IDs here
}

------------------------------------------------------------
-- Check Stock
------------------------------------------------------------
function StockManager:CheckStock()
    if not SkillWeaver.Settings or not SkillWeaver.Settings.consumables.enabled then return end
    
    local warnings = {}
    
    for itemID, name in pairs(TRACKED_ITEMS) do
        local count = GetItemCount(itemID)
        if count < self.Threshold and count > 0 then -- Don't warn if 0 (might not carry it)
            table.insert(warnings, name .. ": " .. count)
        end
    end
    
    if #warnings > 0 then
        print("|cffff0000SkillWeaver Low Stock Warning:|r")
        for _, warning in ipairs(warnings) do
            print("  - " .. warning)
        end
    end
end

-- Check on login and zone change
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function() 
    C_Timer.After(5, function() StockManager:CheckStock() end) 
end)

return StockManager
