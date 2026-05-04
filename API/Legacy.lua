---@class addonTableAuctionator
local addonTable = select(2, ...)

function addonTable.API.ComposeError(callerID, message)
  error(
    "Contact the maintainer of " .. callerID ..
    " to resolve this problem. Details: " .. message
  )
end

function Auctionator.API.v1.GetAuctionPriceByItemID(callerID, itemID)
  if type(itemID) ~= "number" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionPriceByItemID(string, number)"
    )
  end

  if addonTable.PriceDatabase == nil then
    return nil
  end

  return addonTable.PriceDatabase:GetPrice(tostring(itemID))
end

function Auctionator.API.v1.GetAuctionPriceByItemLink(callerID, itemLink)
  if type(itemLink) ~= "string" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionPriceByItemLink(string, string)"
    )
  end

  if addonTable.PriceDatabase == nil then
    return nil
  end

  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  local dbKeys = addonTable.Storage.DBKeyFromLinkFast(itemLink)

  if dbKeys then
    return addonTable.PriceDatabase:GetFirstPrice(dbKeys)
  else
    return addonTable.PriceDatabase:GetPrice(
      Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
    )
  end
end

-- Returns the number of days since the item was seen in the auction house,
-- except if the number of days exceeds 21, then it returns nil. It will return
-- nil if there is no auction ever seen in the auction house for the item.
function Auctionator.API.v1.GetAuctionAgeByItemID(callerID, itemID)
  if type(itemID) ~= "number" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionAgeByItemID(string, number)"
    )
  end

  if addonTable.PriceDatabase == nil then
    return nil
  end

  return addonTable.PriceDatabase:GetPriceAge(tostring(itemID))
end

function Auctionator.API.v1.IsAuctionDataExactByItemID(callerID, itemID)
  if type(itemID) ~= "number" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.IsAuctionDataExactByItemID(string, number)"
    )
  end

  if addonTable.PriceDatabase == nil then
    return nil
  end

  return addonTable.PriceDatabase:GetPrice(tostring(itemID)) ~= nil
end

function Auctionator.API.v1.IsAuctionDataExactByItemLink(callerID, itemLink)
  if type(itemLink) ~= "string" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.IsAuctionDataExactByItemLink(string, string)"
    )
  end

  if addonTable.PriceDatabase == nil then
    return false
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  addonTable.Storage.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    if #dbKeys > 2 then
      return addonTable.PriceDatabase:GetPrice(dbKeys[1]) ~= nil or addonTable.PriceDatabase:GetPrice(dbKeys[2]) ~= nil
    else
      return addonTable.PriceDatabase:GetPrice(dbKeys[1]) ~= nil
    end
  else
    return addonTable.PriceDatabase:GetPrice(
      addonTable.Storage.BasicDBKeyFromLink(itemLink)
    ) ~= nil
  end
end

function Auctionator.API.v1.GetAuctionAgeByItemLink(callerID, itemLink)
  if type(itemLink) ~= "string" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionAgeByItemLink(string, string)"
    )
  end

  if addonTable.PriceDatabase == nil then
    return nil
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  addonTable.Storage.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    if #dbKeys > 2 then
      return addonTable.PriceDatabase:GetPriceAge(dbKeys[1]) or addonTable.PriceDatabase:GetPriceAge(dbKeys[2])
    else
      return addonTable.PriceDatabase:GetPriceAge(dbKeys[1])
    end
  else
    return addonTable.PriceDatabase:GetPriceAge(
      addonTable.Storage.BasicDBKeyFromLink(itemLink)
    )
  end
end

function Auctionator.API.v1.GetDisenchantPriceByItemID(callerID, itemID)
  if type(itemID) ~= "number" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionPriceByItemID(string, number)"
    )
  end

  local itemInfo = { C_Item.GetItemInfo(itemID) }
  local itemLink = itemInfo[2]

  if itemLink ~= nil then
    return addonTable.Enchant.GetDisenchantAuctionPrice(itemLink, itemInfo)
  else
    return nil
  end
end

function Auctionator.API.v1.GetDisenchantPriceByItemLink(callerID, itemLink)
  if type(itemLink) ~= "string" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionPriceByItemLink(string, string)"
    )
  end

  local itemInfo = { C_Item.GetItemInfo(itemLink) }

  if #itemInfo > 0 then
    return addonTable.Enchant.GetDisenchantAuctionPrice(itemLink, itemInfo)
  else
    return nil
  end
end

function Auctionator.API.v1.GetVendorPriceByItemID(callerID, itemID)
  if type(itemID) ~= "number" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetVendorPriceByItemID(string, number)"
    )
  end

  return AUCTIONATOR_VENDOR_PRICE_CACHE[tostring(itemID)]
end

function Auctionator.API.v1.GetVendorPriceByItemLink(callerID, itemLink)
  if type(itemLink) ~= "string" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetVendorPriceByItemLink(string, string)"
    )
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  addonTable.Storage.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    for _, key in ipairs(dbKeys) do
      if AUCTIONATOR_VENDOR_PRICE_CACHE[key] then
        return AUCTIONATOR_VENDOR_PRICE_CACHE[key]
      end
    end
  else
    return AUCTIONATOR_VENDOR_PRICE_CACHE[Auctionator.Utilities.BasicDBKeyFromLink(itemLink)]
  end
end

function Auctionator.API.v1.RegisterForDBUpdate(callerID, callback)
  if type(callback) ~= "function" then
    addonTable.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.RegisterForDBUpdate(string, function)"
    )
  end

  addonTable.CallbackRegistry:RegisterCallback("ScanComplete", function()
    callback()
  end)
  addonTable.CallbackRegistry:RegisterCallback("PricesUpdated", function()
    callback()
  end)
end
