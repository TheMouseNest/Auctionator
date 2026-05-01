---@class addonTableAuctionator
local addonTable = select(2, ...)

local function IsGear(itemID)
  local classType = select(6, C_Item.GetItemInfoInstant(itemID))
  return addonTable.Utilities.IsEquipment(classType)
end

function addonTable.Storage.BasicDBKeyFromLink(itemLink)
  if itemLink ~= nil then
    local _, _, itemString = string.find(itemLink, "^|c%w+:?|H(.+)|h%[.*%]")
    if itemString == nil and string.find(itemLink, "^item") then
      itemString = itemLink
    end
    if itemString ~= nil then
      local linkType, itemId, _, _, _, _, _, _, _ = strsplit(":", itemString)
      if linkType == "battlepet" then
        return "p:"..itemId;
      elseif linkType == "item" then
        return itemId;
      end
    end
  end
  return nil
end

if addonTable.Constants.IsModernAH then
  function addonTable.Storage.DBKeyFromLinkFast(itemLink)
    local basicKey = addonTable.Utilities.BasicDBKeyFromLink(itemLink)

    if basicKey == nil then
      return {}
    end

    if IsGear(itemLink) then
      if not C_Item.DoesItemExistByID(itemLink) then
        return {}
      end

      local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) or 0
      if itemLevel >= addonTable.Constants.ItemLevelThreshold then
        return {"g:" .. basicKey .. ":" .. itemLevel, basicKey}
      else
        return {basicKey}
      end
    else
      return {basicKey}
    end
  end

  function addonTable.Storage.DBKeyFromLink(itemLink, callback)
    local itemID
    if itemLink then
      itemID = C_Item.GetItemIDForItemInfo(itemLink)
    end
    if not itemID or not C_Item.DoesItemExistByID(itemID) or C_Item.IsItemDataCachedByID(itemLink) then
      callback(addonTable.Storage.DBKeyFromLinkFast(itemLink))
    else
      local item = Item:CreateFromItemID(itemID)
      item:ContinueOnItemLoad(function()
        callback(addonTable.Storage.DBKeyFromLinkFast(itemLink))
      end)
    end
  end
else
  function addonTable.Storage.DBKeyFromLinkFast(itemLink)
    local basicKey = addonTable.Storage.BasicDBKeyFromLink(itemLink)

    if basicKey == nil then
      return {}
    end

    if IsGear(itemLink) then
      local suffix = tonumber((itemLink:match("item:.-:.-:.-:.-:.-:.-:(.-):")))
      local suffixStringID = addonTable.Data.Legacy.SuffixIDToSuffixStringID[suffix]
      local suffixString = addonTable.Data.Legacy.SuffixStringIDTOSuffixString[suffixStringID]
      if suffixString then
        return {"gr:" .. basicKey .. ":" .. suffixString, basicKey}
      else
        return {basicKey}
      end
    else
      return {basicKey}
    end
  end

  function addonTable.Storage.DBKeyFromLink(itemLink, callback)
    callback(addonTable.Storage.DBKeyFromLinkFast(itemLink))
  end
end

function addonTable.Storage.DBKeysFromMultipleLinks(itemLinks, callback)
  local result = {}

  for index, link in ipairs(itemLinks) do
    addonTable.Storage.DBKeyFromLink(link, function(dbKeys)
      result[index] = dbKeys

      for i = 1, #itemLinks do
        if result[i] == nil then
          return
        end
      end
      callback(result)
    end)
  end
end

function addonTable.Storage.Modern.DBKeyFromItemKey(itemKey)
  if itemKey.battlePetSpeciesID ~= 0 then
    return {"p:" .. tostring(itemKey.battlePetSpeciesID)}
  elseif IsGear(itemKey.itemID) and itemKey.itemLevel >= addonTable.Constants.ItemLevelThreshold then
    return {
      "g:" .. itemKey.itemID .. ":" .. itemKey.itemLevel,
      tostring(itemKey.itemID)
    }
  else
    return {tostring(itemKey.itemID)}
  end
end
