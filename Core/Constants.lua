---@class addonTableAuctionator
local _, addonTable = ...

addonTable.Constants = {
  AdvancedSearchDivider = ';',

  PetCageID = 82800,
  WoWTokenID = 122270,

  ScanDay0 = time({year=2020, month=1, day=1, hour=0}),

  ScanInterval = 15 * 60,

  Sort = {
    Ascending = 1,
    Descending = 0
  },
  ItemType = {
    Item = 1,
    Commodity = 2
  },
  OldSlotTypes = {
    Enum.InventoryType.IndexHeadType,
    Enum.InventoryType.IndexShoulderType,
    Enum.InventoryType.IndexChestType,
    Enum.InventoryType.IndexWaistType,
    Enum.InventoryType.IndexLegsType,
    Enum.InventoryType.IndexFeetType,
    Enum.InventoryType.IndexWristType,
    Enum.InventoryType.IndexHandType,
  },
  NoList = "",

  ShoppingListViews = {
    Lists = 1,
    Recents = 2,
  },

  RecentsListLimit = 30,

  Durations = {
    Short = 1,
    Medium = 2,
    Long = 3,
  },

  ItemMatching = {
    Full = "full",
    BaseOnly = "base",
  },

  UndercutType = {
    Percentage = "percentage",
    Static = "static"
  },

  Shortcuts = {
    LeftClick = "left click",
    RightClick = "right click",
    AltLeftClick = "alt left click",
    ShiftLeftClick = "shift left click",
    AltRightClick = "alt right click",
    ShiftRightClick = "shift right click",
    None = "none",
  },

  AfterAHCut = 0.95,

  IsLegacyAH = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or IsUsingLegacyAuctionClient ~= nil and IsUsingLegacyAuctionClient(),
  IsModernAH = WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and (IsUsingLegacyAuctionClient == nil or not IsUsingLegacyAuctionClient()),

  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,
  IsVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,

  EnchantingVellumID = 38682,
}

if addonTable.Constants.IsModernAH then
  addonTable.Constants.ShoppingSorts = {
    {sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false},
    {sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = true}
  }
  addonTable.Constants.CommodityResultsSorts = {sortOrder = 0, reverseSort = false}
  addonTable.Constants.ItemResultsSorts = {sortOrder = 4, reverseSort = false}
  addonTable.Constants.SummaryBatchSize = 500
end

if addonTable.Constants.IsLegacyAH then
  addonTable.Constants.AuctionItemInfo = {
    Buyout = 10,
    Quantity = 3,
    Owner = 14,
    ItemID = 17,
    Level = 6,
    MinBid = 8,
    BidAmount = 11,
    Bidder = 12,
    SaleStatus = 16,
  }

  addonTable.Constants.PriceIncreaseWarningDuration = 5
  addonTable.Constants.PriceIncreaseWarningThreshold = 40
  addonTable.Constants.MaxResultsPerPage = 50
end

if addonTable.Constants.IsRetail then

  addonTable.Constants.SellingBagIconSize = 42
  addonTable.Constants.ItemLevelThreshold = 168
  addonTable.Constants.QualityIDs = {
    Enum.ItemQuality.Poor,
    Enum.ItemQuality.Common,
    Enum.ItemQuality.Uncommon,
    Enum.ItemQuality.Rare,
    Enum.ItemQuality.Epic,
    Enum.ItemQuality.Legendary,
    Enum.ItemQuality.Artifact,
  }
  addonTable.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Gem,
    Enum.ItemClass.ItemEnhancement,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Profession,
    Enum.ItemClass.Battlepet,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Miscellaneous,
  }
else

  addonTable.Constants.SellingBagIconSize = 35
  addonTable.Constants.ItemLevelThreshold = 0
  addonTable.Constants.QualityIDs = {
    Enum.ItemQuality.Poor,
    Enum.ItemQuality.Standard,
    Enum.ItemQuality.Good,
    Enum.ItemQuality.Rare,
    Enum.ItemQuality.Epic,
  }
end

addonTable.Constants.Events = {
  "RequestScan",
  "ScanStart",
  "ScanProgress",
  "ScanComplete",
  "ScanFail",

  "AuctionCreated",

  "PricesUpdated",

  "ShoppingListItemChange",
  "ShoppingListMetaChange",

  "ThrottleReady",
  "ThrottleUpdate",

  "CurrentThrottleTimeout", -- Legacy
  "ThrottleAbort", -- Legacy
  "ScanPageStart", -- Legacy
  "ScanResultsUpdate", -- Legacy
  "ScanPageReady", -- Legacy
  "ScanAborted", -- Legacy

  "WrappedCommodityResultsReady", -- Modern
  "WrappedItemResultsReady", -- Modern

  "SkinLoaded",

  "ShowCustomise",
}

Auctionator.Constants = CopyTable(addonTable.Constants)
