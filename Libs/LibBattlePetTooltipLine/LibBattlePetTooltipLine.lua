local lib = LibStub:NewLibrary("LibBattlePetTooltipLine-1-0", 1)

if not lib or not BattlePetToolTip_Show then return end

local battlePetTooltipFontStringPool = CreateFontStringPool(UIParent, "ARTWORK", 0, "GameTooltipText")

local padding = 10

local function PetTooltipShow(tooltip)
  tooltip.Name:SetPoint("LEFT", padding, 0)
  tooltip.PetType:ClearAllPoints()
  tooltip.PetType:SetPoint("TOP", tooltip.Name, "BOTTOM", 0, -5)
  tooltip.PetType:SetPoint("RIGHT", -padding, 0)
end

-- Revert changes to the tooltip
local function DefaultSetup(self)
  self:SetWidth(260)
  self.PetType:ClearAllPoints()
  self.PetType:SetPoint("BOTTOM", self.Name, 0, -5)
end

hooksecurefunc("BattlePetToolTip_Show", function(...)
  PetTooltipShow(BattlePetTooltip)
end)

BattlePetTooltip:HookScript("OnHide", DefaultSetup)

hooksecurefunc("FloatingBattlePet_Toggle", function(...)
  if FloatingBattlePetTooltip:IsShown() then
    PetTooltipShow(FloatingBattlePetTooltip)
  end
end)
FloatingBattlePetTooltip:HookScript("OnHide", DefaultSetup)

function lib:AddLine(tooltip, left, wrapText)
  assert(tooltip.PetType)
  tooltip:AddLine(left, nil, nil, nil, wrapText)
  local leftText = tooltip.textLineAnchor
  local neededWidth = leftText:GetWidth() + 2 * padding
  if neededWidth > tooltip:GetWidth() then
    tooltip:SetWidth(neededWidth)
  end
end

function lib:AddDoubleLine(tooltip, left, right)
  assert(tooltip.PetType)
  tooltip:AddLine(left)
  local rightText = battlePetTooltipFontStringPool:Acquire()
  rightText:SetParent(tooltip)
  rightText:SetScript("OnHide", function(self)
    battlePetTooltipFontStringPool:Release(self)
  end)
  rightText:Show()
  rightText:SetPoint("TOP", tooltip.textLineAnchor)
  rightText:SetPoint("RIGHT", tooltip, -padding, 0)
  rightText:SetText(right)
  local neededWidth = rightText:GetWidth() + tooltip.textLineAnchor:GetWidth() + 40 + 2 * padding
  if neededWidth > tooltip:GetWidth() then
    tooltip:SetWidth(neededWidth)
  end
end
