local SALE_ITEM_EVENTS = {
  Auctionator.AH.Events.CommoditySearchResultsReady,
  Auctionator.AH.Events.ItemSearchResultsReady,
}

-- Necessary because attempting to post an auction with copper value silently
-- fails
local function NormalizePrice(price)
  local normalizedPrice = price

  if Auctionator.Constants.IsRetail then
    -- Round up
    if normalizedPrice % 100 ~= 0 then
      normalizedPrice = normalizedPrice + (100 - normalizedPrice % 100)
    end

    -- Need to have a price of at least one silver (retail) or one copper (cata)
    if normalizedPrice < 100 then
      normalizedPrice = 100
    end
  elseif normalizedPrice < 1 then
    normalizedPrice = 1
  end

  return normalizedPrice
end

local function IsEquipment(itemInfo)
  -- Commodity check because some items like Secret Sauce are set to the wrong item class
  return not itemInfo.isCommodity and Auctionator.Utilities.IsEquipment(itemInfo.classId)
end

local function IsValidItem(item)
  return item ~= nil and
    -- May be a favourite with no items available, ignore it.
    item.location ~= nil and
    -- Location may be invalid because of items being moved in the bag
    C_Item.DoesItemExist(item.location)
end

AuctionatorSaleItemMixin = {}

function AuctionatorSaleItemMixin:OnLoad()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    self.BidPrice:Show()
  end
end

function AuctionatorSaleItemMixin:OnShow()
  Auctionator.EventBus:Register(self, {
    Auctionator.Selling.Events.BagItemClicked,
    Auctionator.Selling.Events.ClearBagItem,
    Auctionator.Selling.Events.RequestPost,
    Auctionator.Selling.Events.ConfirmPost,
    Auctionator.Selling.Events.SkipItem,
    Auctionator.AH.Events.ThrottleUpdate,
    Auctionator.Selling.Events.PriceSelected,
    Auctionator.Selling.Events.RefreshSearch,
    Auctionator.Components.Events.EnterPressed,
  })
  Auctionator.EventBus:RegisterSource(self, "AuctionatorSaleItemMixin")

  local function SetupBindings()
    if self:IsVisible() then
      SetOverrideBinding(self, false, Auctionator.Config.Get(Auctionator.Config.Options.SELLING_POST_SHORTCUT), "CLICK AuctionatorPostButton:LeftButton")
      SetOverrideBinding(self, false, Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SKIP_SHORTCUT), "CLICK AuctionatorSkipPostingButton:LeftButton")
      SetOverrideBinding(self, false, Auctionator.Config.Get(Auctionator.Config.Options.SELLING_PREV_SHORTCUT), "CLICK AuctionatorPrevPostingButton:LeftButton")
    end
  end
  if InCombatLockdown() then
    EventUtil.ContinueAfterAllEvents(SetupBindings, "PLAYER_REGEN_ENABLED")
  else
    SetupBindings()
  end

  self.lastItemInfo = nil
  self.nextItem = nil
  self.prevItem = nil

  self:UpdateSkipButton()
  self:Reset()

  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SHOULD_RESELECT_ITEM) then
    local key = Auctionator.Config.Get(Auctionator.Config.Options.SELLING_RESELECT_ITEM)
    if key ~= nil then
      Auctionator.EventBus:Fire(
        self, Auctionator.Selling.Events.BagItemRequest, key
      )
    end
  end
end

function AuctionatorSaleItemMixin:OnHide()
  Auctionator.EventBus:Unregister(self, {
    Auctionator.Selling.Events.BagItemClicked,
    Auctionator.Selling.Events.ClearBagItem,
    Auctionator.Selling.Events.RequestPost,
    Auctionator.Selling.Events.ConfirmPost,
    Auctionator.Selling.Events.SkipItem,
    Auctionator.AH.Events.ThrottleUpdate,
    Auctionator.Selling.Events.PriceSelected,
    Auctionator.Selling.Events.RefreshSearch,
    Auctionator.Components.Events.EnterPressed,
  })
  if self.saleItemEventsRegistered then
    Auctionator.EventBus:Unregister(self, SALE_ITEM_EVENTS)
  end
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_RESELECT_ITEM, self.lastKey)
  Auctionator.EventBus:UnregisterSource(self)
  self:UnlockItem()

  if InCombatLockdown() then
    EventUtil.ContinueAfterAllEvents(function() ClearOverrideBindings(self) end, "PLAYER_REGEN_ENABLED")
  else
    ClearOverrideBindings(self)
  end
end

function AuctionatorSaleItemMixin:UpdateSkipButton()
  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT) then
    self.PostButton:SetSize(114, 22)
    self.SkipButton:Show()
  else
    self.PostButton:SetSize(194, 22)
    self.SkipButton:Hide()
  end
end

function AuctionatorSaleItemMixin:UnlockItem()
  if self.itemInfo ~= nil then
    --Existence check added because of a bug report from a user where (for an
    --unknown reason) the item no longer existed.
    if IsValidItem(self.itemInfo) then
      C_Item.UnlockItem(self.itemInfo.location)
    end
    self.itemInfo = nil
  end
end

function AuctionatorSaleItemMixin:LockItem()
  if IsValidItem(self.itemInfo) then
    C_Item.LockItem(self.itemInfo.location)
  end
end

function AuctionatorSaleItemMixin:OnUpdate()
  if self.itemInfo == nil then
    return

  elseif self.itemInfo.count == 0 then
    return

  elseif not C_Item.DoesItemExist(self.itemInfo.location) then
    --Bag item location invalid due to posting (race condition)
    self.itemInfo = nil
    self:Reset()
    return
  end

  self.TotalPrice:SetText(
    GetMoneyString(self.Quantity:GetNumber() * self.Price:GetAmount(), true)
  )

  if self.Quantity:GetNumber() > self:GetPostLimit() then
    self:SetMax()
  end

  self.MaxButton:SetEnabled(self.Quantity:GetNumber() ~= self:GetPostLimit())

  self.DepositPrice:SetText(GetMoneyString(self:GetDeposit(), true))
  self:UpdatePostButtonState()
  self:UpdateSkipButtonState()
end

function AuctionatorSaleItemMixin:GetPostLimit()
  return math.min(C_AuctionHouse.GetAvailablePostCount(self.itemInfo.location), self.itemInfo.count)
end
function AuctionatorSaleItemMixin:SetMax()
  self.Quantity:SetNumber(self:GetPostLimit())
end

function AuctionatorSaleItemMixin:GetDeposit()
  local deposit = 0

  if C_AuctionHouse.GetItemCommodityStatus(self.itemInfo.location) == Enum.ItemCommodityStatus.Commodity then
    deposit = C_AuctionHouse.CalculateCommodityDeposit(
      self.itemInfo.itemID,
      self:GetDuration(),
      self.Quantity:GetNumber()
    ) or deposit

  else
    deposit = C_AuctionHouse.CalculateItemDeposit(
      self.itemInfo.location,
      self:GetDuration(),
      self.Quantity:GetNumber()
    ) or deposit
  end

  return NormalizePrice(deposit)
end

function AuctionatorSaleItemMixin:ReceiveEvent(event, ...)
  if event == Auctionator.Selling.Events.BagItemClicked then
    self:UnlockItem()
    local itemInfo = ...
    Auctionator.AH.GetItemKeyInfo(C_AuctionHouse.MakeItemKey(itemInfo.itemID), function(itemKeyInfo)
      self.itemInfo = itemInfo
      self.itemInfo.isCommodity = itemKeyInfo.isCommodity
      self.nextItem = self.itemInfo and self.itemInfo.nextItem
      self.prevItem = self.itemInfo and self.itemInfo.prevItem
      self.lastKey = self.itemInfo and self.itemInfo.key
      self:LockItem()
      self:Update()
    end)

  elseif event == Auctionator.Selling.Events.ClearBagItem then
    self.nextItem = nil
    self.prevItem = nil
    self.lastKey = nil
    self:Reset()

  elseif event == Auctionator.AH.Events.ThrottleUpdate then
    self:UpdatePostButtonState()

  elseif event == Auctionator.Selling.Events.RequestPost then
    self:PostItem()

  elseif event == Auctionator.Selling.Events.ConfirmPost then
    self:PostItem(true)

  elseif event == Auctionator.Selling.Events.SkipItem then
    self:SkipItem()

  elseif event == Auctionator.Components.Events.EnterPressed then
    self:PostItem()

  elseif event == Auctionator.Selling.Events.PriceSelected and
         self.itemInfo ~= nil then
    local selectedPrices, shouldUndercut = ...
    local buyoutAmount = selectedPrices.buyout or selectedPrices.bid

    if shouldUndercut then
      buyoutAmount = Auctionator.Selling.CalculateItemPriceFromPrice(buyoutAmount)
    end

    if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
      self:UpdateSalesPrice(buyoutAmount, selectedPrices.bid, true)
    else
      self:UpdateSalesPrice(buyoutAmount)
    end

  elseif event == Auctionator.Selling.Events.RefreshSearch then
    self:RefreshButtonClicked()

  elseif event == Auctionator.AH.Events.CommoditySearchResultsReady then
    local itemID = ...
    if itemID ~= self.expectedItemKey.itemID then
      return
    end

    self:ProcessCommodityResults(...)
    self.saleItemEventsRegistered = false
    Auctionator.EventBus:Unregister(self, SALE_ITEM_EVENTS)

  elseif event == Auctionator.AH.Events.ItemSearchResultsReady then
    local itemKey = ...
    if Auctionator.Utilities.ItemKeyString(itemKey) ~=
        Auctionator.Utilities.ItemKeyString(self.expectedItemKey) then
      return
    end

    local item = Item:CreateFromItemID(itemKey.itemID)
    item:ContinueOnItemLoad(function()
      self:ProcessItemResults(itemKey)
    end)
    self.saleItemEventsRegistered = false
    Auctionator.EventBus:Unregister(self, SALE_ITEM_EVENTS)
  end
end

function AuctionatorSaleItemMixin:Update()
  self:UpdateVisuals()

  if self.itemInfo ~= nil then
    self:UpdateForNewItem()
  else
    self:UpdateForNoItem()
  end

  self:UpdatePostButtonState()
  self:UpdateSkipButtonState()

end

function AuctionatorSaleItemMixin:UpdateVisuals()
  self.Icon:SetItemInfo(self.itemInfo)

  if self.itemInfo ~= nil then
    self:SetItemName()


    -- Fade the (optionally visible) bid price if posting a commodity
    if self.itemInfo.isCommodity then
      self.BidPrice:SetAlpha(0.5)
    else
      self.BidPrice:SetAlpha(1)
    end

  else
    -- No item, reset all the visuals
    self.TitleArea.Text:SetText("")
  end
end

-- The exact item name is only loaded when needed as it slows down loading the
-- bag items too much to do in BagDataProvider.
function AuctionatorSaleItemMixin:SetItemName()
  local reagentQuality
  if Auctionator.Constants.IsRetail then
    reagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(self.itemInfo.itemID)
  end
  local itemName = self.itemInfo.itemName
  if reagentQuality then
    itemName = itemName .. " " .. C_Texture.GetCraftingReagentQualityChatIcon(reagentQuality)
  elseif self.itemInfo.itemLevel then
    itemName = AUCTIONATOR_L_ITEM_NAME_X_ITEM_LEVEL_X:format(itemName, self.itemInfo.itemLevel)
  elseif self.itemInfo.itemLink:find("battlepet", nil, true) then
    itemName = AUCTIONATOR_L_ITEM_NAME_X_ITEM_LEVEL_X:format(itemName, Auctionator.Utilities.GetPetLevelFromLink(self.itemInfo.itemLink))
  end
  itemName = ITEM_QUALITY_COLORS[self.itemInfo.quality].color:WrapTextInColorCode(itemName)
  self.TitleArea.Text:SetText(itemName)
end

function AuctionatorSaleItemMixin:UpdateForNewItem()
  self:SetDuration()

  self.MaxButton:Disable() -- Disable needed for case quantity is 0

  self:SetQuantity()

  Auctionator.Utilities.DBKeyFromLink(self.itemInfo.itemLink, function(dbKeys)
    local price = Auctionator.Database:GetFirstPrice(dbKeys)

    if price ~= nil then
      self:UpdateSalesPrice(price)
    elseif IsEquipment(self.itemInfo) then
      self:SetEquipmentMultiplier(self.itemInfo.itemLink)
    else
      self:UpdateSalesPrice(0)
    end
  end)

  self:DoSearch(self.itemInfo)
end

function AuctionatorSaleItemMixin:UpdateForNoItem()
  self.Quantity:SetNumber(0)
  self.MaxButton:Disable()
  self:UpdateSalesPrice(0)

  self.DepositPrice:SetText(GetMoneyString(100, true))
  self.TotalPrice:SetText(GetMoneyString(100, true))
end

local DURATIONS_TO_TIME = {
  [1] = 12,
  [2] = 24,
  [3] = 48,
}
function AuctionatorSaleItemMixin:SetDuration()
  local duration = Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_DURATION)

  self.Duration:SetSelectedValue(duration)
end

function AuctionatorSaleItemMixin:SetQuantity()
  local defaultQuantity = Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_QUANTITIES)[self.itemInfo.classId]

  if self.itemInfo.count == 0 then
    self.Quantity:SetNumber(0)
  elseif defaultQuantity ~= nil and defaultQuantity > 0 then
    -- If a default quantity has been selected (ie non-zero amount)
    self.Quantity:SetNumber(math.min(self.itemInfo.count, defaultQuantity, self:GetPostLimit()))
  else
    -- No default quantity setting, use the maximum possible
    self:SetMax()
  end
end

function AuctionatorSaleItemMixin:DoSearch(itemInfo, ...)
  Auctionator.EventBus:Register(self, SALE_ITEM_EVENTS)
  self.saleItemEventsRegistered = true

  local sortingOrder

  if itemInfo.isCommodity then
    sortingOrder = Auctionator.Constants.CommodityResultsSorts
  else
    sortingOrder = Auctionator.Constants.ItemResultsSorts
  end

  if IsEquipment(itemInfo) then
    self.expectedItemKey = {itemID = itemInfo.itemID, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0}
    Auctionator.AH.SendSellSearchQueryByItemKey(self.expectedItemKey, {sortingOrder}, true)
  else
    local battlePetID = itemInfo.itemLink:match("battlepet:(%d+)")

    if battlePetID then
      self.expectedItemKey = C_AuctionHouse.MakeItemKey(itemInfo.itemID, nil, nil, tonumber(battlePetID))
    else
      self.expectedItemKey = C_AuctionHouse.MakeItemKey(itemInfo.itemID)
    end
    Auctionator.AH.SendSearchQueryByItemKey(self.expectedItemKey, {sortingOrder}, true)
  end
  Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.SellSearchStart, self.expectedItemKey, itemInfo.itemLink)
end

function AuctionatorSaleItemMixin:Reset()
  self:UnlockItem()

  self:Update()
end

function AuctionatorSaleItemMixin:UpdateSalesPrice(salesPrice, bidPrice, preserveBidPrice)
  if salesPrice == 0 then
    self.Price:SetAmount(0)
  else
    self.Price:SetAmount(NormalizePrice(salesPrice))
  end
  if bidPrice == nil then
    -- Carry over the bid price from a previously selected row unless its higher
    -- than the unit price chosen
    if not preserveBidPrice or self.BidPrice:GetAmount() >= self.Price:GetAmount() then
      self.BidPrice:Clear()
    end
  else
    self.BidPrice:SetAmount(bidPrice)
  end
end

function AuctionatorSaleItemMixin:SetEquipmentMultiplier(itemLink)
  self:UpdateSalesPrice(0)

  local item = Item:CreateFromItemLink(itemLink)
  item:ContinueOnItemLoad(function()
    local multiplier = Auctionator.Config.Get(Auctionator.Config.Options.GEAR_PRICE_MULTIPLIER)
    local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, C_Item.GetItemInfo(itemLink))
    if multiplier ~= 0 and vendorPrice ~= 0 then
      -- Check for a vendor price multiplier being set (and a vendor price)
      self:UpdateSalesPrice(
        vendorPrice * multiplier + self:GetDeposit()
      )
    end
  end)
end

function AuctionatorSaleItemMixin:OnEvent(eventName, ...)
end

function AuctionatorSaleItemMixin:GetCommodityResult(itemID)
  if C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) > 0 then
    return C_AuctionHouse.GetCommoditySearchResultInfo(itemID, 1)
  else
    return nil
  end
end

-- Identifies when an auction is skewing the current price down and is probably
-- not meant to be so low.
function AuctionatorSaleItemMixin:GetCommodityThreshold(itemID)
  local amount = 0
  -- Scan half the auctions, of the first 500, whichever is fewer
  local target = math.min(5000, math.floor(C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) * 0.2))
  for index = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
    local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)

    amount = amount + result.quantity

    if amount >= target then
      return Auctionator.Utilities.PriceWarningThreshold(result.unitPrice)
    end
  end

  return nil
end

function AuctionatorSaleItemMixin:ProcessCommodityResults(itemID, ...)
  Auctionator.Debug.Message("AuctionatorSaleItemMixin:ProcessCommodityResults()")

  local dbKeys = Auctionator.Utilities.DBKeyFromBrowseResult({ itemKey = C_AuctionHouse.MakeItemKey(itemID) })

  local result = self:GetCommodityResult(itemID)
  -- Update DB with current lowest price
  if result ~= nil then
    for _, key in ipairs(dbKeys) do
      Auctionator.Database:SetPrice(key, result.unitPrice)
    end
  end
  if self.itemInfo ~= nil then
    self.itemInfo.existingValue = result and result.unitPrice
  end

  self.priceThreshold = self:GetCommodityThreshold(itemID)

  if result == nil then
    return
  end

  -- A few cases to process here:
  -- 1. If the entry containsOwnerItem=true, I should use this price as my
  -- calculated posting price (i.e. I do not want to undercut myself)
  -- 2. Otherwise, this entry is what to base my calculation on:
  --    a. Undercut by percentage (player can choose 0% to become first item chosen via LIFO)
  --    b. Undercut by static value
  local postingPrice = nil

  if result.containsOwnerItem and result.owners[1] == "player" then
    -- No need to undercut myself
    postingPrice = result.unitPrice
  else
    -- Otherwise, we're not the lowest price, so calculate based on user preferences
    postingPrice = Auctionator.Selling.CalculateItemPriceFromPrice(result.unitPrice)
  end

  -- Didn't find anything currently posted, and nothing in DB
  if postingPrice == nil then
    Auctionator.Debug.Message("No prices have been recorded for this item.")
    return
  end

  self:UpdateSalesPrice(postingPrice)
end

function AuctionatorSaleItemMixin:GetItemResult(itemKey)
  local itemInfo = self.itemInfo or self.lastItemInfo
  for i = 1, C_AuctionHouse.GetItemSearchResultsQuantity(itemKey) do
    local resultInfo = C_AuctionHouse.GetItemSearchResultInfo(itemKey, i)
    if Auctionator.Selling.DoesItemMatchFromLink(itemInfo.itemLink, resultInfo.itemKey, resultInfo.itemLink) then
      return resultInfo
    end
  end
  return nil
end

function AuctionatorSaleItemMixin:ProcessItemResults(itemKey)
  Auctionator.Debug.Message("AuctionatorSaleItemMixin:ProcessItemResults()")

  -- Update DB with current lowest price (accomodating for itemKey variations
  -- from the searched for itemKey)
  if C_AuctionHouse.GetNumItemSearchResults(itemKey) > 0 then
    local result = C_AuctionHouse.GetItemSearchResultInfo(itemKey, 1)
    local dbKeys = Auctionator.Utilities.DBKeyFromBrowseResult({ itemKey = result.itemKey })
    for _, key in ipairs(dbKeys) do
      Auctionator.Database:SetPrice(key, result.buyoutAmount or result.bidAmount)
    end
  end

  -- Get the first result that matches the price matching requirements
  local result = self:GetItemResult(itemKey)

  if self.itemInfo ~= nil then
    self.itemInfo.existingValue = result and (result.buyoutAmount or result.bidAmount)
  end

  self.priceThreshold = nil

  local postingPrice = nil

  if result == nil then
    return
  end

  if result.containsOwnerItem then
    -- Posting an item I have alread posted, and that is the current lowest price, so just
    -- use this price
    postingPrice = result.buyoutAmount
  else
    postingPrice = Auctionator.Selling.CalculateItemPriceFromPrice(result.buyoutAmount or result.bidAmount)
  end

  -- Didn't find anything currently posted, and nothing in DB
  if postingPrice == nil then
    Auctionator.Debug.Message("Lowest price not found.")
    return
  end

  self:UpdateSalesPrice(postingPrice)
end

function AuctionatorSaleItemMixin:GetPostButtonState()
  return
    self.itemInfo ~= nil and
    self.itemInfo.count > 0 and

    C_Item.DoesItemExist(self.itemInfo.location) and

    -- Sufficient money to cover deposit
    GetMoney() >= self:GetDeposit() and

    -- Valid quantity
    self.Quantity:GetNumber() > 0 and
    self.Quantity:GetNumber() <= self:GetPostLimit() and

    (
      (
      -- Normal pricing
        -- Positive price
        self.Price:GetAmount() > 0 and

        -- Bid price is not bigger than buyout
        self.BidPrice:GetAmount() < self.Price:GetAmount()
      ) or (
      -- Bid only with no buyout price
        Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) and
        -- Only items can have a bid amount
        self.itemInfo.itemType == Auctionator.Constants.ITEM_TYPES.ITEM and
        -- Only items can have a bid amount
        self.Price:GetAmount() == 0 and
        self.BidPrice:GetAmount() > 0
      )
    ) and

    -- Not throttled (to avoid silent post failure)
    Auctionator.AH.IsNotThrottled()
end

function AuctionatorSaleItemMixin:GetConfirmationMessage()
  local effectiveUnitPrice = self.Price:GetAmount()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) and effectiveUnitPrice == 0 then
    effectiveUnitPrice = self.BidPrice:GetAmount()
  end

  -- Check if the item was underpriced compared to the currently on sale items
  if self.priceThreshold ~= nil and self.priceThreshold >= effectiveUnitPrice then
    return AUCTIONATOR_L_CONFIRM_POST_LOW_PRICE:format(GetMoneyString(effectiveUnitPrice, true))
  end

  -- Determine if the item is worth more to sell to a vendor than to post on the
  -- AH.
  local itemInfo = { C_Item.GetItemInfo(self.itemInfo.itemLink) }
  local vendorPrice = itemInfo[Auctionator.Constants.ITEM_INFO.SELL_PRICE]
  if Auctionator.Utilities.IsVendorable(itemInfo) and
     vendorPrice * self.Quantity:GetNumber()
       > math.floor(effectiveUnitPrice * self.Quantity:GetNumber() * Auctionator.Constants.AfterAHCut) then
    return AUCTIONATOR_L_CONFIRM_POST_BELOW_VENDOR
  end
end

function AuctionatorSaleItemMixin:RequiresConfirmationState()
  return
    Auctionator.Config.Get(Auctionator.Config.Options.SELLING_CONFIRM_LOW_PRICE) and
    self:GetConfirmationMessage() ~= nil
end

function AuctionatorSaleItemMixin:UpdatePostButtonState()
  if self:GetPostButtonState() then
    self.PostButton:Enable()
  else
    self.PostButton:Disable()
  end
end

function AuctionatorSaleItemMixin:UpdateSkipButtonState()
  self.SkipButton:SetEnabled(self.SkipButton:IsShown() and self.nextItem)
  self.PrevButton:SetEnabled(self.SkipButton:IsShown() and self.prevItem)
end

local AUCTION_DURATIONS = {
  [12] = 1,
  [24] = 2,
  [48] = 3,
}

function AuctionatorSaleItemMixin:GetDuration()
  return AUCTION_DURATIONS[self.Duration:GetValue()]
end

function AuctionatorSaleItemMixin:PostItem(confirmed)
  if not self:GetPostButtonState() then
    Auctionator.Debug.Message("Trying to post when we can't. Returning")
    return
  elseif not confirmed and self:RequiresConfirmationState() then
    if self.SkipButton:IsEnabled() then
      Auctionator.Dialogs.ShowConfirmAlt(self:GetConfirmationMessage(), ACCEPT, AUCTIONATOR_L_SKIP, CANCEL, function()
        Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.ConfirmPost)
      end, function()
        Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.SkipItem)
      end)
    else
      Auctionator.Dialogs.ShowConfirm(self:GetConfirmationMessage(), ACCEPT, CANCEL, function()
        Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.ConfirmPost)
      end)
    end
    return
  end

  local quantity = self.Quantity:GetNumber()
  local duration = self:GetDuration()
  local startingBid = self.BidPrice:GetAmount()
  local buyout = self.Price:GetAmount()
  local bidAmountReported = nil -- Only includes bid price when non-zero and for an item

  self.MultisellProgress:SetDetails(self.itemInfo.iconTexture, quantity)

  if not self.itemInfo.isCommodity then
    local params = nil
    if startingBid ~= 0 then
      bidAmountReported = startingBid
      params = {self.itemInfo.location, duration, quantity, startingBid, buyout ~= 0 and buyout or nil}
    else
      params = {self.itemInfo.location, duration, quantity, nil, buyout}
    end
    -- Accomodate 9.2.7 dialog for when the AH requires confirmation before the
    -- commodities AH region merge.
    if C_AuctionHouse.PostItem(unpack(params)) then
      AuctionHouseFrame.ItemSellFrame:CachePendingPost(unpack(params))
    end
  else
    local params = {self.itemInfo.location, duration, quantity, buyout}
    -- Accomodate 9.2.7 dialog for when the AH requires confirmation before the
    -- commodities AH region merge.
    if C_AuctionHouse.PostCommodity(unpack(params)) then
      AuctionHouseFrame.CommoditiesSellFrame:CachePendingPost(unpack(params))
    end
  end

  local postedInfo = {
    itemLink = self.itemInfo.itemLink,
    quantity = quantity,
    buyoutAmount = buyout,
    bidAmount = bidAmountReported,
  }

  --Print auction to chat
  if Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_CHAT_LOG) then
    Auctionator.Utilities.Message(Auctionator.Selling.ComposeAuctionPostedMessage(postedInfo))
  end

  Auctionator.EventBus:Fire(self,
    Auctionator.Selling.Events.AuctionCreated,
    postedInfo
  )

  -- If there aren't any other auctions or this item is posted lower than the
  -- existing auctions then this item has become the new price for the item
  local priceToSave = postedInfo.buyoutAmount
  if postedInfo.buyoutAmount == 0 then
    priceToSave = postedInfo.bidAmount
  end
  if self.itemInfo.existingValue == nil or self.itemInfo.existingValue > priceToSave then
    Auctionator.Utilities.DBKeyFromLink(self.itemInfo.itemLink, function(dbKeys)
      for _, key in ipairs(dbKeys) do
        Auctionator.Database:SetPrice(key, priceToSave)
      end
      -- Refresh history listing after the new price is saved
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshHistory)
    end)
  else
    -- Refresh history (posting and price history)
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshHistory)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT) then
    Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_DURATION, self.Duration:GetValue())
  end

  -- Save item info for refreshing search results
  self.lastItemInfo = self.itemInfo
  self:Reset()

  if (Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT) and
      self.nextItem
     ) then
    -- Option to automatically select the next item in the bag view
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.nextItem
    )

  else
    -- Search for current auctions of the last item posted
    self:DoSearch(self.lastItemInfo)
  end
end

function AuctionatorSaleItemMixin:SkipItem()
  if self.SkipButton:IsEnabled() then
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.nextItem
    )
  end
end

function AuctionatorSaleItemMixin:PrevItem()
  if self.PrevButton:IsEnabled() then
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.prevItem
    )
  end
end

function AuctionatorSaleItemMixin:RefreshButtonClicked()
  -- Search for the current item or the last item posted
  if self.itemInfo ~= nil then
    self:DoSearch(self.itemInfo)
  elseif self.lastItemInfo ~= nil then
    self:DoSearch(self.lastItemInfo)
  end
end
