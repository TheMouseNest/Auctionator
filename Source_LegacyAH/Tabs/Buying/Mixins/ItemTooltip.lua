AuctionatorBuyingItemTooltipMixin = {}

function AuctionatorBuyingItemTooltipMixin:OnLoad()
  Auctionator.EventBus:Register(self, {
    Auctionator.Buying.Events.ShowForShopping
  })
end

function AuctionatorBuyingItemTooltipMixin:OnEnter()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetHyperlink(self.itemLink)
  GameTooltip:Show()
end

function AuctionatorBuyingItemTooltipMixin:OnLeave()
  GameTooltip:Hide()
end

function AuctionatorBuyingItemTooltipMixin:OnMouseUp()
  if IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.itemLink)
  else
    if self.itemLink ~= nil then
      -- Search for item in the browse tab (so that someone can check the bid
      -- prices)
      if BrowseResetButton then
        -- BrowseResetButton doesn't exist on classic era
        BrowseResetButton:Click()
      end
      BrowseName:SetText(Auctionator.Utilities.GetNameFromLink(self.itemLink))
      AuctionFrameTab1:Click()
      AuctionFrameBrowse_Search()
    end
  end
end

function AuctionatorBuyingItemTooltipMixin:ReceiveEvent(eventName, eventData)
  self.itemLink = eventData.itemLink
  self.Icon:SetTexture(eventData.iconTexture)
  self.Text:SetText(eventData.itemName)
end
