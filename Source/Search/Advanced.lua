-- Extract components of an advanced search string.
-- Assumes searchParametersString is an advanced search.
function Auctionator.Search.SplitAdvancedSearch(searchParametersString)
  local queryString, categoryKey, minItemLevel, maxItemLevel, minLevel, maxLevel,
    minCraftedLevel, maxCraftedLevel, minPrice, maxPrice, quality, tier,
    expansion, quantity =
    strsplit( Auctionator.Constants.AdvancedSearchDivider, searchParametersString )

  -- A nil queryString causes a disconnect if searched for, but an empty one
  -- doesn't, this ensures searchString ~= nil.
  if queryString == nil then
    queryString = ""
  end

  -- Remove "" that are used in exact searches as it causes some searches to
  -- fail when they would otherwise work, example "Steak a la Mode"
  local searchString = string.gsub(queryString, "^\"(.*)\"$", "%1")

  local isExact = string.match(queryString, "^\"(.*)\"$") ~= nil

  if categoryKey == nil then
    categoryKey = ""
  end

  minLevel = tonumber( minLevel )
  maxLevel = tonumber( maxLevel )
  minItemLevel = tonumber( minItemLevel )
  maxItemLevel = tonumber( maxItemLevel )

  minCraftedLevel = tonumber( minCraftedLevel )
  maxCraftedLevel = tonumber( maxCraftedLevel )

  minPrice = (tonumber(minPrice) or 0) * 10000
  maxPrice = (tonumber(maxPrice) or 0) * 10000

  quality = tonumber( quality )
  tier = tonumber( tier )
  expansion = tonumber( expansion )

  quantity = tonumber( quantity )

  if minLevel == 0 then
    minLevel = nil
  end

  if maxLevel == 0 then
    maxLevel = nil
  end

  if minItemLevel == 0 then
    minItemLevel = nil
  end

  if maxItemLevel == 0 then
    maxItemLevel = nil
  end

  if minCraftedLevel == 0 then
    minCraftedLevel = nil
  end

  if maxCraftedLevel == 0 then
    maxCraftedLevel = nil
  end

  if minPrice == 0 then
    minPrice = nil
  end

  if maxPrice == 0 then
    maxPrice = nil
  end

  if quantity == 0 then
    quantity = nil
  end

  return {
    searchString = searchString,
    isExact = isExact,
    categoryKey = categoryKey,
    minLevel = minLevel,
    maxLevel = maxLevel,
    minPrice = minPrice,
    maxPrice = maxPrice,
    minItemLevel = minItemLevel,
    maxItemLevel = maxItemLevel,
    minCraftedLevel = minCraftedLevel,
    maxCraftedLevel = maxCraftedLevel,
    quality = quality,
    tier = tier,
    expansion = expansion,
    quantity = quantity,
  }
end

local function RangeOptionString(name, min, max)
  if min ~= nil and min == max then
    return name .. " = " .. tostring(max)
  elseif min ~= nil and max ~= nil then
    return name .. " " ..  tostring(min) .. "-" ..  tostring(max)
  elseif min ~= nil then
    return name .. " >= " .. tostring(min)
  elseif max ~= nil then
    return name .. " <= " .. tostring(max)
  else
    return ""
  end
end

local function TooltipRangeString(min, max)
  if min ~= nil and min == max then
    return tostring(max)
  elseif min ~= nil and max ~= nil then
    return tostring(min) .. "-" ..  tostring(max)
  elseif min ~= nil then
    return ">= " .. tostring(min)
  elseif max ~= nil then
    return "<= " .. tostring(max)
  else
    return AUCTIONATOR_L_ANY_LOWER
  end
end

local function QuantityString(quantity)
  if quantity ~= nil then
    return LIGHTBLUE_FONT_COLOR:WrapTextInColorCode("x" .. quantity)
  else
    return ""
  end
end

local function QualityString(quality)
  if quality ~= nil and ITEM_QUALITY_COLORS[quality] ~= nil then
    return Auctionator.Utilities.CreateColoredQuality(quality)
  else
    return ""
  end
end

local function TierString(tier)
  if Auctionator.Constants.IsRetail and tier ~= nil then
    return Auctionator.Utilities.GetCraftingQualityMarkup(tier)
  else
    return ""
  end
end

local function ExpansionString(expansion)
  if expansion ~= nil then
    return _G["EXPANSION_NAME" .. expansion] or ""
  else
    return ""
  end
end

local separator = ", "

local function CategoryKey(splitSearch)
  return splitSearch.categoryKey .. separator
end

local function Quality(splitSearch)
  return QualityString(splitSearch.quality) .. separator
end

local function Quantity(splitSearch)
  return QuantityString(splitSearch.quantity) .. separator
end

local function Tier(splitSearch)
  return TierString(splitSearch.tier) .. separator
end

local function Expansion(splitSearch)
  return ExpansionString(splitSearch.expansion) .. separator
end

local function ItemLevelRange(splitSearch)
  return RangeOptionString(
    "ilvl",
    splitSearch.minItemLevel,
    splitSearch.maxItemLevel
  ) .. separator
end

local function CraftedLevelRange(splitSearch)
  return RangeOptionString(
    "clvl",
    splitSearch.minCraftedLevel,
    splitSearch.maxCraftedLevel
  ) .. separator
end

local function LevelRange(splitSearch)
  return RangeOptionString(
    "lvl",
    splitSearch.minLevel,
    splitSearch.maxLevel
  ) .. separator
end
local function ConvertMoneyStrings(splitSearch)
  -- Convert to money strings
  -- Some padding " " is necessary
  local min = splitSearch.minPrice
  if min ~= nil then
    min = GetMoneyString(min, true) .. " "
  end

  local max = splitSearch.maxPrice
  if max ~= nil then
    max = GetMoneyString(splitSearch.maxPrice, true) .. " "
  end

  return min, max
end

local function PriceRange(splitSearch)
  local min, max = ConvertMoneyStrings(splitSearch)

  return RangeOptionString(
    "price",
    min,
    max
  ) .. separator
end

local function WrapExactSearch(splitSearch)
  if splitSearch.isExact then
    return "\"" .. splitSearch.searchString .. "\""
  else
    return splitSearch.searchString
  end
end

function Auctionator.Search.PrettifySearchString(searchString)
  local splitSearch = Auctionator.Search.SplitAdvancedSearch(searchString)

  local result = WrapExactSearch(splitSearch)
    .. " ["
    .. CategoryKey(splitSearch)
    .. PriceRange(splitSearch)
    .. LevelRange(splitSearch)
    .. ItemLevelRange(splitSearch)
    .. Quantity(splitSearch)
    .. CraftedLevelRange(splitSearch)
    .. Expansion(splitSearch)
    .. Quality(splitSearch)
    .. Tier(splitSearch)
    .. "]"

  -- Clean up string removing empty stuff
  result = string.gsub(result ," ,", "")
  result = string.gsub(result ,"%[, ", "[")
  result = string.gsub(result ,"^ %[", "[")
  result = string.gsub(result ,", %]", "]")
  result = string.gsub(result ," %[%]$", "")

  return result
end

local function TooltipCategory(splitSearch)
  local key = splitSearch.categoryKey

  if splitSearch.categoryKey == nil or splitSearch.categoryKey == "" then
    key = AUCTIONATOR_L_ANY_LOWER
  end

  return {
    AUCTIONATOR_L_ITEM_CLASS,
    key
  }
end

local function TooltipExpansion(splitSearch)
  local key

  if splitSearch.expansion == nil then
    key = AUCTIONATOR_L_ANY_LOWER
  else
    key = _G["EXPANSION_NAME" .. splitSearch.expansion] or AUCTIONATOR_L_UNKNOWN
  end

  return {
    AUCTIONATOR_L_EXPANSION,
    key
  }
end

local function TooltipQuality(splitSearch)
  local key

  if splitSearch.quality == nil or ITEM_QUALITY_COLORS[splitSearch.quality] == nil then
    key = AUCTIONATOR_L_ANY_LOWER
  else
    key = Auctionator.Utilities.CreateColoredQuality(splitSearch.quality)
  end

  return {
    QUALITY,
    key
  }
end

local function TooltipQuantity(splitSearch)
  local key = splitSearch.quantity

  if splitSearch.quantity == nil then
    key = AUCTIONATOR_L_ANY_LOWER
  end

  return {
    AUCTIONATOR_L_QUANTITY,
    key
  }
end

local function TooltipTier(splitSearch)
  local key

  if not Auctionator.Constants.IsRetail or splitSearch.tier == nil then
    key = AUCTIONATOR_L_ANY_LOWER
  else
    key = Auctionator.Utilities.GetCraftingQualityMarkup(splitSearch.tier)
  end

  return {
    AUCTIONATOR_L_TIER,
    key
  }
end

local function TooltipPriceRange(splitSearch)
  local minPrice, maxPrice = ConvertMoneyStrings(splitSearch)

  return {
    AUCTIONATOR_L_PRICE,
    TooltipRangeString(minPrice, maxPrice)
  }
end

local function TooltipLevelRange(splitSearch)
  return {
    AUCTIONATOR_L_LEVEL,
    TooltipRangeString(splitSearch.minLevel, splitSearch.maxLevel)
  }
end

local function TooltipItemLevelRange(splitSearch)
  return {
    AUCTIONATOR_L_ITEM_LEVEL,
    TooltipRangeString(splitSearch.minItemLevel, splitSearch.maxItemLevel)
  }
end

local function TooltipCraftedLevelRange(splitSearch)
  return {
    AUCTIONATOR_L_CRAFTED_LEVEL,
    TooltipRangeString(splitSearch.minCraftedLevel, splitSearch.maxCraftedLevel)
  }
end

function Auctionator.Search.ComposeTooltip(searchString)
  local splitSearch = Auctionator.Search.SplitAdvancedSearch(searchString)

  local lines = {}

  table.insert(lines, TooltipCategory(splitSearch))
  table.insert(lines, TooltipPriceRange(splitSearch))
  table.insert(lines, TooltipLevelRange(splitSearch))
  table.insert(lines, TooltipItemLevelRange(splitSearch))
  table.insert(lines, TooltipQuantity(splitSearch))
  table.insert(lines, TooltipCraftedLevelRange(splitSearch))
  table.insert(lines, TooltipQuality(splitSearch))
  if Auctionator.Constants.IsRetail then
    table.insert(lines, TooltipExpansion(splitSearch))
    table.insert(lines, TooltipTier(splitSearch))
  end

  if splitSearch.searchString == "" then
    splitSearch.searchString = " "
  end

  return {
    title = splitSearch.searchString,
    lines = lines
  }
end

local function GetQueryString(search)
  if search.isExact then
    return "\"" .. search.searchString .. "\""
  else
    return search.searchString
  end
end
function Auctionator.Search.ReconstituteAdvancedSearch(search)
  return strjoin(";",
    GetQueryString(search),
    search.categoryKey or "",
    tostring(search.minItemLevel or ""),
    tostring(search.maxItemLevel or ""),
    tostring(search.minLevel or ""),
    tostring(search.maxLevel or ""),
    tostring(search.minCraftedLevel or ""),
    tostring(search.maxCraftedLevel or ""),
    tostring(((search.minPrice and search.minPrice / 10000) or "")),
    tostring(((search.maxPrice and search.maxPrice / 10000) or "")),
    tostring(search.quality or ""),
    tostring(search.tier or "#"),
    tostring(search.expansion or ""),
    tostring(search.quantity ~= 0 and search.quantity or "")
  )
end
