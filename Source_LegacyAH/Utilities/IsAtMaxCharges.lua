local possibleChargePatterns
do
  possibleChargePatterns = {
    "^" .. ITEM_SPELL_CHARGES_NONE .. "$",
  }

  local escapeSequence = ITEM_SPELL_CHARGES:match("|4([^;]*);")

  if escapeSequence then
    for _, part in ipairs({ strsplit(":", escapeSequence) }) do
      table.insert(possibleChargePatterns, "^" .. (ITEM_SPELL_CHARGES:gsub("%%d", "%%d%+"):gsub("|4[^;]*;", part)) .. "$")
    end
  else
    table.insert(possibleChargePatterns, "^" .. ITEM_SPELL_CHARGES .. "$")
  end
end

-- Gets the string (if any) that specifies the max charges for the item in
-- its tooltip.
local function GetChargesText(itemLink)
  -- Using the tooltip set by item ID gets it to show the max charges
  -- (unlike when using an item link)
  local itemID = C_Item.GetItemInfoInstant(itemLink)
  return Auctionator.Utilities.ScanTooltip(
    function(tip)
      tip:SetItemByID(itemID)
    end,
    function(str)
      for _, pat in ipairs(possibleChargePatterns) do
        if str:match(pat) then
          return true
        end
      end
    end
  )
end

-- Given a bag item determine if has the maximum possible charges. Intended for
-- use on consumables.
function Auctionator.Utilities.IsAtMaxCharges(bagLocation)
  local itemLink = C_Item.GetItemLink(bagLocation)
  local chargesText = GetChargesText(itemLink)
  if chargesText ~= nil then
    return Auctionator.Utilities.ScanTooltip(
      function(tip) tip:SetBagItem(bagLocation:GetBagAndSlot()) end,
      function(str) return chargesText == str end
    ) ~= nil
  end
  return true
end
