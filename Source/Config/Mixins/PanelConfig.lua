AuctionatorPanelConfigMixin = {}

function AuctionatorPanelConfigMixin:SetupPanel()
  self.cancel = function()
    self:Cancel()
  end

  self.okay = function()
    if self.shownSettings then
      self:Save()
    end
  end

  self.shownSettings =  false

  self.OnCommit = self.okay
  self.OnDefault = function() end
  self.OnRefresh = function() end

  if self.parent == nil then
    local category = Settings.RegisterCanvasLayoutCategory(self, self.name)
    Settings.RegisterAddOnCategory(category)
    Auctionator.State.OptionsCategory = category
  else
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(Auctionator.State.OptionsCategory, self, self.name)
    Settings.RegisterAddOnCategory(subcategory)
  end
end

function AuctionatorPanelConfigMixin:OnShow()
  self:ShowSettings()
  self.shownSettings = true
end

-- Derive
function AuctionatorPanelConfigMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorPanelConfigMixin:Cancel() Unimplemented")
end

-- Derive
function AuctionatorPanelConfigMixin:Save()
  Auctionator.Debug.Message("AuctionatorPanelConfigMixin:Save() Unimplemented")
end
