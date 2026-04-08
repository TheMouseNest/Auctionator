
---@class addonTableAuctionator
local addonTable = select(2, ...)

function addonTable.Crafting.Mill.IsMillable(itemID)
  return addonTable.Data.Classic.MillingProbability[tostring(itemID)] ~= nil
end

local function GetMillResults(itemID)
  return addonTable.Data.Classic.MillingProbability[tostring(itemID)]
end

function addonTable.Crafting.Mill.GetAuctionPrice(itemID)
  local millResults = GetMillResults(itemID)

  if millResults == nil then
    return nil
  end

  local price = 0

  for reagentKey, allDrops in pairs(millResults) do
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
