local HealerLoader = require("skillweaver.core.HealerLoader")

local SkillWeaver = {}

SkillWeaver.currentSpec = nil
SkillWeaver.role = nil
SkillWeaver.Sequences = {}

---------------------------------------------------------
-- Secure Buttons (ST & AoE)
---------------------------------------------------------
-- These buttons are clicked by the user's macro.
-- They use SecureHandler to cycle through steps.

local btnST = CreateFrame("Button", "SkillWeaverButton_ST", UIParent, "SecureActionButtonTemplate, SecureHandlerStateTemplate")
btnST:SetAttribute("type", "macro")
btnST:RegisterForClicks("AnyDown", "AnyUp")

local btnAoE = CreateFrame("Button", "SkillWeaverButton_AoE", UIParent, "SecureActionButtonTemplate, SecureHandlerStateTemplate")
btnAoE:SetAttribute("type", "macro")
btnAoE:RegisterForClicks("AnyDown", "AnyUp")

-- Secure Snippet: Cycles 'stepX' attributes into 'macrotext'
-- This runs in the restricted environment.
local secureSnippet = [[
    local step = self:GetAttribute("step_index") or 1
    local total = self:GetAttribute("step_total") or 1
    
    -- Get command for current step
    local cmd = self:GetAttribute("step" .. step)
    
    -- Set macrotext for execution
    self:SetAttribute("macrotext", cmd)
    
    -- Advance index
    step = step + 1
    if step > total then step = 1 end
    self:SetAttribute("step_index", step)
]]

-- Attach snippet to OnClick
btnST:SetAttribute("_onclick", secureSnippet)
btnAoE:SetAttribute("_onclick", secureSnippet)

---------------------------------------------------------
-- Update Secure Button with Sequence Data
---------------------------------------------------------
function SkillWeaver:UpdateSecureButton(sequence)
    if not sequence then return end
    
    -- Store for Overlay
    self.ActiveSequence = sequence

    -- 1. Generate the macro body for the SecureHandler
    -- We want a snippet that iterates our steps.
    -- But SecureHandlers are tricky.
    -- Simplified approach for "One Button":
    -- We will use a snippet that runs on PreClick.
    if InCombatLockdown() then
        print("|cffFF0000SkillWeaver: Cannot update buttons in combat!|r")
        return
    end

    -- 1. Process Single Target (ST)
    -- If sequence has explicit 'st' table, use it. Otherwise use main 'steps'.
    local stSteps = sequence.st or sequence.steps
    if stSteps then
        btnST:SetAttribute("step_total", #stSteps)
        btnST:SetAttribute("step_index", 1)
        for i, step in ipairs(stSteps) do
            btnST:SetAttribute("step" .. i, step.command)
        end
    else
        btnST:SetAttribute("step_total", 1)
        btnST:SetAttribute("step1", "/cast [help] Flash Heal; Smite") -- Fallback
    end

    -- 2. Process AoE
    -- If sequence has explicit 'aoe' table, use it. Otherwise default to ST.
    local aoeSteps = sequence.aoe
    if aoeSteps then
        btnAoE:SetAttribute("step_total", #aoeSteps)
        btnAoE:SetAttribute("step_index", 1)
        for i, step in ipairs(aoeSteps) do
            btnAoE:SetAttribute("step" .. i, step.command)
        end
    else
        -- Fallback: Clone ST if no AoE specified
        btnAoE:SetAttribute("step_total", #stSteps)
        btnAoE:SetAttribute("step_index", 1)
        for i, step in ipairs(stSteps) do
            btnAoE:SetAttribute("step" .. i, step.command)
        end
    end

    print("|cff00ff00SkillWeaver: Secure Buttons Updated.|r")
end

---------------------------------------------------------
-- Called when player changes spec
---------------------------------------------------------
function SkillWeaver:OnSpecChanged(specID)
    self.currentSpec = specID

    if self:IsHealerSpec(specID) then
        self.role = "HEALER"
        HealerLoader:Activate(specID)
    else
        self.role = "DPS" -- future
    end
end

---------------------------------------------------------
-- Identify healer specs
---------------------------------------------------------
function SkillWeaver:IsHealerSpec(specID)
    return (
        specID == "PALADIN_65" or
        specID == "PRIEST_256" or
        specID == "PRIEST_257" or
        specID == "DRUID_105" or
        specID == "SHAMAN_264" or
        specID == "MONK_270" or
        specID == "EVOKER_1468"
    )
end

return SkillWeaver
