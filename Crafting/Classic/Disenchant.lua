---@class addonTableAuctionator
local addonTable = select(2, ...)

local function GetItemName(itemID)
  local itemName = C_Item.GetItemInfo(itemID)

  return itemName or Auctionator.Constants.DisenchantingItemName[itemID]
end

local function GetItemPrice(itemID)
  local mapping = Auctionator.Constants.DisenchantingMatMapping[itemID]

  if mapping then
    local lesserPrice = Auctionator.API.v1.GetAuctionPriceByItemID("Auctionator", itemID)
    local greaterPrice = Auctionator.API.v1.GetAuctionPriceByItemID("Auctionator", mapping)

    if lesserPrice and greaterPrice and lesserPrice * 3 > greaterPrice then
      return math.floor(greaterPrice / 3)
    else
      return lesserPrice
    end
  else
    return Auctionator.API.v1.GetAuctionPriceByItemID("Auctionator", itemID)
  end
end

local function ItemLevelMatches(entry, itemLevel)
  return itemLevel >= entry[Auctionator.Constants.DisenchantingProbabilityKeys.LOW] and
    itemLevel <= entry[Auctionator.Constants.DisenchantingProbabilityKeys.HIGH]
end

local function GetEntry(classID, itemRarity, itemLevel)
  local itemClassTable = Auctionator.Constants.DisenchantingProbability[classID]
  local entries = (itemClassTable and itemClassTable[itemRarity]) or {}

  for _, entry in pairs(entries) do
    if ItemLevelMatches(entry, itemLevel) then
      return entry
    end
  end
end

local function IsNotCommon(itemRarity)
  return itemRarity == Enum.ItemQuality.Good or
    itemRarity == Enum.ItemQuality.Rare or
    itemRarity == Enum.ItemQuality.Epic
end

local function IsDisenchantableItemType(classID)
  return classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor
end

local function GetDisenchantPrice(classID, itemRarity, itemLevel)
  if IsDisenchantableItemType(classID) and IsNotCommon(itemRarity) then

    local dePrice = 0

    local ta = GetEntry(classID, itemRarity, itemLevel)
    if ta then
      for x = 3, #ta, 3 do
        local price = GetItemPrice(ta[x + 2])

        if price then
          dePrice = dePrice + (ta[x] * ta[x + 1] * price)
        end
      end
    end

    return math.floor(dePrice / 100)
  end

  return nil
end

function addonTable.Crafting.Disenchant.GetStatus(itemInfo)
  return {
    isDisenchantable = IsDisenchantableItemType(itemInfo[12]),
    supportedXpac = true,
  }
end

function addonTable.Crafting.Disenchant.GetBreakdown(itemLink, itemInfo)
  local entry = GetEntry(itemInfo[12], itemInfo[3], C_Item.GetDetailedItemLevelInfo(itemLink))

  local results = {}

  if entry then
    for x = 3, #entry, 3 do
      local percent = math.floor(entry[x] * 100) / 100
      local deitem = GetItemName(entry[x + 2])

      if (percent > 0) then
        table.insert(results, "  " .. WHITE_FONT_COLOR:WrapTextInColorCode(percent .. "%") .. " " .. entry[x + 1] .. " " .. (deitem or '???'))
      end
    end
  end

  return results
end

function addonTable.Crafting.Disenchant.GetAuctionPrice(itemLink, itemInfo)
  local itemLevel = (C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo)(itemLink)
  return GetDisenchantPrice(itemInfo[12], itemInfo[3], itemLevel)
end
