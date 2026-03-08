local function IsGear(itemID)
  local classType = select(6, C_Item.GetItemInfoInstant(itemID))
  return Auctionator.Utilities.IsEquipment(classType)
end

-- Build DB keys from itemKey (itemID, itemLevel, itemSuffix) for price lookup.
-- Preserves itemLevel for crafted gear so each ilvl tier shows its correct AH price.
function Auctionator.Utilities.DBKeysFromItemKey(itemKey)
  if not itemKey then return {} end
  if (itemKey.battlePetSpeciesID or 0) ~= 0 then return {"p:" .. tostring(itemKey.battlePetSpeciesID)} end
  if IsGear(itemKey.itemID) and (itemKey.itemLevel or 0) >= Auctionator.Constants.ITEM_LEVEL_THRESHOLD then
    return {"g:" .. itemKey.itemID .. ":" .. (itemKey.itemLevel or 0), tostring(itemKey.itemID)}
  end
  return {tostring(itemKey.itemID)}
end

function Auctionator.Utilities.DBKeyFromBrowseResult(result)
  if result.itemKey.battlePetSpeciesID ~= 0 then
    return {"p:" .. tostring(result.itemKey.battlePetSpeciesID)}
  elseif IsGear(result.itemKey.itemID) and result.itemKey.itemLevel >= Auctionator.Constants.ITEM_LEVEL_THRESHOLD then
    return {
      "g:" .. result.itemKey.itemID .. ":" .. result.itemKey.itemLevel,
      tostring(result.itemKey.itemID)
    }
  else
    return {tostring(result.itemKey.itemID)}
  end
end
