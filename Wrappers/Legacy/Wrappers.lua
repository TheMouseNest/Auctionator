---@class addonTableAuctionator
local addonTable = select(2, ...)

-- query = {
--   searchString -> string
--   minLevel -> int?
--   maxLevel -> int?
--   itemClassFilters -> itemClassFilter[]
--   isExact -> boolean?
-- }
function addonTable.Wrappers.Legacy.QueryAuctionItems(query)
  addonTable.Wrappers.Legacy.Internals.scan:StartQuery(query, 0, -1)
end

function addonTable.Wrappers.Legacy.QueryAndFocusPage(query, page)
  addonTable.Wrappers.Legacy.Internals.scan:StartQuery(query, page, page)
end

function addonTable.Wrappers.Legacy.GetCurrentPage()
  return addonTable.Wrappers.Legacy.Internals.scan:GetCurrentPage()
end

function addonTable.Wrappers.Legacy.AbortQuery()
  addonTable.Wrappers.Legacy.Internals.scan:AbortQuery()
end

-- Event ThrottleUpdate will fire whenever the state changes
function addonTable.Wrappers.Legacy.IsNotThrottled()
  return addonTable.Wrappers.Legacy.Internals.throttling:IsReady()
end

function addonTable.Wrappers.Legacy.GetAuctionItemSubClasses(classID)
  return { GetAuctionItemSubClasses(classID) }
end

function addonTable.Wrappers.Legacy.PlaceAuctionBid(...)
  addonTable.Wrappers.Legacy.Internals.throttling:BidPlaced()
  PlaceAuctionBid("list", ...)
end

function addonTable.Wrappers.Legacy.PostAuction(...)
  addonTable.Wrappers.Legacy.Internals.throttling:AuctionsPosted()
  PostAuction(...)
end

-- view is a string and must be "list", "owner" or "bidder"
function addonTable.Wrappers.Legacy.DumpAuctions(view)
  local auctions = {}
  for index = 1, GetNumAuctionItems(view) do
    local auctionInfo = { GetAuctionItemInfo(view, index) }
    local itemLink = GetAuctionItemLink(view, index)
    local timeLeft = GetAuctionItemTimeLeft(view, index)
    local entry = {
      info = auctionInfo,
      itemLink = itemLink,
      timeLeft = timeLeft - 1, --Offset to match Retail time parameters
      index = index,
    }
    table.insert(auctions, entry)
  end
  return auctions
end

function addonTable.Wrappers.Legacy.CancelAuction(auction)
  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }

    local stackPrice = info[addonTable.Constants.AuctionItemInfo.Buyout]
    local stackSize = info[addonTable.Constants.AuctionItemInfo.Quantity]
    local bidAmount = info[addonTable.Constants.AuctionItemInfo.BidAmount]
    local saleStatus = info[addonTable.Constants.AuctionItemInfo.SaleStatus]
    local itemLink = GetAuctionItemLink("owner", index)

    if saleStatus ~= 1 and auction.bidAmount == bidAmount and auction.stackPrice == stackPrice and auction.stackSize == stackSize and addonTable.Utilities.GetCleanItemLink(itemLink) == addonTable.Utilities.GetCleanItemLink(auction.itemLink) then
      addonTable.Wrappers.Legacy.Internals.throttling:AuctionCancelled()
      CancelAuction(index)
      break
    end
  end
end
