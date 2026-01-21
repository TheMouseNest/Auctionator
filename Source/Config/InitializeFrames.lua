function Auctionator.Config.InternalInitializeFrames(templateNames)
  for _, name in ipairs(templateNames) do
    CreateFrame(
      "FRAME",
      "AuctionatorConfig" .. name .. "Frame",
      SettingsPanel,
      "AuctionatorConfig" .. name .. "FrameTemplate")
  end
end
