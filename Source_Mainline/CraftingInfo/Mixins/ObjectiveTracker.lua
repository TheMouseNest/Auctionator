AuctionatorCraftingInfoObjectiveTrackerFrameMixin = {}

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "TRACKED_RECIPE_UPDATE",
  })
  self:ShowIfRelevant()

  local function Update()
    self:ShowIfRelevant()
    if self:IsVisible() then
      self:UpdateTotal()
    end
  end
end

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:SetDoNotShowProfit()
  self.doNotShowProfit = true
end

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:ShowIfRelevant()
  self:SetShown(Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW) and self:IsAnythingTracked())
  if self:IsShown() then
    self:UpdateSearchButton()
  end
end

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:UpdateSearchButton()
  self.SearchButton:SetShown(AuctionHouseFrame and AuctionHouseFrame:IsShown())
end

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:IsAnythingTracked()
  return #C_TradeSkillUI.GetRecipesTracked(true) > 0 or #C_TradeSkillUI.GetRecipesTracked(false) > 0
end

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:SearchButtonClicked()
  Auctionator.CraftingInfo.DoTrackedRecipesSearch()
end

function AuctionatorCraftingInfoObjectiveTrackerFrameMixin:OnEvent(eventName, eventData)
  if eventName == "TRACKED_RECIPE_UPDATE" then
    self:ShowIfRelevant()
  elseif eventData == Enum.PlayerInteractionType.Auctioneer then
    self:UpdateSearchButton()
  end
end
