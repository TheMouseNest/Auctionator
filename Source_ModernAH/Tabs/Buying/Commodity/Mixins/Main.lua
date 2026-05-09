AuctionatorBuyCommodityFrameTemplateMixin = {}

local SEARCH_EVENTS = {
  "COMMODITY_SEARCH_RESULTS_UPDATED",
  "COMMODITY_PURCHASE_SUCCEEDED",
  "COMMODITY_PURCHASE_FAILED",
}

local PURCHASE_EVENTS = {
  "COMMODITY_PRICE_UPDATED",
  "COMMODITY_PRICE_UNAVAILABLE",
}

function AuctionatorBuyCommodityFrameTemplateMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
  Auctionator.EventBus:Register(self, {
    Auctionator.Buying.Events.ShowCommodityBuy,
    Auctionator.Buying.Events.SelectCommodityRow,
    Auctionator.Shopping.Tab.Events.SearchStart,
  })

  self.DetailsContainer.Quantity:SetScript("OnTextChanged", function(numericInput)
    if numericInput:GetText() == "" then
      self.selectedQuantity = 0
    else
      local value = tonumber(numericInput:GetText())
      if value and value >= 0 then
        if self.maxQuantity then
          value = math.min(value, self.maxQuantity)
        end
        self.selectedQuantity = value
      end
    end
    self:UpdateView()
  end)
end

function AuctionatorBuyCommodityFrameTemplateMixin:OnShow()
  self:GetParent().ResultsListing:Hide()
  self:GetParent().ShoppingResultsInset:Hide()
  self:GetParent().ExportCSV:Hide()
  FrameUtil.RegisterFrameForEvents(self, SEARCH_EVENTS)
end

function AuctionatorBuyCommodityFrameTemplateMixin:OnHide()
  self:GetParent().ResultsListing:Show()
  self:GetParent().ShoppingResultsInset:Show()
  self:GetParent().ExportCSV:Show()
  self:Hide()
  self.results = nil
  self.maxQuantity = nil
  if self.waitingForPurchase then
    FrameUtil.UnregisterFrameForEvents(self, PURCHASE_EVENTS)
    C_AuctionHouse.CancelCommoditiesPurchase()
    self.waitingForPurchase = false
  end
  FrameUtil.UnregisterFrameForEvents(self, SEARCH_EVENTS)
end

function AuctionatorBuyCommodityFrameTemplateMixin:ReceiveEvent(eventName, ...)
  if eventName == Auctionator.Buying.Events.ShowCommodityBuy then
    local rowData, itemKeyInfo = ...

    self:Show()
    self.selectedRows = 1
    self.selectedQuantity = rowData.purchaseQuantity or 1
    local prettyName = AuctionHouseUtil.GetItemDisplayTextFromItemKey(
      rowData.itemKey,
      itemKeyInfo,
      false
    )
    self.expectedItemID = rowData.itemKey.itemID
    self.itemKey = rowData.itemKey
    self.IconAndName:SetItem(rowData.itemKey, nil, itemKeyInfo.quality, prettyName, itemKeyInfo.iconFileID)
    self.IconAndName:SetScript("OnMouseUp", function()
      AuctionHouseFrame:SelectBrowseResult(rowData)
      -- Clear displayMode (prevents bag items breaking in some scenarios)
      AuctionHouseFrame.displayMode = nil
    end)
    self:Search()
    self:UpdateView()
  elseif eventName == Auctionator.Buying.Events.SelectCommodityRow then
    local rows = ...
    self.selectedQuantity = 0
    for _, r in ipairs(self.results) do
      if r.rowIndex <= rows then
        self.selectedQuantity = self.selectedQuantity + r.quantity
      else
        break
      end
    end
    self:UpdateView()
  elseif eventName == Auctionator.Shopping.Tab.Events.SearchStart then
    self:Hide()
  end
end

function AuctionatorBuyCommodityFrameTemplateMixin:OnEvent(eventName, eventData, ...)
  if (eventName == "COMMODITY_SEARCH_RESULTS_UPDATED" and self.expectedItemID ~= nil and
          self.expectedItemID == eventData
        ) then
    self.results = self:ProcessCommodityResults(eventData)
    self.maxQuantity = C_AuctionHouse.GetCommoditySearchResultsQuantity(eventData)
    self.DataProvider:SetListing(self.results)
    self:UpdateView()

  elseif eventName == "COMMODITY_PRICE_UPDATED" and self.results then
    self:CheckPurchase(eventData, ...)

  -- Getting a price to purchase failed
  elseif eventName == "COMMODITY_PRICE_UNAVAILABLE" then
    FrameUtil.UnregisterFrameForEvents(self, PURCHASE_EVENTS)
    self.waitingForPurchase = false
    C_AuctionHouse.CancelCommoditiesPurchase()

    self:Search()

  -- Refresh listing after purchase attempt
  elseif eventName == "COMMODITY_PURCHASE_SUCCEEDED" or
      eventName == "COMMODITY_PURCHASE_FAILED" then
    self:Search()
  end
end

function AuctionatorBuyCommodityFrameTemplateMixin:Search()
  if self.itemKey == nil then
    return
  end
  Auctionator.EventBus
    :RegisterSource(self, "BuyCommodityFrame")
    :Fire(self, Auctionator.Buying.Events.RefreshingCommodities)
    :UnregisterSource(self)
  Auctionator.AH.SendSearchQueryByItemKey(self.itemKey, Auctionator.Constants.CommodityResultsSorts, false)
end

function AuctionatorBuyCommodityFrameTemplateMixin:ProcessCommodityResults(itemID)
  local entries = {}
  local anyOwnedNotLoaded = false

  for index = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
    local resultInfo = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)
    if resultInfo.owners[1] == "player" then
      resultInfo.owners[1] = GREEN_FONT_COLOR:WrapTextInColorCode(AUCTION_HOUSE_SELLER_YOU)
    end
    local entry = {
      price = resultInfo.unitPrice,
      owners = resultInfo.owners,
      totalNumberOfOwners = resultInfo.totalNumberOfOwners,
      otherSellers = Auctionator.Utilities.StringJoin(resultInfo.owners, PLAYER_LIST_DELIMITER),
      quantity = resultInfo.quantity,
      quantityFormatted = FormatLargeNumber(resultInfo.quantity),
      selected = self.selectedRows >= index,
      rowIndex = index,
    }

    if #entry.owners > 0 and #entry.owners < entry.totalNumberOfOwners then
      entry.otherSellers = AUCTIONATOR_L_SELLERS_OVERFLOW_TEXT:format(entry.otherSellers, entry.totalNumberOfOwners - #entry.owners)
    end

    table.insert(entries, entry)
  end

  return entries
end

function AuctionatorBuyCommodityFrameTemplateMixin:GetPrices()
  local total = 0
  local quantityLeft = self.selectedQuantity
  for _, r in ipairs(self.results) do
    if quantityLeft == 0 then
      break
    elseif r.quantity > quantityLeft then
      total = total + quantityLeft * r.price
      quantityLeft = 0
    else
      total = total + r.price * r.quantity
      quantityLeft = quantityLeft - r.quantity
    end
  end
  local unitPrice = 0
  if self.selectedQuantity > 0 then
    unitPrice = math.ceil(math.ceil(total / self.selectedQuantity / 100) * 100)
  end

  return unitPrice, total
end

function AuctionatorBuyCommodityFrameTemplateMixin:UpdateView()
  if self.DetailsContainer.Quantity:GetText() ~= "" or self.selectedQuantity ~= 0 then
    self.DetailsContainer.Quantity:SetNumber(self.selectedQuantity)
  end
  if self.results then
    local runningQuantity = 0
    for _, r in ipairs(self.results) do
      r.selected = runningQuantity < self.selectedQuantity
      runningQuantity = runningQuantity + r.quantity
    end
    self.DataProvider:SetListing(self.results)

    local unitPrice, total = self:GetPrices()

    self.DetailsContainer.UnitPriceText:SetText(GetMoneyString(unitPrice, true))
    self.DetailsContainer.TotalPriceText:SetText(GetMoneyString(total, true))

    self.DetailsContainer.BuyButton:SetEnabled(total <= GetMoney())

  else
    self.DetailsContainer.UnitPriceText:SetText("")
    self.DetailsContainer.TotalPriceText:SetText("")
    self.DetailsContainer.BuyButton:Disable()
  end
end
function AuctionatorBuyCommodityFrameTemplateMixin:BuyClicked(button)
  local minUnitPrice = self.results[1].price
  local maxUnitPrice = self.results[1].price
  for _, r in ipairs(self.results) do
    if not r.selected then
      break
    end
    maxUnitPrice = r.price
  end
  local shift = (maxUnitPrice - minUnitPrice) / minUnitPrice * 100
  local shortcut = Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_SKIP_BUY_CONFIRMATION)
  local skipConfirm = shortcut ~= Auctionator.Config.Shortcuts.NONE and
    Auctionator.Utilities.IsShortcutActive(shortcut, button or "LeftButton")
  self.skipConfirmation = skipConfirm
  if not skipConfirm and shift >= 50 then
    self.WidePriceRangeWarningDialog:SetDetails({
      minUnitPrice = minUnitPrice,
      maxUnitPrice = maxUnitPrice,
    })
  else
    self:ForceStartPurchase()
  end
end

function AuctionatorBuyCommodityFrameTemplateMixin:ForceStartPurchase()
  self.waitingForPurchase = true
  FrameUtil.RegisterFrameForEvents(self, PURCHASE_EVENTS)
  C_AuctionHouse.StartCommoditiesPurchase(self.expectedItemID, self.selectedQuantity)
end

local function GetMedianUnit(quantity, results)
  local target = math.floor(quantity / 2)
  local runningQuantity = 0
  for _, r in ipairs(results) do
    runningQuantity = runningQuantity + r.quantity
    if runningQuantity >= target then
      return r.price
    end
  end
  return results[#results].price
end

function AuctionatorBuyCommodityFrameTemplateMixin:CheckPurchase(newUnitPrice, newTotalPrice)
  if self.skipConfirmation then
    C_AuctionHouse.ConfirmCommoditiesPurchase(self.expectedItemID, self.selectedQuantity)
    FrameUtil.UnregisterFrameForEvents(self, PURCHASE_EVENTS)
    self.waitingForPurchase = false
    return
  end

  local originalUnitPrice = self:GetPrices()

  local prefix = ""
  if originalUnitPrice < newUnitPrice then
    prefix = RED_FONT_COLOR:WrapTextInColorCode(AUCTIONATOR_L_PRICE_INCREASED .. "\n\n")
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_ALWAYS_CONFIRM_COMMODITY_QUANTITY) then
    self.QuantityCheckConfirmationDialog:SetDetails({
      prefix = prefix,
      message = AUCTIONATOR_L_TOTAL_OF_X_FOR_UNIT_PRICE_OF_X,
      itemID = self.expectedItemID,
      quantity = self.selectedQuantity,
      total = newTotalPrice,
      unitPrice = newUnitPrice,
    })
  else
    self.FinalConfirmationDialog:SetDetails({
      prefix = prefix,
      itemID = self.expectedItemID,
      quantity = self.selectedQuantity,
      total = newTotalPrice,
      unitPrice = newUnitPrice,
    })
  end

  FrameUtil.UnregisterFrameForEvents(self, PURCHASE_EVENTS)
  self.waitingForPurchase = false -- Cancelling is done by dialog after this
end
