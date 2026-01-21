AuctionatorItemKeyLoadingMixin = {}

function AuctionatorItemKeyLoadingMixin:OnLoad()
  Auctionator.EventBus:Register(self, {Auctionator.AH.Events.ItemKeyInfo})

  self:SetOnEntryProcessedCallback(function(entry)
    Auctionator.AH.GetItemKeyInfo(entry.itemKey, function(itemKeyInfo, wasCached)
      self:ProcessItemKey(entry, itemKeyInfo)
      if wasCached then
        self:NotifyCacheUsed()
      end
    end)
  end)
end

function AuctionatorItemKeyLoadingMixin:ProcessItemKey(rowEntry, itemKeyInfo)
  local text = AuctionHouseUtil.GetItemDisplayTextFromItemKey(
    rowEntry.itemKey,
    itemKeyInfo,
    false
  )
  local icon
  if C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
    local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(rowEntry.itemKey.itemID)
    if quality then
      icon = Auctionator.Utilities.GetCraftingQualityMarkup(quality)
    end
  end
  if icon then
    text = text .. " " .. icon
  end

  rowEntry.itemName = text
  rowEntry.plainItemName = itemKeyInfo.itemName
  rowEntry.name = Auctionator.Utilities.RemoveTextColor(text):gsub("|A.-Tier(%d).-|a", AUCTIONATOR_L_TIER .. " %1")
  rowEntry.iconTexture = itemKeyInfo.iconFileID
  rowEntry.noneAvailable = rowEntry.totalQuantity == 0

  self:SetDirty()
end
