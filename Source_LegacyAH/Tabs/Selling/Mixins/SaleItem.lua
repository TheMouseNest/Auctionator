local function IsEquipment(itemInfo)
  return Auctionator.Utilities.IsEquipment(itemInfo.classId)
end

local function IsValidItem(item)
  return item ~= nil and
    -- May be a favourite with no items available, ignore it.
    item.location ~= nil and
    -- Location may be invalid because of items being moved in the bag
    C_Item.DoesItemExist(item.location)
end

local function GetAmountWithUndercut(amount)
  local salesPreference = Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_SALES_PREFERENCE)
  local undercutAmount = 0
  if salesPreference == Auctionator.Config.SalesTypes.STATIC then
    undercutAmount = Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_STATIC_VALUE)
  else
    undercutAmount = math.ceil(amount * Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_PERCENTAGE) / 100)
  end

  return math.max(0, amount - undercutAmount)
end

AuctionatorSaleItemMixin = {}

function AuctionatorSaleItemMixin:OnLoad()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    self.PostButton:SetPoint("TOPLEFT", self.Duration, "BOTTOMLEFT", 20, 0)
    self.BidPrice:Show()
  end

  self:SetupTabbing()
  self.clickedSellItem = true
end

-- Make pressing tab work to jump between edit boxes in the SaleItemFrame
function AuctionatorSaleItemMixin:SetupTabbing()
  self.UnitPrice.MoneyInput:SetNextEditBox(self.StackPrice.MoneyInput.GoldBox)
  self.StackPrice.MoneyInput:SetNextEditBox(self.Stacks.NumStacks)
  self.Stacks.NumStacks.nextEditBox = self.Stacks.StackSize
  self.Stacks.StackSize.previousEditBox = self.Stacks.NumStacks

  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    self.Stacks.StackSize.nextEditBox = self.BidPrice.MoneyInput.GoldBox
    self.BidPrice.MoneyInput.GoldBox.previousEditBox = self.Stacks.StackSize
  end
end

function AuctionatorSaleItemMixin:OnShow()
  Auctionator.EventBus:Register(self, {
    Auctionator.Selling.Events.BagItemClicked,
    Auctionator.Selling.Events.ClearBagItem,
    Auctionator.Selling.Events.RequestPost,
    Auctionator.Selling.Events.SkipItem,
    Auctionator.Selling.Events.ConfirmPost,
    Auctionator.Selling.Events.PostSuccessful,
    Auctionator.Selling.Events.PostFailed,
    Auctionator.Buying.Events.ViewSetup,
    Auctionator.AH.Events.ThrottleUpdate,
    Auctionator.Buying.Events.AuctionFocussed,
    Auctionator.Buying.Events.HistoricalPrice,
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

  self:UpdateSkipButton()
  self:Reset()

  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SHOULD_RESELECT_ITEM) then
    local key = Auctionator.Config.Get(Auctionator.Config.Options.SELLING_RESELECT_ITEM)
    if key ~= nil then
      self.lastKey = key
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
    Auctionator.Selling.Events.PostSuccessful,
    Auctionator.Selling.Events.PostFailed,
    Auctionator.Buying.Events.ViewSetup,
    Auctionator.AH.Events.ThrottleUpdate,
    Auctionator.Buying.Events.AuctionFocussed,
    Auctionator.Buying.Events.HistoricalPrice,
    Auctionator.Components.Events.EnterPressed,
  })
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
    self.PostButton:SetSize(104, 22)
    self.SkipButton:Show()
  else
    self.PostButton:SetSize(184, 22)
    self.SkipButton:Hide()
  end
end

function AuctionatorSaleItemMixin:UnlockItem()
  if self.itemInfo ~= nil then
    --Existence check added because of a bug report from a user where (for an
    --unknown reason) the item no longer existed.
    if self.itemInfo.count > 0 and C_Item.DoesItemExist(self.itemInfo.location) then
      C_Item.UnlockItem(self.itemInfo.location)
    end
    self.itemInfo = nil
  end
end

function AuctionatorSaleItemMixin:LockItem()
  if self.itemInfo.count > 0 then
    C_Item.LockItem(self.itemInfo.location)
  end
end

function AuctionatorSaleItemMixin:UpdatePrices()
  if self.UnitPrice:GetAmount() ~= self.prevUnitPrice then
    self.prevUnitPrice = self.UnitPrice:GetAmount()
    self.prevStackPrice = self.prevUnitPrice * self.prevStackSize
    self.StackPrice:SetAmount(self.prevStackPrice)
    self.BidPrice:SetAmount(self:GetAutoBidAmount())

  elseif self.StackPrice:GetAmount() ~= self.prevStackPrice then
    self.prevStackPrice = self.StackPrice:GetAmount()
    if self.prevStackSize ~= 0 then
      self.prevUnitPrice = math.ceil(self.prevStackPrice / self.prevStackSize)
      self.UnitPrice:SetAmount(self.prevUnitPrice)
      self.BidPrice:SetAmount(self:GetAutoBidAmount())
    end

  elseif self:GetStackSize() ~= self.prevStackSize then
    self.prevStackSize = self:GetStackSize()
    self.prevStackPrice = self:GetStackSize() * self.UnitPrice:GetAmount()
    self.StackPrice:SetAmount(self.prevStackPrice)
    self.BidPrice:SetAmount(self:GetAutoBidAmount())
    self:DisplayMaxNumStacks()
  end
end

function AuctionatorSaleItemMixin:OnUpdate()
  GetOwnerAuctionItems(0)
  if self.itemInfo == nil then
    return

  elseif self.itemInfo.count == 0 and self.clickedSellItem then
    return

  elseif self.itemInfo.location ~= nil and not C_Item.DoesItemExist(self.itemInfo.location) then
    local itemInfo = Auctionator.Groups.Utilities.QueryItem(self.itemInfo.sortKey)
    self.itemInfo.location = itemInfo and itemInfo.locations[1]
    -- Bag position changes (race condition or posting reattempt)
    if not self.itemInfo.location then
      self.itemInfo = nil
      self:Reset()
      return
    else
      self.clickedSellItem = false
    end
  end

  if not self.clickedSellItem then
    self:SellItemClick()
    return
  end


  self:UpdatePrices()

  self.TotalPrice:SetText(
    GetMoneyString(
      self:GetNumStacks() * self:GetStackSize() * self.UnitPrice:GetAmount(),
      true
    )
  )

  self.DepositPrice:SetText(GetMoneyString(self:GetDeposit(), true))
  self:UpdatePostButtonState()
  self:UpdateSkipButtonState()
end

function AuctionatorSaleItemMixin:GetAutoBidAmount()
  local startingPricePercentage = Auctionator.Config.Get(Auctionator.Config.Options.STARTING_PRICE_PERCENTAGE) / 100
  return math.ceil(startingPricePercentage * self.StackPrice:GetAmount())
end

function AuctionatorSaleItemMixin:GetBidAmount()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    return self.BidPrice:GetAmount()
  else
    return self:GetAutoBidAmount()
  end
end

function AuctionatorSaleItemMixin:GetStackSize()
  return math.min(self.Stacks.StackSize:GetNumber(), math.min(self.itemInfo.count, self.itemInfo.stackSize))
end

function AuctionatorSaleItemMixin:GetNumStacks()
  return math.min(self.Stacks.NumStacks:GetNumber(), self.itemInfo.count)
end

function AuctionatorSaleItemMixin:GetDeposit()
  return GetAuctionDeposit(
    self:GetDuration(),
    math.min(self:GetBidAmount(), MAXIMUM_BID_PRICE),
    math.min(self.StackPrice:GetAmount(), MAXIMUM_BID_PRICE),
    self:GetStackSize(),
    self:GetNumStacks()
  )
end

-- We need to wait for whatever item is being posted to finish posting
-- before accepting the new item, hence the throttle check and this extra
-- function.
-- Also, when using right-click as a shortcut to select the item or reselecting
-- the same item this fails on the first couple of attempts.
function AuctionatorSaleItemMixin:SellItemClick()
  self.clickedSellItem = true

  ClearCursor()

  -- Remove any item already selected in the Auctions frame, as if it is the
  -- same as the item we're trying to add it will cause the add to fail.
  ClickAuctionSellItemButton()
  ClearCursor()

  if IsValidItem(self.itemInfo) then
    if self.itemInfo.location:IsBagAndSlot() then
      if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(self.itemInfo.location:GetBagAndSlot())
      else
        PickupContainerItem(self.itemInfo.location:GetBagAndSlot())
      end
    else
      PickupInventoryItem(self.itemInfo.location:GetEquipmentSlot())
    end

    ClickAuctionSellItemButton()
    ClearCursor()

    -- Check we didn't fail
    if (GetAuctionSellItemInfo()) ~= nil then
      Auctionator.Debug.Message("Valid sell item", GetAuctionSellItemInfo())
      self:LockItem()
      if not self.retryingItem then
        Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshBuying, self.itemInfo)
      end
    -- Failed; this item can't be auctioned
    else
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StopFakeBuyLoading)
      Auctionator.Debug.Message("Invalid sell item")
      self.itemInfo = nil
      self:Update()
    end
  else
    if self.itemInfo ~= nil then
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshBuying, self.itemInfo)
    else
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StopFakeBuyLoading)
    end
    self.itemInfo = nil
  end
end

function AuctionatorSaleItemMixin:ReceiveEvent(event, ...)
  if event == Auctionator.Selling.Events.BagItemClicked then
    local itemInfo = ...
    self.retryingItem = false

    self:UnlockItem()
    self.clickedSellItem = false

    self.itemInfo = itemInfo
    self.nextItem = self.itemInfo and self.itemInfo.nextItem
    self.prevItem = self.itemInfo and self.itemInfo.prevItem
    self.lastKey = self.itemInfo and self.itemInfo.key

    if self.itemInfo ~= nil and self.itemInfo.stackSize == nil then
      self.itemInfo = nil

      local item
      if IsValidItem(itemInfo) then
        item = Item:CreateFromItemLocation(itemInfo.location)
      else
        item = Item:CreateFromItemLink(itemInfo.itemLink)
      end

      item:ContinueOnItemLoad(function()
        itemInfo.stackSize = select(8, C_Item.GetItemInfo(itemInfo.itemLink))
        self.itemInfo = itemInfo

        self:Update()
      end)
    end
    self:Update()

  elseif event == Auctionator.Selling.Events.ClearBagItem then
    self.nextItem = nil
    self.prevItem = nil
    self.lastKey = nil
    self:Reset()
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StopFakeBuyLoading)

  elseif event == Auctionator.AH.Events.ThrottleUpdate then
    self:UpdatePostButtonState()

  elseif event == Auctionator.Buying.Events.ViewSetup then
    self.buyViewSetup = true
    self:UpdatePostButtonState()

  elseif event == Auctionator.Selling.Events.RequestPost then
    self:PostItem()

  elseif event == Auctionator.Selling.Events.ConfirmPost then
    self:PostItem(true)

  elseif event == Auctionator.Selling.Events.SkipItem then
    self:SkipItem()

  elseif event == Auctionator.Components.Events.EnterPressed then
    self:PostItem()

  elseif event == Auctionator.Buying.Events.AuctionFocussed and
         self.itemInfo ~= nil then
    local info = ...
    if info ~= nil then
      self:UpdateForHistoryPrice(info.unitPrice)
      local unitPrice
      if not info.isOwned then
        unitPrice = GetAmountWithUndercut(info.unitPrice)
      else
        unitPrice = info.unitPrice
      end
      self:SetUnitPrice(unitPrice)
      -- Used to check if the undercut is more than 50% below configured setting
      self.priceCutThreshold = unitPrice * 0.5
    end
  elseif event == Auctionator.Buying.Events.HistoricalPrice and
         self.itemInfo ~= nil then
    local price = ...
    self:SetUnitPrice(price)
  elseif event == Auctionator.Selling.Events.PostSuccessful then
    local details = ...
    self:SuccessfulPost(details)
    if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_POST_STACK_REMAINDER) and (details.itemInfo.count - details.numStacks * details.stackSize) < details.stackSize then
      self:ReselectItem(details)
    else
      self:DoNextItem(details)
    end
  elseif event == Auctionator.Selling.Events.PostFailed then
    local details = ...
    if details.numStacksReached > 0 then
      self:SuccessfulPost(details)
    end
    UIErrorsFrame:AddMessage(AUCTIONATOR_L_POST_ATTEMPT_FAILED, 1.0, 0.1, 0.1, 1.0)
    Auctionator.Utilities.Message(AUCTIONATOR_L_POST_ATTEMPT_FAILED)
    self:ReselectItem(details)
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

  else
    -- No item, reset all the visuals
    self.TitleArea.Text:SetText("")
  end
end

-- The exact item name is only loaded when needed as it slows down loading the
-- bag items too much to do in BagDataProvider.
function AuctionatorSaleItemMixin:SetItemName()
  if self.itemInfo then
    local name = Auctionator.Utilities.GetNameFromLink(self.itemInfo.itemLink)
    local color = ITEM_QUALITY_COLORS[self.itemInfo.quality].color
    self.TitleArea.Text:SetText(color:WrapTextInColorCode(name))

    if IsEquipment(self.itemInfo) then
      local item = Item:CreateFromItemLink(self.itemInfo.itemLink)
      item:ContinueOnItemLoad(function()
        local itemLevel = GetDetailedItemLevelInfo(self.itemInfo.itemLink)
        self.TitleArea.Text:SetText(color:WrapTextInColorCode(name .. " (" .. itemLevel .. ")"))
      end)
    end
  end
end

function AuctionatorSaleItemMixin:UpdateForHistoryPrice(newPrice)
  if self.minPriceSeen == 0 then
    self.minPriceSeen = newPrice
  else
    self.minPriceSeen = math.min(self.minPriceSeen, newPrice)
  end
end

function AuctionatorSaleItemMixin:UpdateForNewItem()
  self:SetDuration()

  self.Stacks:SetMaxStackSize(math.min(self.itemInfo.stackSize, self.itemInfo.count))

  self:SetQuantity()

  self.priceCutThreshold = nil

  if not self.retryingItem then
    self.buyViewSetup = false

    Auctionator.Utilities.DBKeyFromLink(self.itemInfo.itemLink, function(dbKeys)
      local price = Auctionator.Database:GetFirstPrice(dbKeys)

      if price ~= nil then
        self:SetUnitPrice(price)
      elseif IsEquipment(self.itemInfo) then
        self:SetEquipmentMultiplier(self.itemInfo.itemLink)
      else
        self:SetUnitPrice(0)
      end
    end)

    -- Used because it can take a while for the throttle to clear on a megaserver,
    -- this makes it clear that something is loading rather than leaving the
    -- prices frozen on the previous item.
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StartFakeBuyLoading, {itemLink = self.itemInfo.itemLink})

    self.minPriceSeen = 0
  end
end

function AuctionatorSaleItemMixin:UpdateForNoItem()
  self.Stacks.NumStacks:SetNumber(0)
  self.Stacks.StackSize:SetNumber(0)
  self.Stacks:SetMaxStackSize(0)
  self.Stacks:SetMaxNumStacks(0)
  self:SetUnitPrice(0)

  self.DepositPrice:SetText(GetMoneyString(0))
  self.TotalPrice:SetText(GetMoneyString(0))
end

local groupDurationToRadioDuration = {
  [1] = 12,
  [2] = 24,
  [3] = 48,
}
function AuctionatorSaleItemMixin:SetDuration()
  self.Duration:SetSelectedValue(
    Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_DURATION)
  )
end

function AuctionatorSaleItemMixin:SetQuantity()
  local defaultStacks = CopyTable(Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_SELLING_STACKS))

  local preferredStackSize = Auctionator.Config.Get(Auctionator.Config.Options.STACK_SIZE_MEMORY)[Auctionator.Utilities.BasicDBKeyFromLink(self.itemInfo.itemLink)]

  -- Determine what the stack size would be without using stack size memory.
  -- This is used to clear stack size memory when the max/min is used
  if defaultStacks.stackSize == 0 then
    self.normalStackSize = math.min(self.itemInfo.count, self.itemInfo.stackSize)
  else
    self.normalStackSize = math.min(defaultStacks.stackSize, self.itemInfo.stackSize)
  end

  if preferredStackSize ~= nil then
    self.Stacks.StackSize:SetNumber(math.min(self.itemInfo.count, preferredStackSize))
  else
    self.Stacks.StackSize:SetNumber(math.min(self.normalStackSize, self.itemInfo.count))
  end

  local numStacks = math.floor(self.itemInfo.count/self.Stacks.StackSize:GetNumber())
  if preferredStackSize ~= nil then
    numStacks = math.floor(self.itemInfo.count/preferredStackSize)
  end

  if numStacks == 0 then
    numStacks = 1
  end

  if self.itemInfo.count == 0 then
    self.Stacks.NumStacks:SetNumber(0)
  elseif defaultStacks.numStacks == 0 then
    self.Stacks.NumStacks:SetNumber(numStacks)
  else
    self.Stacks.NumStacks:SetNumber(math.min(numStacks, defaultStacks.numStacks))
  end

  self:DisplayMaxNumStacks()
end

function AuctionatorSaleItemMixin:DisplayMaxNumStacks()
  local numStacks = math.floor(self.itemInfo.count / self:GetStackSize())
  if self:GetStackSize() == 0 then
    numStacks = 0
  elseif numStacks == 0 then
    numStacks = 1
  end

  self.Stacks:SetMaxNumStacks(numStacks)
end

function AuctionatorSaleItemMixin:Reset()
  self:UnlockItem()

  self:Update()
end

function AuctionatorSaleItemMixin:SetUnitPrice(salesPrice)
  if salesPrice == 0 then
    self.UnitPrice:SetAmount(0)
  else
    self.UnitPrice:SetAmount(salesPrice)
  end

  self.StackPrice:SetAmount(self.UnitPrice:GetAmount() * self.Stacks.StackSize:GetNumber())
  self.BidPrice:SetAmount(self:GetAutoBidAmount())

  self.priceCutThreshold = nil

  self.prevStackSize = self.Stacks.StackSize:GetNumber()
  self.prevUnitPrice = self.UnitPrice:GetAmount()
  self.prevStackPrice = self.StackPrice:GetAmount()
end

function AuctionatorSaleItemMixin:SetEquipmentMultiplier(itemLink)
  self:SetUnitPrice(0)

  local item = Item:CreateFromItemLink(itemLink)
  item:ContinueOnItemLoad(function()
    local multiplier = Auctionator.Config.Get(Auctionator.Config.Options.GEAR_PRICE_MULTIPLIER)
    local vendorPrice = select(11, C_Item.GetItemInfo(itemLink))
    if multiplier ~= 0 and vendorPrice ~= 0 then
      -- Check for a vendor price multiplier being set (and a vendor price)
      self:SetUnitPrice(
        vendorPrice * multiplier + self:GetDeposit()
      )
    end
  end)
end

function AuctionatorSaleItemMixin:GetPostButtonState()
  return
    self.itemInfo ~= nil and
    self.itemInfo.count > 0 and
    self.clickedSellItem and
    self.buyViewSetup and

    C_Item.DoesItemExist(self.itemInfo.location) and

    self.StackPrice:GetAmount() <= MAXIMUM_BID_PRICE and

    -- Sufficient money to cover deposit
    GetMoney() >= self:GetDeposit() and

    -- Valid quantity
    self.Stacks.NumStacks:GetNumber() > 0 and
    self.Stacks.StackSize:GetNumber() > 0 and
    self.Stacks.StackSize:GetNumber() <= self.itemInfo.stackSize and
    self.Stacks.NumStacks:GetNumber() * self.Stacks.StackSize:GetNumber() <= self.itemInfo.count and

    -- Positive price
    (
      self.UnitPrice:GetAmount() > 0 or
      self.BidPrice:GetAmount() > 0
    ) and

    -- Have opted to ignore the throttle or searches on the client aren't throttled
    (not Auctionator.Config.Get(Auctionator.Config.Options.SELLING_GREY_POST_BUTTON) or Auctionator.AH.IsNotThrottled())
end

function AuctionatorSaleItemMixin:GetStackableWarningThreshold()
  -- Limit warning to stackable items only (like the retail warning on
  -- commodities)
  if self.itemInfo.stackSize <= 1 then
    return 0
  end

  -- Identifies when an auction is skewing the current price down and is
  -- probably not meant to be so low.
  local allAuctions = self:GetParent().BuyFrame.CurrentPrices.SearchDataProvider.allAuctions
  local midPoint = math.min(5, math.ceil(#allAuctions / 2))
  local watchPoint = allAuctions[midPoint]
  if watchPoint ~= nil then
    local watchPointPrice = Auctionator.Utilities.ToUnitPrice(watchPoint) or 0
    return Auctionator.Utilities.PriceWarningThreshold(watchPointPrice)
  end
  return 0
end

function AuctionatorSaleItemMixin:GetConfirmationMessage()
  local effectiveUnitPrice = self.UnitPrice:GetAmount()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) and effectiveUnitPrice == 0 then
    effectiveUnitPrice = math.ceil(self.BidPrice:GetAmount() / self:GetStackSize())
  end
  -- Check if the price may have had the unit and stack price entered in the
  -- wrong box with the item being underpriced compared to the on sale items
  if self.priceCutThreshold ~= nil and effectiveUnitPrice < self.priceCutThreshold then
    return AUCTIONATOR_L_CONFIRM_POST_PRICE_DROP:format(GetMoneyString(self.UnitPrice:GetAmount(), true))
  end

  -- Determine if the item is worth more to sell to a vendor than to post on the
  -- AH.
  local itemInfo = { C_Item.GetItemInfo(self.itemInfo.itemLink) }
  local vendorPrice = itemInfo[Auctionator.Constants.ITEM_INFO.SELL_PRICE]
  if Auctionator.Utilities.IsVendorable(itemInfo) and
     vendorPrice * self:GetStackSize() * self:GetNumStacks()
       > math.floor(effectiveUnitPrice * self:GetStackSize() * self:GetNumStacks() * Auctionator.Constants.AfterAHCut) then
    return AUCTIONATOR_L_CONFIRM_POST_BELOW_VENDOR
  end

  -- Check if the item was underpriced compared to the currently on sale items
  if effectiveUnitPrice < self:GetStackableWarningThreshold() then
    return AUCTIONATOR_L_CONFIRM_POST_LOW_PRICE:format(GetMoneyString(self.UnitPrice:GetAmount(), true))
  end
end

function AuctionatorSaleItemMixin:RequiresConfirmationState()
  return
    Auctionator.Config.Get(Auctionator.Config.Options.SELLING_CONFIRM_LOW_PRICE) and
    self:GetConfirmationMessage() ~= nil
end

function AuctionatorSaleItemMixin:UpdatePostButtonState()
  self.PostButton:SetEnabled(self:GetPostButtonState())
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
      StaticPopupDialogs[Auctionator.Constants.DialogNames.SellingConfirmPostSkip].text = self:GetConfirmationMessage()
      StaticPopup_Show(Auctionator.Constants.DialogNames.SellingConfirmPostSkip)
    else
      StaticPopupDialogs[Auctionator.Constants.DialogNames.SellingConfirmPost].text = self:GetConfirmationMessage()
      StaticPopup_Show(Auctionator.Constants.DialogNames.SellingConfirmPost)
    end
    return
  end

  local numStacks = self.Stacks.NumStacks:GetNumber()
  local stackSize = self.Stacks.StackSize:GetNumber()
  local duration = self:GetDuration()
  local startingBid = self:GetBidAmount()
  local buyoutPrice = self.StackPrice:GetAmount()
  local deposit = self:GetDeposit()

  local stackSizeMemory = Auctionator.Config.Get(Auctionator.Config.Options.STACK_SIZE_MEMORY)
  local basicDBKey = Auctionator.Utilities.BasicDBKeyFromLink(self.itemInfo.itemLink)
  -- Only save stack size if its different to the global default
  if stackSize ~= self.normalStackSize then
    stackSizeMemory[basicDBKey] = stackSize
  else
    stackSizeMemory[basicDBKey] = nil
  end

  Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.PostAttempt, {
    numStacks = numStacks,
    stackSize = stackSize,
    duration = duration,
    unitPrice = self.UnitPrice:GetAmount(),
    startingBid = startingBid,
    buyoutPrice = buyoutPrice,
    deposit = deposit,
    itemInfo = self.itemInfo,
    minPriceSeen = self.minPriceSeen,
  })

  if StaticPopupDialogs["AUCTION_HOUSE_POST_WARNING"] then
    Auctionator.AH.PostAuction(startingBid, buyoutPrice, duration, stackSize, numStacks, true)
  else
    Auctionator.AH.PostAuction(startingBid, buyoutPrice, duration, stackSize, numStacks)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT) then
    Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_DURATION, self.Duration:GetValue())
  end

  self:Reset()
end

function AuctionatorSaleItemMixin:SuccessfulPost(details)
  --Print auction to chat
  if Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_CHAT_LOG) then
    Auctionator.Utilities.Message(Auctionator.Selling.ComposeAuctionPostedMessage({
      itemLink = details.itemInfo.itemLink,
      numStacks = details.numStacksReached,
      stackSize = details.stackSize,
      stackBuyout = details.buyoutPrice,
    }))
  end

  Auctionator.EventBus:Fire(self,
    Auctionator.Selling.Events.AuctionCreated,
    {
      itemLink = details.itemInfo.itemLink,
      quantity = details.numStacksReached * details.stackSize,
      buyoutAmount = details.unitPrice,
      bidAmount = details.startingBid,
      deposit = details.deposit,
    }
  )

  -- If not seen in any queries before this, then this price is the first one
  -- listed. Update the database to include this price.
  if details.minPriceSeen == 0 or details.minPriceSeen > details.unitPrice then
    local minPrice = details.unitPrice
    Auctionator.Utilities.DBKeyFromLink(details.itemInfo.itemLink, function(dbKeys)
      for _, key in ipairs(dbKeys) do
        Auctionator.Database:SetPrice(key, minPrice)
      end
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshHistoryOnly, details.itemInfo)
    end)
  else
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshHistoryOnly, details.itemInfo)
  end
end

function AuctionatorSaleItemMixin:DoNextItem(details)
  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT) and self.nextItem then
    -- Option to automatically select the next item in the bag view
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.nextItem
    )
  end
end

function AuctionatorSaleItemMixin:ReselectItem(details)
  -- estimate count as the bag may not have updated to remove the posted items
  -- yet
  local count = details.itemInfo.count - details.stackSize * details.numStacksReached
  if count > 0 then
    local itemInfo = Auctionator.Groups.Utilities.QueryItem(details.itemInfo.sortKey)
    if itemInfo then
      Auctionator.Debug.Message("found again, trying")
      self:UnlockItem()
      self.retryingItem = true
      self.itemInfo = CopyTable(details.itemInfo, true)
      self.itemInfo.location = itemInfo.locations[1]
      self.itemInfo.count = count
      self.clickedSellItem = false
      self.minPriceSeen = details.minPriceSeen
      self:Update()
      self:SetUnitPrice(details.unitPrice)
      self.Stacks.NumStacks:SetNumber(math.max(1, details.numStacks - details.numStacksReached))
      return
    end
  end

  Auctionator.Debug.Message("item missing, won't retry")
  self:DoNextItem(details)
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
