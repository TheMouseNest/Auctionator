---@class addonTableAuctionator
local addonTable = select(2, ...)

addonTable.Prospect = {}

function addonTable.Prospect.IsProspectable(itemID)
  return Auctionator.Prospect.PROSPECT_TABLE[tostring(itemID)] ~= nil
end

local function GetProspectResults(itemID)
  return addonTable.Data.Classic.ProspectingProbability[tostring(itemID)]
end

function addonTable.Prospect.GetAuctionPrice(itemID)
  local prospectResults = GetProspectResults(itemID)

  if prospectResults == nil then
    return nil
  end

  local price = 0

  for reagentKey, allDrops in pairs(prospectResults) do
    local reagentPrice = addonTable.PriceDatabase:GetPrice(reagentKey)

    if reagentPrice == nil then
      return nil
    end

    for index, drop in ipairs(allDrops) do
      price = price + reagentPrice * index * drop
    end
  end

  return price / 5
end
