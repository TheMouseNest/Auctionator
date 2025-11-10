---@class addonTableAuctionator
local addonTable = select(2, ...)

function addonTable.Wrappers.Legacy.Initialize()
  addonTable.Wrappers.Internals = {}

  addonTable.Wrappers.Internals.throttling = addonTable.Utilities.InitFrameWithMixin(AuctionHouseFrame, addonTable.Wrappers.Legacy.ThrottlingMixin)

  addonTable.Wrappers.Internals.scan = addonTable.Utilities.InitFrameWithMixin(AuctionHouseFrame, addonTable.Wrappers.Legacy.ScanMixin)

  addonTable.Wrappers.Queue = CreateAndInitFromMixin(addonTable.Wrappers.QueueMixin)
end
