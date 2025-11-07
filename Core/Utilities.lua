---@class addonTableAuctionator
local addonTable = select(2, ...)

function addonTable.Utilities.Message(text)
  print(LIGHTBLUE_FONT_COLOR:WrapTextInColorCode("Auctionator") .. ": " .. text)
end

do
  local callbacksPending = {}
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", function(_, _, addonName)
    if callbacksPending[addonName] then
      for _, cb in ipairs(callbacksPending[addonName]) do
        xpcall(cb, CallErrorHandler)
      end
      callbacksPending[addonName] = nil
    end
  end)

  local AddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

  -- Necessary because cannot nest EventUtil.ContinueOnAddOnLoaded
  function addonTable.Utilities.OnAddonLoaded(addonName, callback)
    if select(2, AddOnLoaded(addonName)) then
      xpcall(callback, CallErrorHandler)
    else
      callbacksPending[addonName] = callbacksPending[addonName] or {}
      table.insert(callbacksPending[addonName], callback)
    end
  end
end

do
  local callbacksPending = {}
  local isOpen = false
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("AUCTION_HOUSE_SHOW")
  frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
  frame:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
      isOpen = true
      for _, cb in ipairs(callbacksPending) do
        xpcall(cb, CallErrorHandler)
      end
      callbacksPending = {}
    else
      isOpen = false
    end
  end)

  function addonTable.Utilities.OnAuctionHouseLoaded(callback)
    if isOpen then
      xpcall(callback, CallErrorHandler)
    else
      table.insert(callbacksPending, callback)
    end
  end
end

local queue = {}
local reporter = CreateFrame("Frame")
function reporter:OnUpdate()
  if #queue > 0 then
    for _, entry in ipairs(queue) do
      print(entry[1], entry[2])
    end
    queue = {}
  else
    self:SetScript("OnUpdate", nil)
  end
end
function addonTable.Utilities.DebugOutput(label, value)
  table.insert(queue, {label, value})
  reporter:SetScript("OnUpdate", reporter.OnUpdate)
end

local pendingItems = {}
local itemFrame = CreateFrame("Frame")
itemFrame.elapsed = 0
itemFrame:SetScript("OnEvent", function(_, _, itemID)
  if pendingItems[itemID] ~= nil then
    addonTable.ReportEntry()
    local forItemID = pendingItems[itemID]
    pendingItems[itemID] = nil
    for _, callback in ipairs(forItemID) do
      callback()
    end
  end
end)
itemFrame.OnUpdate = function(self, elapsed)
  itemFrame.elapsed = itemFrame.elapsed + elapsed
  if itemFrame.elapsed > 0.4 then
    for itemID in pairs(pendingItems) do
      C_Item.RequestLoadItemDataByID(itemID)
    end
    itemFrame.elapsed = 0
  end

  if next(pendingItems) == nil then
    itemFrame.elapsed = 0
    self:SetScript("OnUpdate", nil)
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
  end
end

function addonTable.Utilities.LoadItemData(itemID, callback)
  pendingItems[itemID] = pendingItems[itemID] or {}
  table.insert(pendingItems[itemID], callback)
  itemFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
  itemFrame:SetScript("OnUpdate", itemFrame.OnUpdate)
  C_Item.RequestLoadItemDataByID(itemID)
end

function addonTable.Utilities.InitFrameWithMixin(parent, mixin)
  local f = CreateFrame("Frame", nil, parent)
  Mixin(f, mixin)
  f:OnLoad()
  return f
end

function addonTable.Utilities.IsEquipment(classID)
  return classID and (classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Profession)
end

function addonTable.Utilities.InsertLink(link)
  if link ~= nil then
    if ChatFrameUtil and ChatFrameUtil.InsertLink then
      if not C_ChatInfo.InChatMessagingLockdown or not C_ChatInfo.InChatMessagingLockdown() then
        ChatFrameUtil.InsertLink(link)
      end
    else
      ChatEdit_InsertLink(link)
    end
  end
end
