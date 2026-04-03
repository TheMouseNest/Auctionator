---@class addonTableAuctionator
local addonTable = select(2, ...)

local function GetCopper(amount)
  return amount % 100
end

local function GetSilver(amount)
  return (amount % 10000 - GetCopper(amount)) / 100
end

local function GetGold(amount)
  return (amount - GetSilver(amount) * 100 - GetCopper(amount)) / 10000
end

local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"
local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t"
local leftPadding = " "
local rightPadding = " "

function addonTable.Tooltips.Utilities.CreatePaddedMoneyString(amount)
  amount = math.floor(amount)

  local gold, silver, copper = GetGold(amount), GetSilver(amount), GetCopper(amount)

  local result = copper .. leftPadding .. copperIcon

  if (gold ~= 0 or silver ~= 0) and copper < 10 then
    result = "0" .. result
  end

  if silver ~= 0 or gold ~= 0 then
    result = silver .. leftPadding .. silverIcon .. rightPadding .. result
  end

  if gold ~= 0 and silver < 10 then
    result = "0" .. result
  end

  if gold ~= 0 then
    result = gold .. leftPadding .. goldIcon .. rightPadding ..result
  end

  return result
end
