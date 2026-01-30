Auctionator.Groups.Utilities = {}
function Auctionator.Groups.Utilities.IsContainedPredicate(list, pred)
  for _, item in ipairs(list) do
    if (pred(item)) then
      return true
    end
  end
  return false
end

function Auctionator.Groups.Utilities.ToPostingItem(info)
  return {
    itemLink = info.itemLink,
    itemID = info.itemID,
    itemName = info.itemName,
    itemLevel = info.itemLevel,
    iconTexture = info.iconTexture,
    quality = info.quality,
    count = info.itemCount,
    location = info.locations[1],
    classId = info.classID,
    auctionable = true,
    bagListing = true,
    nextItem = nil,
    prevItem = nil,
    sortKey = info.sortKey,
  }
end

function Auctionator.Groups.Utilities.QueryItem(sortKey)
  return AuctionatorBagCacheFrame:GetByKey(sortKey)
end

if Auctionator.Constants.IsRetail then
  local itemLevelMap = {}
  local ITEM_LEVEL_PATTERN = ITEM_LEVEL:gsub("%%d", "(%%d+)")
  function Auctionator.Groups.Utilities.ExtractItemLevel(itemLink)
    local prev = itemLevelMap[itemLink]
    if prev then
      return prev
    end

    local tooltipData = C_TooltipInfo.GetHyperlink(itemLink)
    if not tooltipData then
      itemLevelMap[itemLink] = 0
      return 0
    end
    for _, line in ipairs(tooltipData.lines) do
      local level = line.leftText:match(ITEM_LEVEL_PATTERN)
      if level then
        level = tonumber(level)
        itemLevelMap[itemLink] = level
        return level
      end
    end
    itemLevelMap[itemLink] = 0
    return 0
  end
end
