AuctionatorBuyItemDialogMixin = {}

function AuctionatorBuyItemDialogMixin:OnLoad()
  Auctionator.EventBus:Register(self, {
    Auctionator.Buying.Events.ShowItemConfirmation,
  })
end

function AuctionatorBuyItemDialogMixin:Reset()
  self.auctionID = nil
  self.price = nil
end

function AuctionatorBuyItemDialogMixin:ReceiveEvent(eventName, rowData, skipConfirmation)
  self.PurchaseDetails:SetText(AUCTIONATOR_L_PAYING_X:format(GetMoneyString(rowData.price, true)))
  self.price = rowData.price
  self.auctionID = rowData.auctionID

  if skipConfirmation then
    self:BuyClicked()
    return
  end

  if rowData.itemLink:match("battlepet") then
    local speciesID, _, breedQuality = BattlePetToolTip_UnpackBattlePetLink(rowData.itemLink)
    local name, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    name= ITEM_QUALITY_COLORS[breedQuality].color:WrapTextInColorCode(name)
    self.IconAndName:SetItem(nil, rowData.itemLink, breedQuality, name, icon)
    self:Show()
  else
    local item = Item:CreateFromItemLink(rowData.itemLink)
    item:ContinueOnItemLoad(function()
      local name, _, quality = C_Item.GetItemInfo(rowData.itemLink)
      local icon = select(10, C_Item.GetItemInfo(rowData.itemLink))
      self.IconAndName:SetItem(nil, rowData.itemLink, quality, name, icon)
      self:Show()
    end)
  end
end

function AuctionatorBuyItemDialogMixin:BuyClicked()
  if self.auctionID and self.price then
    C_AuctionHouse.PlaceBid(self.auctionID, self.price)
  end
  self:Hide()
  self:Reset()
end

function AuctionatorBuyItemDialogMixin:OnHide()
  self:Hide()
  self:Reset()
end
