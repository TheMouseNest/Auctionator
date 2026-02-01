AuctionatorBagCacheMixin = {}
function AuctionatorBagCacheMixin:OnLoad()
  self.cache = {}
  self.loaders = {}
  self.contents = {}

  self.cacheOn = 0
  Auctionator.Groups.CallbackRegistry:RegisterCallback("BagCacheOn", function()
    self.cacheOn = self.cacheOn + 1
    if self.cacheOn > 0 then
      self:SetScript("OnUpdate", self.DoBagRefresh)
    end
  end)
  Auctionator.Groups.CallbackRegistry:RegisterCallback("BagCacheOff", function()
    self.cacheOn = self.cacheOn - 1
    if self.cacheOn <= 0 then
      self:SetScript("OnUpdate", self.DoBagRefresh)
    end
  end)
  self:RegisterEvent("BAG_UPDATE")
end

function AuctionatorBagCacheMixin:OnEvent(eventName, ...)
  if self.cacheOn > 0 and eventName == "BAG_UPDATE" then
    self:SetScript("OnUpdate", self.DoBagRefresh)
  end
end

local function GetItemKey(entry)
  local itemLevel = entry.itemLevel or 0
  if entry.classID == Enum.ItemClass.Battlepet then
    itemLevel = Auctionator.Utilities.GetPetLevelFromLink(entry.itemLink)
  end
  return entry.itemID .. "_" ..  entry.itemName .. "_" .. itemLevel .. "_" .. entry.quality .. "_" ..  tostring(entry.auctionable)
end

function AuctionatorBagCacheMixin:PostUpdate(bagContents)
  local byKey = {}
  for _, item in ipairs(bagContents) do
    if byKey[item.key] == nil then
      byKey[item.key] = {
        count = 0,
        entries = {}
      }
    end
    local existingEntry = byKey[item.key]
    existingEntry.count = existingEntry.count + item.itemCount
    table.insert(existingEntry.entries, item)
  end
  self.contents = byKey
  Auctionator.Groups.CallbackRegistry:TriggerEvent("BagCacheUpdated", self)
end

local linkInstantCache = {}
function AuctionatorBagCacheMixin:GetByLinkInstant(suppliedItemLink, auctionable)
  local entry = linkInstantCache[suppliedItemLink]

  if entry == nil then
    return
  end

  entry.auctionable = auctionable

  local key = GetItemKey(entry)
  local realEntry = self.contents[key]
  local itemLink = entry.itemLink

  local itemCount = 0
  local locations = {}

  if realEntry ~= nil then
    for _, e in ipairs(realEntry.entries) do
      table.insert(locations, e.location)
    end
    itemCount = realEntry.count
    itemLink = realEntry.entries[1].itemLink
  end

  return {
    locations = locations,
    itemCount = itemCount,
    auctionable = auctionable,
    itemName = entry.itemName,
    itemLink = itemLink,
    itemID = entry.itemID,
    itemLevel = entry.itemLevel,
    quality = entry.quality,
    iconTexture = entry.iconTexture,
    classID = entry.classID,
    sortKey = key,
  }
end

function AuctionatorBagCacheMixin:GetByKey(key)
  local value = self.contents[key]
  if value ~= nil then
    local entry = value.entries[1]
    local locations = {}
    for _, e in ipairs(value.entries) do
      table.insert(locations, e.location)
    end

    return {
      locations = locations,
      itemCount = value.count,
      itemName = entry.itemName,
      itemID = entry.itemID,
      itemLevel = entry.itemLevel,
      auctionable = entry.auctionable,
      itemLink = entry.itemLink,
      quality = entry.quality,
      iconTexture = entry.iconTexture,
      classID = entry.classID,
      sortKey = key,
    }
  end
end

function AuctionatorBagCacheMixin:CacheLinkInfo(suppliedItemLink, callback)
  local existingEntry = linkInstantCache[suppliedItemLink]
  if existingEntry then
    callback()
    return
  end

  callback = callback or function() end

  local realEntry

  if suppliedItemLink:match("battlepet") then
    local itemName, iconTexture = C_PetJournal.GetPetInfoBySpeciesID(tonumber(suppliedItemLink:match("battlepet:(%d+)")))

    local entry = {
      itemLink = suppliedItemLink,
      itemID = Auctionator.Constants.PET_CAGE_ID,
      itemName = itemName,
      iconTexture = iconTexture,
      itemCount = 0,
      classID = Enum.ItemClass.Battlepet,
      quality = tonumber(suppliedItemLink:match("battlepet:%d*:%d*:(%d+)") or "3")
    }
    entry.key = GetItemKey(entry)
    linkInstantCache[suppliedItemLink] = entry

    callback()
  else
    -- Ignore mythic keystones, etc.
    local itemID = C_Item.GetItemInfoInstant(suppliedItemLink)
    if itemID == nil then
      return
    end

    local item = Item:CreateFromItemLink(suppliedItemLink)
    item:ContinueOnItemLoad(function()
      local itemName, itemLink = C_Item.GetItemInfo(suppliedItemLink)

      local entry = {
        itemLink = suppliedItemLink,
        iconTexture = item:GetItemIcon(),
        itemName = itemName,
        itemID = itemID,
        itemLink = itemLink,
        itemCount = 0,
        classID = select(6, C_Item.GetItemInfoInstant(itemLink)),
        quality = item:GetItemQuality(),
      }
      if Auctionator.Utilities.IsEquipment(entry.classID) then
        if Auctionator.Constants.IsRetail then
          entry.itemLevel = Auctionator.Groups.Utilities.ExtractItemLevel(entry.itemLink)
        else
          entry.itemLevel = C_Item.GetDetailedItemLevelInfo(entry.itemLink)
        end
      end
      linkInstantCache[suppliedItemLink] = entry
      callback()
    end)
  end
end

function AuctionatorBagCacheMixin:GetAllContents()
  local result = {}
  for key in pairs(self.contents) do
    table.insert(result, self:GetByKey(key))
  end
  return result
end

function AuctionatorBagCacheMixin:DoBagRefresh()
  self:SetScript("OnUpdate", nil)
  if self.waiting then
    for _, l in pairs(self.loaders) do
      l()
    end
  end
  self.loaders = {}

  self.waiting = true

  local entireBag = {}
  local waitingCount = 0

  local loopFinished = false
  local loaderIndex = 0
  for _, bagID in ipairs(Auctionator.Groups.Constants.BagIDs) do
    for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
      local location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
      local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)

      if slotInfo then
        waitingCount = waitingCount + 1
        local item = Item:CreateFromItemID(slotInfo.itemID)

        local function FinishSlot()
          local entry = self:AddToCache(location, slotInfo)
          if entry then
            table.insert(entireBag, entry)
          end
          waitingCount = waitingCount - 1
          if loopFinished and waitingCount == 0 then
            self.loaders = {}
            self.waiting = false
            self:PostUpdate(entireBag)
          end
        end
        local li = loaderIndex + 1

        -- Load item data to determine whether it can be auctioned, its quality,
        -- item level, etc.
        if Auctionator.Groups.Constants.IsVanilla then
          local classID = select(6, C_Item.GetItemInfoInstant(slotInfo.itemID))
          local _, spellID = C_Item.GetItemSpell(slotInfo.itemID)
          -- Classic: Special case to load spell data for item charge info for
          -- auctionable check
          if classID == Enum.ItemClass.Consumable and spellID then
            local function LocalFinish()
              if not C_Item.IsItemDataCached(location) then
                local item = Item:CreateFromItemID(slotInfo.itemID)
                self.loaders[li] = item:ContinueWithCancelOnItemLoad(FinishSlot)
              elseif not C_Spell.IsSpellDataCached(spellID) then
                local spell = Spell:CreateFromSpellID(spellID)
                self.loaders[li] = spell:ContinueWithCancelOnSpellLoad(LocalFinish)
              else
                self.loaders[li] = nil
                FinishSlot()
              end
            end
            LocalFinish()
          elseif C_Item.IsItemDataCached(location) then
            FinishSlot()
          else
            self.loaders[li] = item:ContinueWithCancelOnItemLoad(FinishSlot)
          end
        -- We check for the item data being cached as its a significant time
        -- saving over waiting for the mixin to call back in that case.
        elseif C_Item.IsItemDataCached(location) then
          FinishSlot()
        else
          self.loaders[li] = item:ContinueWithCancelOnItemLoad(FinishSlot)
        end
      end
    end
  end
  loopFinished = true

  if waitingCount == 0 then
    self.loaders = {}
    self.waiting = false
    self:PostUpdate(entireBag)
  end
end

local detailsCache = {}

function AuctionatorBagCacheMixin:AddToCache(location, slotInfo)
  local entry = {}

  entry.itemID = slotInfo.itemID

  entry.location = location

  entry.iconTexture, entry.itemCount, entry.quality, entry.itemLink = slotInfo.iconFileID, slotInfo.stackCount, slotInfo.quality, slotInfo.hyperlink

  local savedDetails = detailsCache[entry.itemLink]
  if savedDetails ~= nil then
    entry.classID = savedDetails.classID
    entry.itemName = savedDetails.itemName
    entry.stackCount = savedDetails.stackCount
    entry.itemLevel = savedDetails.itemLevel
    entry.quality = savedDetails.quality
  else
    if entry.itemLink:match("battlepet:") then
      entry.classID = Enum.ItemClass.Battlepet
      entry.itemName = C_PetJournal.GetPetInfoBySpeciesID(tonumber(entry.itemLink:match("battlepet:(%d+)")))
      entry.stackCount = 1
    else
      local itemName, itemLink, quality, _, _, _, _, stackCount, _, _, _, classID, _ = C_Item.GetItemInfo(entry.itemLink)
      if itemName == nil then --mythic keystones don't have a normal item link
        return nil
      end
      entry.classID = classID
      entry.itemName = itemName
      entry.itemLink = itemLink
      entry.stackCount = stackCount
      entry.quality = quality
    end
    if Auctionator.Utilities.IsEquipment(entry.classID) then
      if Auctionator.Constants.IsRetail then
        entry.itemLevel = Auctionator.Groups.Utilities.ExtractItemLevel(entry.itemLink)
      else
        entry.itemLevel = C_Item.GetDetailedItemLevelInfo(entry.itemLink)
      end
    end
    detailsCache[entry.itemLink] = entry
  end

  if C_AuctionHouse == nil then -- Classic, check if the item can be auctioned
    local currentDurability, maxDurability
    if location:IsBagAndSlot() then
      currentDurability, maxDurability = C_Container.GetContainerItemDurability(location:GetBagAndSlot())
    else
      local slot = location:GetEquipmentSlot()
      currentDurability, maxDurability = GetInventoryItemDurability(slot)
    end

    entry.auctionable = not C_Item.IsBound(location) and currentDurability == maxDurability

    if entry.auctionable and entry.classID == Enum.ItemClass.Consumable and location:IsBagAndSlot() then
      entry.auctionable = Auctionator.Utilities.IsAtMaxCharges(location)
    end
  else
    entry.auctionable = C_AuctionHouse.IsSellItemValid(location, false)
  end

  entry.key = GetItemKey(entry)

  return entry
end
