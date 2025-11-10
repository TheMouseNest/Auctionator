---@class addonTableAuctionator
local _, addonTable = ...

addonTable.Wrappers.Legacy.ScanMixin = {}

local SCAN_EVENTS = {
  "AUCTION_ITEM_LIST_UPDATE",
}

local function ParamsForBlizzardAPI(query, page)
  return query.searchString, query.minLevel, query.maxLevel, page, nil, query.quality, false, query.isExact or false, query.itemClassFilters
end

function addonTable.Wrappers.Legacy.ScanMixin:OnLoad()
  self:SetScript("OnEvent", self.OnEvent)

  self.scanRunning = false
end

function addonTable.Wrappers.Legacy.ScanMixin:IsOnLastPage()
  --Loaded all the terms from API
  return (
    (self.endPage ~= -1 and self.nextPage > self.endPage) or
    GetNumAuctionItems("list") < addonTable.Constants.MaxResultsPerPage
  )
end

function addonTable.Wrappers.Legacy.ScanMixin:GotAllOwners()
  local result = true
  local allAuctions = addonTable.Wrappers.Legacy.DumpAuctions("list")
  for _, auction in ipairs(allAuctions) do
    result = result and auction.info[addonTable.Constants.AuctionItemInfo.Owner] ~= nil
  end

  return result
end

function addonTable.Wrappers.Legacy.ScanMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_ITEM_LIST_UPDATE" and self.waitingOnPage and self.sentQuery and self:GotAllOwners() then
    self.waitingOnPage = false
    self:ProcessSearchResults()
  end
end

function addonTable.Wrappers.Legacy.ScanMixin:StartQuery(query, startPage, endPage)
  if self.scanRunning then
    error("Scan already running")
  end
  self:RegisterEvents()

  self.scanRunning = true

  self.nextPage = startPage
  self.endPage = endPage
  self.query = query
  self:DoNextSearchQuery()
end

function addonTable.Wrappers.Legacy.ScanMixin:AbortQuery()
  if self.scanRunning then
    addonTable.Wrappers.Queue:Remove(self.lastQueuedItem)
    self.scanRunning = false
    self:UnregisterEvents()
    addonTable.CallbackRegistry("ScanAborted")
  end
end

function addonTable.Wrappers.Legacy.ScanMixin:DoNextSearchQuery()
  local page = self.nextPage
  self.sentQuery = false

  self.lastQueuedItem = function()
    self.sentQuery = true
    SortAuctionSetSort("list", "unitprice")
    QueryAuctionItems(ParamsForBlizzardAPI(self.query, page))
  end
  addonTable.Wrappers.Queue:Enqueue(self.lastQueuedItem)

  self.waitingOnPage = true
  self.nextPage = self.nextPage + 1

  addonTable.CallbackRegistry:TriggerEvent("ScanPageStart", page)
end

function addonTable.Wrappers.Legacy.ScanMixin:ProcessSearchResults()
  local results = self:GetCurrentPage()

  if self:IsOnLastPage() then
    self.scanRunning = false
    self:UnregisterEvents()
  else
    self:DoNextSearchQuery()
  end
  addonTable.CallbackRegistry:TriggerEvent("ScanResultsUpdate", results, not self.scanRunning)
end

function addonTable.Wrappers.Legacy.ScanMixin:GetCurrentPage()
  local results = addonTable.Wrappers.Legacy.DumpAuctions("list")
  for _, entry in ipairs(results) do
    entry.query = self.query
    entry.page = self.nextPage - 1
  end

  return results
end

function addonTable.Wrappers.Legacy.ScanMixin:RegisterEvents()
  FrameUtil.RegisterFrameForEvents(self, SCAN_EVENTS)

  addonTable.CallbackRegistry:RegisterCallback("ThrottleAbort", self.AbortQuery, self)
end

function addonTable.Wrappers.Legacy.ScanMixin:UnregisterEvents()
  FrameUtil.UnregisterFrameForEvents(self, SCAN_EVENTS)

  addonTable.CallbackRegistry:UnregisterCallback("ThrottleAbort", self)
end
