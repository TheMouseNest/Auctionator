AuctionatorConfigShoppingAltFrameMixin = CreateFromMixins(AuctionatorConfigShoppingFrameMixin)

function AuctionatorConfigShoppingAltFrameMixin:ShowSettings()
  AuctionatorConfigShoppingFrameMixin.ShowSettings(self)

  self.AlwaysConfirmQuantity:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_ALWAYS_CONFIRM_COMMODITY_QUANTITY))
  self.SkipBuyConfirmationShortcut:SetValue(Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_SKIP_BUY_CONFIRMATION))
end

function AuctionatorConfigShoppingAltFrameMixin:Save()
  AuctionatorConfigShoppingFrameMixin.Save(self)

  Auctionator.Config.Set(Auctionator.Config.Options.SHOPPING_ALWAYS_CONFIRM_COMMODITY_QUANTITY, self.AlwaysConfirmQuantity:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SHOPPING_SKIP_BUY_CONFIRMATION, self.SkipBuyConfirmationShortcut:GetValue())
end
