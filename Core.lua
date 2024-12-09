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

local currentState = {
    crit = 0,
    damage = 0,
}

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
    currentState.crit = 0
    currentState.damage = 0

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
            if debuff.stat == "damage" then
                currentState.damage = currentState.damage + debuff.bonus
            elseif debuff.stat == "crit" then
                currentState.crit = currentState.crit + debuff.bonus
            end
        end
    end
end

local function GetSnapshotStats()
    -- Ottieni i valori di base
    local spellPower = GetSpellBonusDamage(6)
    local critChance = GetSpellCritChance(6)

    local finalCritChance = critChance + currentState.crit
    local finalSpellPower = spellPower + currentState.damage

    return finalSpellPower, finalCritChance
end


local function StartCalculation()
    UpdateCurrentState()

    local spellPower, critChance = GetSnapshotStats()

    text:SetText(string.format("SP: %d | Crit: %.2f%%", spellPower, critChance))
    frame:Show()
end

local function OnCorruptionRemoved()
    frame:Hide()
end

frame:SetScript("OnEvent", function(_, event, ...)
    local timestamp, subEvent, a, sourceName, _, _, destName, _, spellId = ...
    
    if(event == "PLAYER_TARGET_CHANGED") then
        currentTarget = UnitName("target")
        StartCalculation()
    elseif(event == "COMBAT_LOG_EVENT_UNFILTERED" and currentTarget == destName) then
        local myName = UnitName("player")

        if sourceName ~= myName then return end

        if (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" or subEvent == "SPELL_AURA_REMOVED") then
            StartCalculation()
        end
    end
end)

frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")