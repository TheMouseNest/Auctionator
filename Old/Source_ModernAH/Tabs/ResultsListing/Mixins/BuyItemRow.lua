AuctionatorBuyItemRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function AuctionatorBuyItemRowMixin:OnEnter()
  if AuctionHouseUtil ~= nil then
    AuctionHouseUtil.LineOnEnterCallback(self, self.rowData)
  end
  AuctionatorResultsRowTemplateMixin.OnEnter(self)
end

function AuctionatorBuyItemRowMixin:Populate(rowData, ...)
  AuctionatorResultsRowTemplateMixin.Populate(self, rowData, ...)

  self.BidderHighlight:SetShown(rowData.bidder ~= nil and rowData.containsOwnerItem)
  self.OwnedHighlight:SetShown(rowData.bidder == nil and rowData.containsOwnerItem)
end

function AuctionatorBuyItemRowMixin:OnLeave()
  if AuctionHouseUtil ~= nil then
    AuctionHouseUtil.LineOnLeaveCallback(self, self.rowData)
  end
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
end

function AuctionatorBuyItemRowMixin:OnClick(button, ...)
  Auctionator.Debug.Message("AuctionatorBuyItemRowMixin:OnClick()")

  if Auctionator.Utilities.IsShortcutActive(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_CANCEL_SHORTCUT), button) then
    if C_AuctionHouse.CanCancelAuction(self.rowData.auctionID) then
      Auctionator.EventBus
        :RegisterSource(self, "BuyItemRow")
        :Fire(self, Auctionator.Cancelling.Events.RequestCancel, self.rowData.auctionID)
        :UnregisterSource(self)
    end

  elseif IsModifiedClick("DRESSUP") then
    DressUpLink(self.rowData.itemLink);

  elseif IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.rowData.itemLink)

  elseif self.rowData.canBuy then
    Auctionator.EventBus
      :RegisterSource(self, "BuyItemRow")
      :Fire(self, Auctionator.Buying.Events.ShowItemConfirmation, self.rowData)
      :UnregisterSource(self)
  end
end
