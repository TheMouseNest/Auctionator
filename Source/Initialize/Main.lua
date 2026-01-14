local AUCTIONATOR_EVENTS = {
  -- Addon Initialization Events
  "PLAYER_LOGIN",
  "ADDON_LOADED",
  -- Import list events
  -- "CHAT_MSG_ADDON"
}

AuctionatorInitializeMixin = {}

function AuctionatorInitializeMixin:OnLoad()
  Auctionator.Debug.Message("Auctionator.Events.CoreFrameLoaded")
  C_ChatInfo.RegisterAddonMessagePrefix("Auctionator")

  FrameUtil.RegisterFrameForEvents(self, AUCTIONATOR_EVENTS)
end

function AuctionatorInitializeMixin:OnEvent(event, ...)
  -- Auctionator.Debug.Message("AuctionatorInitializeMixin", event, ...)
  if event == "PLAYER_LOGIN" then
    Auctionator.Variables.InitializeLate()
  elseif event == "ADDON_LOADED" and (...) == "Auctionator" then
    Auctionator.Variables.Initialize()

    Auctionator.SlashCmd.Initialize()
  elseif event == "CHAT_MSG_ADDON" then
    -- For now, just drop the message - we
    -- need to aggregate the messages and provide a pop up
    -- asking people if they want to import
  end
end

function AuctionatorInitializeMixin:AddonDataLoaded(event, ...)
  Auctionator.Debug.Message("AuctionatorInitializeMixin:VariablesLoaded")
end
