---@class addonTableAuctionator
local addonTable = select(2, ...)

function addonTable.Wrappers.Modern.SendSearchQueryByGenerator(itemKeyGenerator, sorts, splitOwnedItems)
  function rawSearch(itemKey)
    C_AuctionHouse.SendSearchQuery(itemKey, sorts, splitOwnedItems)
  end

  addonTable.Wrappers.Internals.searchScan:SetSearch(itemKeyGenerator, rawSearch)
end

function addonTable.Wrappers.Modern.SendSearchQueryByItemKey(itemKey, sorts, splitOwnedItems)
  function itemKeyGenerator()
    return itemKey
  end
  function rawSearch(itemKey)
    C_AuctionHouse.SendSearchQuery(itemKey, sorts, splitOwnedItems)
  end

  addonTable.Wrappers.Internals.searchScan:SetSearch(itemKeyGenerator, rawSearch)
end

function addonTable.Wrappers.Modern.SendSellSearchQueryByGenerator(itemKeyGenerator, sorts, splitOwnedItems)
  function rawSearch(itemKey)
    C_AuctionHouse.SendSellSearchQuery(itemKey, sorts, splitOwnedItems)
  end

  addonTable.Wrappers.Internals.searchScan:SetSearch(itemKeyGenerator, rawSearch)
end

function addonTable.Wrappers.Modern.SendSellSearchQueryByItemKey(itemKey, sorts, splitOwnedItems)
  function itemKeyGenerator()
    return itemKey
  end
  function rawSearch(itemKey)
    C_AuctionHouse.SendSellSearchQuery(itemKey, sorts, splitOwnedItems)
  end

  addonTable.Wrappers.Internals.searchScan:SetSearch(itemKeyGenerator, rawSearch)
end

function addonTable.Wrappers.Modern.QueryOwnedAuctions(...)
  local args = {...}
  addonTable.Wrappers.Queue:Enqueue(function()
    C_AuctionHouse.QueryOwnedAuctions(unpack(args))
  end)
end

local sentBrowseQuery = true
function addonTable.Wrappers.Modern.SendBrowseQuery(...)
  local args = {...}
  sentBrowseQuery = false
  addonTable.Wrappers.Queue:Enqueue(function()
    sentBrowseQuery = true
    C_AuctionHouse.SendBrowseQuery(unpack(args))
  end)
end

function addonTable.Wrappers.Modern.HasFullBrowseResults()
  return sentBrowseQuery and C_AuctionHouse.HasFullBrowseResults()
end

function addonTable.Wrappers.Modern.RequestMoreBrowseResults(...)
  local args = {...}
  addonTable.Wrappers.Queue:Enqueue(function()
    C_AuctionHouse.RequestMoreBrowseResults(unpack(args))
  end)
end

-- Event ThrottleUpdate will fire whenever the state changes
function addonTable.Wrappers.Modern.IsNotThrottled()
  return addonTable.Wrappers.Internals.throttling:IsReady()
end

function addonTable.Wrappers.Modern.CancelAuction(...)
  -- Can't be queued, "protected" call
  C_AuctionHouse.CancelAuction(...)
end

function addonTable.Wrappers.Modern.ReplicateItems()
  C_AuctionHouse.ReplicateItems()
end

function addonTable.Wrappers.Modern.GetItemKeyInfo(itemKey, callback)
  addonTable.Wrappers.Internals.itemKeyLoader:Get(itemKey, callback)
end

function addonTable.Wrappers.Modern.GetAuctionItemSubClasses(classID)
  return C_AuctionHouse.GetAuctionItemSubClasses(classID)
end
