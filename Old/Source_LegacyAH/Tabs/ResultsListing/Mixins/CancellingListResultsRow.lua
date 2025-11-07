AuctionatorCancellingListResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function AuctionatorCancellingListResultsRowMixin:OnClick(button, ...)
  Auctionator.Debug.Message("AuctionatorCancellingListResultsRowMixin:OnClick", self.rowData and self.rowData.id)

  if IsModifiedClick("DRESSUP") then
    DressUpLink(self.rowData.itemLink);

  elseif IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.rowData.itemLink)

  elseif button == "LeftButton" and Auctionator.AH.IsNotThrottled() then
    self.rowData.cancelled = true
    self:ApplyFade()

    Auctionator.EventBus
      :RegisterSource(self, "CancellingListResultRow")
      :Fire(self, Auctionator.Cancelling.Events.RequestCancel, self.rowData)
      :UnregisterSource(self)
  elseif button == "RightButton" then
    Auctionator.API.v1.MultiSearchExact(AUCTIONATOR_L_CANCELLING_TAB, { Auctionator.Utilities.GetNameFromLink(self.rowData.itemLink) })
  end
end

function AuctionatorCancellingListResultsRowMixin:OnEnter()
  if Auctionator.AH.IsNotThrottled() then
    AuctionatorResultsRowTemplateMixin.OnEnter(self)
  end
end

function AuctionatorCancellingListResultsRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
end

function AuctionatorCancellingListResultsRowMixin:Populate(rowData, dataIndex)
  AuctionatorResultsRowTemplateMixin.Populate(self, rowData, dataIndex)

  self:ApplyFade()
  self:ApplyUndercutHighlight()
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
