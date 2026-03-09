AuctionatorCraftingInfoProfessionsFrameMixin = {}

function AuctionatorCraftingInfoProfessionsFrameMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
  })
  self:UpdateSearchButton()

  self:SetupCustomQuantitySearch()

  local function Update()
    self:ShowIfRelevant()
    if self:IsVisible() then
      self:UpdateTotal()
    end
  end

  -- Defer one frame: recipe/transaction may not be ready when handlers fire
  local function UpdateDeferred()
    C_Timer.After(0, Update)
  end

  hooksecurefunc(self:GetParent(), "Init", UpdateDeferred)
  self:GetParent():RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, UpdateDeferred)
  self:GetParent():RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, UpdateDeferred)
  hooksecurefunc(self:GetParent(), "statsChangedHandler", UpdateDeferred)

  Auctionator.API.v1.RegisterForDBUpdate(AUCTIONATOR_L_REAGENT_SEARCH, function()
    if self:IsVisible() then
      self:UpdateTotal()
    end
  end)
end

function AuctionatorCraftingInfoProfessionsFrameMixin:SetupCustomQuantitySearch()
  ButtonFrameTemplate_HidePortrait(self.CustomQuantity)
  ButtonFrameTemplate_HideButtonBar(self.CustomQuantity)
  self.CustomQuantity.Inset:Hide()

  self.CustomQuantity:SetTitle(AUCTIONATOR_L_SEARCH_FOR_QUANTITY)

  self.CustomQuantity:SetScript("OnShow", function()
    self.CustomQuantity.Quantity:SetFocus()
    Auctionator.EventBus:Register(self.CustomQuantity, {Auctionator.Components.Events.EnterPressed})
  end)
  self.CustomQuantity:SetScript("OnHide", function()
    Auctionator.EventBus:Unregister(self.CustomQuantity, {Auctionator.Components.Events.EnterPressed})
  end)

  self.CustomQuantity.ReceiveEvent = function(_, eventName, ...)
    self.CustomQuantity.SearchButton:Click()
  end
end

function AuctionatorCraftingInfoProfessionsFrameMixin:SetDoNotShowProfit()
  self.doNotShowProfit = true
end

function AuctionatorCraftingInfoProfessionsFrameMixin:ShowIfRelevant()
  self:SetShown(Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW) and self:GetParent():GetRecipeInfo() ~= nil and self:IsAnyReagents())

  if self:IsVisible() then
    self:ClearAllPoints()

    local reagents = self:GetParent().Reagents
    local framesToBeBelow = {
      self:GetParent().OptionalReagents,
    }
    for _, f in ipairs(self:GetParent().extraSlotFrames) do
      table.insert(framesToBeBelow, f)
    end
    local min = reagents
    for _, f in ipairs(framesToBeBelow) do
      if f:IsShown() and f:GetBottom() < min:GetBottom() then
        min = f
      end
    end

    self:SetPoint("LEFT", reagents, "LEFT", 0, -10)

    self:SetPoint("TOP", min, "BOTTOM", 0, -5)

    self:UpdateSearchButton()
  end
end

function AuctionatorCraftingInfoProfessionsFrameMixin:UpdateSearchButton()
  self.SearchButton:SetShown(AuctionHouseFrame and AuctionHouseFrame:IsShown())
  self.CustomQuantity:Hide()
end

-- Checks for case when there are no regeants, for example a DK Runeforging
-- crafting view.
function AuctionatorCraftingInfoProfessionsFrameMixin:IsAnyReagents()
  local schematicForm = self:GetParent()
  local recipeInfo = schematicForm:GetRecipeInfo()
  local recipeID = recipeInfo.recipeID
  local recipeLevel = schematicForm:GetCurrentRecipeLevel()
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)
  return #recipeSchematic.reagentSlotSchematics > 0
end

function AuctionatorCraftingInfoProfessionsFrameMixin:UpdateTotal()
  local text, lines = Auctionator.CraftingInfo.GetInfoText(self:GetParent(), not self.doNotShowProfit)
  self.Total:SetText(text)
  if lines == 0 then
    self:SetHeight(16)
  else
    self:SetHeight(16 * lines)
  end
end

function AuctionatorCraftingInfoProfessionsFrameMixin:SearchButtonClicked(button)
  if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
    if button == "RightButton" then
      self.CustomQuantity:Show()
    else
      Auctionator.CraftingInfo.DoTradeSkillReagentsSearch(self:GetParent(), 1)
    end
  end
end

function AuctionatorCraftingInfoProfessionsFrameMixin:QuantitySearchButtonClicked(quantity)
  if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
    Auctionator.CraftingInfo.DoTradeSkillReagentsSearch(self:GetParent(), math.max(quantity, 1))
  end
  self.CustomQuantity:Hide()
end

function AuctionatorCraftingInfoProfessionsFrameMixin:OnEvent(...)
  local eventName, paneType = ...
  if paneType == Enum.PlayerInteractionType.Auctioneer then
    self:UpdateSearchButton()
  end
end
