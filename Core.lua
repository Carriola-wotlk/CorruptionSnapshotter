local corruptionSpellId = 47813
local currentTarget = nil;

local debuffTable = {
    ["Shadow Embrace"] = {
        [1] = { bonus = 5, stat = "damage" }; -- 1 stack, +5%
        [2] = { bonus = 10, stat = "damage" }; -- 2 stacks, +10%
        [3] = { bonus = 15, stat = "damage" }; -- 3 stacks, +15%
    },
    ["Shadow Mastery"] = { bonus = 5, stat = "crit" }; -- +5%,
    ["Improved Scorch"] = {
        [1] = { bonus = 5, stat = "crit" }; -- 1 stack, +5%
    }
}

local castCrit = 0;
local deltaCrit = 0;


local frame = CreateFrame("Frame", "CorruptionSnapshotterFrame", UIParent)
frame:SetSize(64, 64)
frame:SetPoint("CENTER")
frame:Hide()

local icon = frame:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints()
icon:SetTexture("Interface\\Icons\\Spell_Shadow_AbominationExplosion")

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
text:SetPoint("BOTTOM", frame, "TOP", 0, 5)

local function UpdateCurrentState()
    local crit = 0
    local critChance = GetSpellCritChance(6);
    local _, _, _, _, _, _, mod = UnitDamage("player")

    local healthPercentage = (UnitHealth('target') / UnitHealthMax('target')) * 100

    for i = 1, 40 do
        local debuffName, rank, _, stack, _, _, _, _, _, spellId = UnitDebuff("target", i)

        if not debuffName then break end
        if not debuffTable[debuffName] then return end

        local debuff

        if stack > 0 then
            debuff = debuffTable[debuffName][stack]
        else
            debuff = debuffTable[debuffName]
        end

        if debuff then
            if debuff.stat == "crit" then
                crit = crit + debuff.bonus
            end
        end
    end
    crit = crit + critChance;

    if healthPercentage <= 35 then
        mod = mod + 0.12;
    end

    return (((100*(mod))*(100-crit)/100)+((100*(mod)*2)*(crit)/100))
end

local function PrintValues()
    text:SetText(string.format("castCrit: %d | deltaCrit: %d", castCrit, deltaCrit))
    frame:Show()
end

local function OnCorruptionRemoved()
    frame:Hide()
end

function OnEvent(_, event, ...)
    local timestamp, subEvent, a, sourceName, _, _, destName, _, spellId = ...
    
    if(event == "UNIT_HEALTH") then
        deltaCrit = UpdateCurrentState() - castCrit;
        PrintValues()
    elseif(event == "PLAYER_TARGET_CHANGED") then
        currentTarget = UnitName("target")
        StartCalculation(false)
    elseif(event == "COMBAT_LOG_EVENT_UNFILTERED" and currentTarget == destName) then
        local myName = UnitName("player")

        if sourceName ~= myName and spellId == 47813 then
            castCrit = UpdateCurrentState();
            PrintValues()
        elseif (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" or subEvent == "SPELL_AURA_REMOVED") then
            deltaCrit = UpdateCurrentState() - castCrit
            PrintValues()
        end
    end
end



frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_HEALTH")
frame:SetScript("OnEvent", OnEvent)
