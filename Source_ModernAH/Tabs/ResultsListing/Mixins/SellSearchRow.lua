AuctionatorSellSearchRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

local function BuyEntry(entry)
  Auctionator.EventBus
    :RegisterSource(BuyEntry, "BuyEntry")
    :Fire(BuyEntry, Auctionator.Selling.Events.ShowConfirmPurchase, entry)
    :UnregisterSource(BuyEntry)
end

function AuctionatorSellSearchRowMixin:OnEnter()
  if AuctionHouseUtil ~= nil then
    AuctionHouseUtil.LineOnEnterCallback(self, self.rowData)
  end
  AuctionatorResultsRowTemplateMixin.OnEnter(self)
end

function AuctionatorSellSearchRowMixin:OnLeave()
  if AuctionHouseUtil ~= nil then
    AuctionHouseUtil.LineOnLeaveCallback(self, self.rowData)
  end
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
end

function AuctionatorSellSearchRowMixin:OnClick(button, ...)
  Auctionator.Debug.Message("AuctionatorSellSearchRowMixin:OnClick()")

  if Auctionator.Utilities.IsShortcutActive(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_CANCEL_SHORTCUT), button) then
    if C_AuctionHouse.CanCancelAuction(self.rowData.auctionID) then
      Auctionator.EventBus
        :RegisterSource(self, "SellSearchRow")
        :Fire(self, Auctionator.Cancelling.Events.RequestCancel, self.rowData.auctionID)
        :UnregisterSource(self)
    end

  elseif Auctionator.Utilities.IsShortcutActive(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_BUY_SHORTCUT), button) then
    if self.rowData.canBuy then
      BuyEntry(self.rowData)
    end

  elseif IsModifiedClick("DRESSUP") then
    DressUpLink(self.rowData.itemLink);

  elseif IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.rowData.itemLink)

  else
    Auctionator.EventBus
      :RegisterSource(self, "SellSearchRow")
      :Fire(self, Auctionator.Selling.Events.PriceSelected, {buyout = self.rowData.price, bid = self.rowData.bidPrice}, true)
      :UnregisterSource(self)
  end
end
