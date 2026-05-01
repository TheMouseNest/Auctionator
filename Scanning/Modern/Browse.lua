---@class addonTableAuctionator
local addonTable = select(2, ...)

addonTable.Scanning.Modern.BrowseMixin = {}

local INCREMENTAL_SCAN_EVENTS = {
  "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
  "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
  "AUCTION_HOUSE_CLOSED",
}

function addonTable.Scanning.Modern.BrowseMixin:OnLoad()
  self:SetScript("OnEvent", self.OnEvent)

  self.doingFullScan = false
  self.state = addonTable.Config.Get(addonTable.Config.Options.SCAN_STATE)
end

function addonTable.Scanning.Modern.BrowseMixin:RegisterForEvents()
  FrameUtil.RegisterFrameForEvents(self, INCREMENTAL_SCAN_EVENTS)
end

function addonTable.Scanning.Modern.BrowseMixin:UnregisterForEvents()
  FrameUtil.UnregisterFrameForEvents(self, INCREMENTAL_SCAN_EVENTS)
end

function addonTable.Scanning.Modern.BrowseMixin:OnEvent(event, ...)
  if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
    self.info = {} -- New search results so reset info
    self.rawScan = {}

    local browseResults = C_AuctionHouse.GetBrowseResults()
    -- Check this is probably the start of a new batch, as the UPDATED event
    -- will fire when doing other specific items searches (to update the price
    -- and quantity) on any size search results.
    if #browseResults <= addonTable.Constants.SummaryBatchSize then
      self:AddPrices(browseResults)
      self:NextStep()
    end
  elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
    self:AddPrices(...)
    self:NextStep()

  elseif event == "AUCTION_HOUSE_CLOSED" and self.doingFullScan then
    self:UnregisterForEvents()
    self.doingFullScan = false
    addonTable.Utilities.Message(addonTable.Locales.FULL_SCAN_FAILED_SUMMARY)
    addonTable.CallbackRegistry:TriggerEvent("ScanFail")
  end
end

function addonTable.Scanning.Modern.BrowseMixin:IsAutoscanReady()
  local timeSinceLastScan = time() - (self.state.TimeOfLastFree)

  return timeSinceLastScan >= (addonTable.Constants.ScanInterval)
end

function addonTable.Scanning.Modern.BrowseMixin:InitiateScan()
  if not self.doingFullScan then
    addonTable.Utilities.Message(addonTable.Locales.STARTING_FULL_SCAN_SUMMARY)
    self:RegisterForEvents()
    self.state.TimeOfLastFree = time()
    addonTable.Wrappers.Modern.SendBrowseQuery({searchString = "", sorts = {}, filters = {}, itemClassFilters = {}})
    self.previousDatabaseCount = addonTable.PriceDatabase:GetItemCount()
    self.doingFullScan = true

    addonTable.CallbackRegistry:TriggerEvent("ScanStart")
    self:FireProgressEvent()
  else
    addonTable.Utilities.Message(addonTable.Locales.FULL_SCAN_IN_PROGRESS)
  end
end

function addonTable.Scanning.Modern.BrowseMixin:FireProgressEvent()
  local infoCount = 0

  if self.info ~= nil then
    for _, _  in pairs(self.info) do
      infoCount = infoCount + 1
    end
  end

  local dbCount = addonTable.PriceDatabase:GetItemCount()

  -- 10% complete after making the browse request
  local progress = 0.1

  if dbCount == 0 then
    -- 50% done if we don't have anything in the database
    progress = 0.5
  elseif dbCount > infoCount then
    -- 10%-90% complete when processing browse results
    progress = progress + 0.8 * infoCount / dbCount
  else
    -- 90% if got more browse results than prices already in the database
    progress = 0.9
  end

  addonTable.CallbackRegistry:TriggerEvent("ScanProgress", progress)
end

function addonTable.Scanning.Modern.BrowseMixin:AddPrices(results)
  for _, resultInfo in ipairs(results) do
    if resultInfo.totalQuantity ~= 0 then
      local allDBKeys = addonTable.Storage.Modern.DBKeyFromItemKey(resultInfo.itemKey)

      for index, dbKey in ipairs(allDBKeys) do
        if self.info[dbKey] == nil then
          self.info[dbKey] = {}
        end

        table.insert(self.info[dbKey],
          { price = resultInfo.minPrice, available = resultInfo.totalQuantity }
        )
      end
      table.insert(self.rawScan, resultInfo)
    end
  end

  self:FireProgressEvent()
end

function addonTable.Scanning.Modern.BrowseMixin:NextStep()
  if not addonTable.Wrappers.Modern.HasFullBrowseResults() then
    addonTable.Wrappers.Modern.RequestMoreBrowseResults()
  else
    self:UnregisterForEvents()
    local count = addonTable.PriceDatabase:ProcessScan(self.info)
    local rawScan = self.rawScan

    self.info = {} --Already processed, so clear
    self.rawScan = {}

    addonTable.Utilities.Message(addonTable.Locales.FINISHED_PROCESSING:format(count))
    self.doingFullScan = false

    addonTable.CallbackRegistry:TriggerEvent("ScanComplete", rawScan)
    addonTable.CallbackRegistry:TriggerEvent("PricesUpdated")
  end
end
