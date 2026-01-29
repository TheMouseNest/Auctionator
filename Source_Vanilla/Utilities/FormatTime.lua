if not Auctionator.Constants.IsVanilla then
	return
end

-- Formatter found in Blizzard_AuctionHouseUtil.lua
local formatter = CreateFromMixins(SecondsFormatterMixin);
formatter:Init(0, SecondsFormatter.Abbreviation.OneLetter, true);
formatter:SetStripIntervalWhitespace(true);

function formatter:GetDesiredUnitCount(seconds)
	return 1;
end

function formatter:GetMinInterval(seconds)
	return SecondsFormatter.Interval.Minutes
end

function formatter:GetMaxInterval()
  return SecondsFormatter.Interval.Hours
end

local hour = 60 * 60
local SHORT     = "<" .. formatter:Format(hour/2) -- <30m
local MEDIUM    = formatter:Format(hour/2) .. " - " .. formatter:Format(hour * 2)     -- 30m - 2h
local LONG      = formatter:Format(hour * 2) .. " - " .. formatter:Format(hour * 8)  -- 2h - 8h
local VERY_LONG = formatter:Format(hour * 8) .. " - " .. formatter:Format(hour * 24) -- 8h - 24h

function Auctionator.Utilities.FormatTimeLeftBand(timeLeftBand)
	if timeLeftBand == Enum.AuctionHouseTimeLeftBand.Short then
		return RED_FONT_COLOR:WrapTextInColorCode(SHORT)
	elseif timeLeftBand == Enum.AuctionHouseTimeLeftBand.Medium then
		return MEDIUM
	elseif timeLeftBand == Enum.AuctionHouseTimeLeftBand.Long then
		return LONG
	elseif timeLeftBand == Enum.AuctionHouseTimeLeftBand.VeryLong then
		return VERY_LONG
	end

	return ""
end
