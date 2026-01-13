---@class addonTableAuctionator
local addonTable = select(2, ...)

local lines = {
  {option = addonTable.Config.Options.TOOLTIPS_VENDOR, func = AddVendorDetails, use = true},
  {option = addonTable.Config.Options.TOOLTIPS_AUCTION, func = AddAuctionDetails, use = true},
  {option = addonTable.Config.Options.TOOLTIPS_AUCTION_AGE, func = AddAuctionAgeDetails, use = true},

  {option = addonTable.Config.Options.TOOLTIPS_ENCHANT, func = AddEnchantDetails, use = addonTable.Constants.IsClassic},
  {option = addonTable.Config.Options.TOOLTIPS_PROSPECT, func = AddProspectDetails, use = addonTable.Constants.IsClassic},
  {option = addonTable.Config.Options.TOOLTIPS_MILL, func = AddMillDetails, use = addonTable.Constants.IsClassic},
}

function addonTable.Tooltips.AddLines(tooltip, dbKey)
  for _, l in ipairs(lines) do
    if addonTable.Config.Get(l.option) then
      l.func(tooltip, dbKey)
    end
  end
end
