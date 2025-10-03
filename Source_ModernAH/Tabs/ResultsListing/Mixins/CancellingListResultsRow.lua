AuctionatorCancellingListResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function AuctionatorCancellingListResultsRowMixin:OnClick(button, ...)
  Auctionator.Debug.Message("AuctionatorCancellingListResultsRowMixin:OnClick", self.rowData and self.rowData.id)

  if IsModifiedClick("DRESSUP") then
    DressUpLink(self.rowData.itemLink);

  elseif IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.rowData.itemLink)

  elseif button == "LeftButton" then
    Auctionator.EventBus
      :RegisterSource(self, "CancellingListResultRow")
      :Fire(self, Auctionator.Cancelling.Events.RequestCancel, self.rowData.id)
      :UnregisterSource(self)
  elseif button == "RightButton" then
    if Auctionator.Utilities.IsEquipment(select(6, C_Item.GetItemInfoInstant(self.rowData.itemKey.itemID))) and
       self.rowData.itemKey.itemLevel < Auctionator.Constants.ITEM_LEVEL_THRESHOLD then
      local item = Item:CreateFromItemID(self.rowData.itemKey.itemID)
      item:ContinueOnItemLoad(function()
        Auctionator.API.v1.MultiSearch(AUCTIONATOR_L_CANCELLING_TAB, { item:GetItemName() })
      end)
    else
      Auctionator.API.v1.MultiSearchExact(AUCTIONATOR_L_CANCELLING_TAB, { self.rowData.searchName })
    end
  end
end

function AuctionatorCancellingListResultsRowMixin:Populate(rowData, dataIndex)
  AuctionatorResultsRowTemplateMixin.Populate(self, rowData, dataIndex)

  self:ApplyFade()
  self:ApplyUndercutHighlight()
  self:ApplyBidderHighlight()
end

function AuctionatorCancellingListResultsRowMixin:ApplyFade()
  --Fade while waiting for the cancel to take effect
  if self.rowData.cancelled then
    self:SetAlpha(0.5)
  else
    self:SetAlpha(1)
  end
end

function AuctionatorCancellingListResultsRowMixin:ApplyUndercutHighlight()
  self.SelectedHighlight:SetShown(self.rowData.undercut == AUCTIONATOR_L_UNDERCUT_YES)
end

function AuctionatorCancellingListResultsRowMixin:ApplyBidderHighlight()
  self.BidderHighlight:SetShown(self.rowData.bidder ~= nil)
end
