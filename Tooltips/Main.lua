---@class addonTableAuctionator
local addonTable = select(2, ...)

local function CreateCountString(count)
  if count == 0 then
    return ""
  else
    return LIGHTBLUE_FONT_COLOR:WrapTextInColorCode(" x" .. count)
  end
end

local AddVendorDetails

if C_TooltipInfo then
  function AddVendorDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
    local data = tooltip:GetPrimaryTooltipData()
    local vendor = TooltipUtil.FindLinesFromData({Enum.TooltipDataLineType.SellPrice}, data)
    if vendor.price ~= 0 then
      tooltip:AddDoubleLine(addonTable.Locales.VENDOR .. CreateCountString(stackCount), addonTable.Tooltips.Utilities.CreatePaddedMoneyString(vendor.price * math.max(1, stackCount)))
    end
  end
else
  function AddVendorDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
    local sellPrice = select(11, GetItemInfo(hyperlinkOrItemID))
    if sellPrice ~= 0 then
      tooltip:AddDoubleLine(addonTable.Locales.VENDOR .. CreateCountString(stackCount), addonTable.Tooltips.Utilities.CreatePaddedMoneyString(sellPrice * math.max(1, stackCount)))
    end
  end
end

local function AddAuctionDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
  local price = addonTable.PriceDatabase:GetFirstPrice(dbKeys)
  tooltip:AddDoubleLine(addonTable.Locales.AUCTION .. CreateCountString(stackCount), price and addonTable.Tooltips.Utilities.CreatePaddedMoneyString(price * math.max(1, stackCount)) or addonTable.Locales.UNKNOWN)
end

local function AddAuctionAgeDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
  local age = addonTable.PriceDatabase:GetPriceAge(dbKeys[1])
  tooltip:AddDoubleLine(addonTable.Locales.AUCTION_AGE, age and addonTable.Locales.X_DAYS:format(age) or addonTable.Locales.UNKNOWN)
end

local function AddEnchantDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
  local price = addonTable.Crafting.Disenchant.GetAuctionPrice(hyperlinkOrItemID)
  tooltip:AddDoubleLine(addonTable.Locales.DISENCHANT .. CreateCountString(stackCount), price and addonTable.Tooltips.Utilities.CreatePaddedMoneyString(price * math.max(1, stackCount)) or addonTable.Locales.UNKNOWN)

  if IsShiftKeyDown() then
    for _, line in ipairs(addonTable.Crafting.Disenchant.GetBreakdown(itemLink, {GetItemInfo(hyperlinkOrItemID)})) do
      tooltip:AddLine(line)
    end
  end
end

local function AddProspectDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
  local price = addonTable.Crafting.Prospect.GetAuctionPrice(hyperlinkOrItemID)
  tooltip:AddDoubleLine(addonTable.Locales.PROSPECT .. CreateCountString(stackCount), price and addonTable.Tooltips.Utilities.CreatePaddedMoneyString(price * math.max(1, stackCount)) or addonTable.Locales.UNKNOWN)
end

local function AddMillDetails(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
  local price = addonTable.Crafting.Mill.GetAuctionPrice(hyperlinkOrItemID)
  tooltip:AddDoubleLine(addonTable.Locales.MILL .. CreateCountString(stackCount), price and addonTable.Tooltips.Utilities.CreatePaddedMoneyString(price * math.max(1, stackCount)) or addonTable.Locales.UNKNOWN)
end

local lines = {
  {option = addonTable.Config.Options.TOOLTIPS_VENDOR, func = AddVendorDetails, use = true},
  {option = addonTable.Config.Options.TOOLTIPS_AUCTION, func = AddAuctionDetails, use = true},
  {option = addonTable.Config.Options.TOOLTIPS_AUCTION_AGE, func = AddAuctionAgeDetails, use = true},

  {option = addonTable.Config.Options.TOOLTIPS_ENCHANT, func = AddEnchantDetails, use = addonTable.Constants.IsClassic},
  {option = addonTable.Config.Options.TOOLTIPS_PROSPECT, func = AddProspectDetails, use = addonTable.Constants.IsClassic},
  {option = addonTable.Config.Options.TOOLTIPS_MILL, func = AddMillDetails, use = addonTable.Constants.IsClassic},
}

function addonTable.Tooltips.AddLines(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
  local applyStacks = addonTable.Config.Get(addonTable.Config.Options.TOOLTIPS_SHIFT_STACK)
  stackCount = applyStacks and stackCount or 0
  for _, l in ipairs(lines) do
    if l.use and addonTable.Config.Get(l.option) then
      l.func(tooltip, dbKeys, hyperlinkOrItemID, stackCount)
    end
  end
end
