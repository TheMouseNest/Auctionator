AuctionatorShoppingTabFrameMixin = {}

local EVENTBUS_EVENTS = {
  Auctionator.Shopping.Events.ListImportFinished,
  Auctionator.Shopping.Tab.Events.ListSearchRequested,
  Auctionator.Shopping.Tab.Events.ShowHistoricalPrices,
  Auctionator.Shopping.Tab.Events.UpdateSearchTerm,
  Auctionator.Shopping.Tab.Events.BuyScreenShown,
}

function AuctionatorShoppingTabFrameMixin:DoSearch(terms, options)
  if #terms == 0 then
    return
  end

  if options == nil and Auctionator.Constants.IsLegacyAH and IsShiftKeyDown() then
    options = { searchAllPages = true }
  end

  self:StopSearch()

  self.searchRunning = true
  Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.SearchStart, terms)
  self.SearchProvider:Search(terms, options or {})
  self:StartSpinner()
end

function AuctionatorShoppingTabFrameMixin:StopSearch()
  self.searchRunning = false
  self.SearchProvider:AbortSearch()
end

function AuctionatorShoppingTabFrameMixin:StartSpinner()
  self.ListsContainer.SpinnerAnim:Play()
  self.ListsContainer.LoadingSpinner:Show()
  self.ListsContainer.ResultsText:SetText(Auctionator.Locales.Apply("LIST_SEARCH_START", self:GetAppropriateListSearchName()))
  self.ListsContainer.ResultsText:Show()
end

function AuctionatorShoppingTabFrameMixin:CloseAnyDialogs()
  for _, d in ipairs(self.dialogs) do
    if d:IsShown() then
      d:Hide()
    end
  end
end

function AuctionatorShoppingTabFrameMixin:OnLoad()
  Auctionator.EventBus:RegisterSource(self, "AuctionatorShoppingTabFrameMixin")

  self.ResultsListing:Init(self.DataProvider)

  self.dialogs = {}

  self.itemDialog = CreateFrame("Frame", "AuctionatorShoppingTabItemFrame", self, "AuctionatorShoppingItemTemplate")
  self.itemDialog:ClearAllPoints()
  self.itemDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.itemDialog)

  self.exportDialog = CreateFrame("Frame", "AuctionatorExportListFrame", self, "AuctionatorExportListTemplate")
  self.exportDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.exportDialog)

  self.importDialog = CreateFrame("Frame", "AuctionatorImportListFrame", self, "AuctionatorImportListTemplate")
  self.importDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.importDialog)

  self.exportCSVDialog = CreateFrame("Frame", nil, self, "AuctionatorExportTextFrame")
  self.exportCSVDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.exportCSVDialog)

  self.ExportButton:SetScript("OnClick", function()
    self:CloseAnyDialogs()
    self.exportDialog:Show()
  end)
  self.ImportButton:SetScript("OnClick", function()
    self:CloseAnyDialogs()
    self.importDialog:Show()
  end)

  self.itemHistoryDialog = CreateFrame("Frame", "AuctionatorItemHistoryFrame", self, "AuctionatorItemHistoryTemplate")
  self.itemHistoryDialog:SetPoint("CENTER")
  self.itemHistoryDialog:Init()

  self:SetupSearchProvider()

  self:SetupListsContainer()
  self:SetupRecentsContainer()
  self:SetupTopSearch()

  self.NewListButton:SetScript("OnClick", function()
    Auctionator.Dialogs.ShowEditBox(AUCTIONATOR_L_CREATE_LIST_DIALOG, ACCEPT, CANCEL, function(text)
      local name = Auctionator.Shopping.ListManager:GetUnusedName(text)
      Auctionator.Shopping.ListManager:Create(name)
      self.ListsContainer:ExpandList(Auctionator.Shopping.ListManager:GetByName(name))
    end)
  end)

  self.ContainerTabs:SetView(Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_LAST_CONTAINER_VIEW))

  self.shouldDefaultOpenOnShow = true
  if Auctionator.Constants.IsVanilla then
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")
  else
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
  end
end

function AuctionatorShoppingTabFrameMixin:SetupSearchProvider()
  self.SearchProvider:InitSearch(
    function(results)
      self.searchRunning = false
      Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.SearchEnd, results)
      self.ListsContainer.SpinnerAnim:Stop()
      self.ListsContainer.LoadingSpinner:Hide()
      self.ListsContainer.ResultsText:Hide()
    end,
    function(current, total, partialResults)
      Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.SearchIncrementalUpdate, partialResults, total, current)
      self.ListsContainer.ResultsText:SetText(Auctionator.Locales.Apply("LIST_SEARCH_STATUS", current, total, self:GetAppropriateListSearchName()))
    end
  )
end

function AuctionatorShoppingTabFrameMixin:SetupListsContainer()
  self.ListsContainer:SetOnListExpanded(function()
    if Auctionator.Config.Get(Auctionator.Config.Options.AUTO_LIST_SEARCH) then
      self.singleSearch = false
      self:DoSearch(self.ListsContainer:GetExpandedList():GetAllItems())
    end
    self.SearchOptions:OnListExpanded()
  end)
  self.ListsContainer:SetOnListCollapsed(function()
    self:StopSearch()
    self.SearchOptions:OnListCollapsed()
  end)
  self.ListsContainer:SetOnSearchTermClicked(function(list, searchTerm, index)
    self.singleSearch = true
    self:DoSearch({searchTerm})
    self.SearchOptions:SetSearchTerm(searchTerm)
    self.ListsContainer:TemporarilySelectSearchTerm(index)
  end)
  self.ListsContainer:SetOnSearchTermDelete(function(list, searchTerm, index)
    list:DeleteItem(index)
  end)
  self.ListsContainer:SetOnSearchTermEdit(function(list, searchTerm, index)
    self:CloseAnyDialogs()
    self.itemDialog:Init(AUCTIONATOR_L_LIST_EDIT_ITEM_HEADER, AUCTIONATOR_L_EDIT_ITEM)
    self.itemDialog:SetOnFinishedClicked(function(newItemString)
      list:AlterItem(index, newItemString)
    end)
    self.itemDialog:Show()
    self.itemDialog:SetItemString(searchTerm)
  end)
  self.ListsContainer:SetOnListSearch(function(list)
    self.singleSearch = false
    self:DoSearch(list:GetAllItems())
  end)
  self.ListsContainer:SetOnListEdit(function(list)
    if list:IsTemporary() then
      Auctionator.Dialogs.ShowEditBox(AUCTIONATOR_L_MAKE_PERMANENT_CONFIRM:format(list:GetName()), ACCEPT, CANCEL, function(text)
        list:Rename(text)
        list:MakePermanent()
        Auctionator.Shopping.ListManager:Sort()
        self.ListsContainer:ScrollToList(list)
      end)
    else
      Auctionator.Dialogs.ShowEditBox(AUCTIONATOR_L_RENAME_LIST_CONFIRM:format(list:GetName()), ACCEPT, CANCEL, function(text)
        list:Rename(text)
        Auctionator.Shopping.ListManager:Sort()
        self.ListsContainer:ScrollToList(list)
      end)
    end
  end)
  self.ListsContainer:SetOnListDelete(function(list)
    Auctionator.Dialogs.ShowConfirm(AUCTIONATOR_L_DELETE_LIST_CONFIRM:format(list:GetName()):gsub("%%", "%%%%"), ACCEPT, CANCEL, function()
      if Auctionator.Shopping.ListManager:GetIndexForName(list:GetName()) ~= nil then
        Auctionator.Shopping.ListManager:Delete(list:GetName())
      end
    end)
  end)

  self.ListsContainer:SetOnListItemDrag(function(list, oldIndex, newIndex)
    if oldIndex ~= newIndex then
      local old = list:GetItemByIndex(oldIndex)
      list:DeleteItem(oldIndex)
      list:InsertItem(old, newIndex)
    end
  end)
end

function AuctionatorShoppingTabFrameMixin:SetupRecentsContainer()
  self.RecentsContainer:SetOnSearchRecent(function(searchTerm)
    self.singleSearch = true
    self:DoSearch({searchTerm})
    self.SearchOptions:SetSearchTerm(searchTerm)
    self.RecentsContainer:TemporarilySelectSearchTerm(searchTerm)
  end)
  self.RecentsContainer:SetOnDeleteRecent(function(searchTerm)
    Auctionator.Shopping.Recents.DeleteEntry(searchTerm)
  end)
  self.RecentsContainer:SetOnCopyRecent(function(searchTerm)
    local list = self.ListsContainer:GetExpandedList()
    if list == nil then
      Auctionator.Utilities.Message(AUCTIONATOR_L_COPY_NO_LIST_SELECTED)
    else
      list:InsertItem(searchTerm)
      Auctionator.Utilities.Message(AUCTIONATOR_L_COPY_ITEM_ADDED:format(
        GREEN_FONT_COLOR:WrapTextInColorCode(Auctionator.Search.PrettifySearchString(searchTerm)),
        GREEN_FONT_COLOR:WrapTextInColorCode(list:GetName())
      ))
    end
  end)
end

function AuctionatorShoppingTabFrameMixin:SetupTopSearch()
  self.SearchOptions:SetOnSearch(function(searchTerm)
    if self.searchRunning then
      self:StopSearch()
    elseif searchTerm == "" and self.ListsContainer:GetExpandedList() ~= nil then
      self:DoSearch(self.ListsContainer:GetExpandedList():GetAllItems())
    else
      self.singleSearch = true
      self:DoSearch({searchTerm})
      Auctionator.Shopping.Recents.Save(searchTerm)
    end
  end)
  self.SearchOptions:SetOnMore(function(searchTerm)
    self:CloseAnyDialogs()
    self.itemDialog:Init(AUCTIONATOR_L_LIST_EXTENDED_SEARCH_HEADER, AUCTIONATOR_L_SEARCH)
    self.itemDialog:SetOnFinishedClicked(function(searchTerm)
      self.SearchOptions:SetSearchTerm(searchTerm)
      self.singleSearch = true
      self:DoSearch({searchTerm})
      Auctionator.Shopping.Recents.Save(searchTerm)
    end)

    self.itemDialog:Show()
    self.itemDialog:SetItemString(searchTerm)
  end)
  self.SearchOptions:SetOnAddToList(function(searchTerm)
    self.ListsContainer:GetExpandedList():InsertItem(searchTerm)
    self.ListsContainer:ScrollToListEnd()
  end)
end

function AuctionatorShoppingTabFrameMixin:GetAppropriateListSearchName()
  if self.singleSearch or not self.ListsContainer:GetExpandedList() then
    return AUCTIONATOR_L_NO_LIST
  else
    return self.ListsContainer:GetExpandedList():GetName()
  end
end

function AuctionatorShoppingTabFrameMixin:ReceiveEvent(eventName, eventData)
  if eventName == Auctionator.Shopping.Events.ListImportFinished then
    self.ListsContainer:ExpandList(Auctionator.Shopping.ListManager:GetByName(eventData))

  elseif eventName == Auctionator.Shopping.Tab.Events.ListSearchRequested then
    self.ContainerTabs:SetView(Auctionator.Constants.ShoppingListViews.Lists)
    self.ListsContainer:ExpandList(eventData)
    if not Auctionator.Config.Get(Auctionator.Config.Options.AUTO_LIST_SEARCH) then
      self.singleSearch = false
      self:DoSearch(eventData:GetAllItems())
    end

  elseif eventName == Auctionator.Shopping.Tab.Events.ShowHistoricalPrices then
    self:CloseAnyDialogs()
    self.itemHistoryDialog:Show()

  elseif eventName == Auctionator.Shopping.Tab.Events.UpdateSearchTerm then
    self.SearchOptions:SetSearchTerm(eventData)

  elseif eventName == Auctionator.Shopping.Tab.Events.BuyScreenShown then
    self:StopSearch()
  end
end

function AuctionatorShoppingTabFrameMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local showType = ...
    if showType == Enum.PlayerInteractionType.Auctioneer then
      self.shouldDefaultOpenOnShow = true
    end
  elseif eventName == "AUCTION_HOUSE_CLOSED" then
    self.shouldDefaultOpenOnShow = true
  end
end

function AuctionatorShoppingTabFrameMixin:OnShow()
  self.SearchOptions:FocusSearchBox()
  Auctionator.EventBus:Register(self, EVENTBUS_EVENTS)

  if self.shouldDefaultOpenOnShow then
    self:OpenDefaultList()
    self.shouldDefaultOpenOnShow = false
  end
end

function AuctionatorShoppingTabFrameMixin:OnHide()
  if self.searchRunning then
    self:StopSearch()
  end
  Auctionator.EventBus:Unregister(self, EVENTBUS_EVENTS)
end

function AuctionatorShoppingTabFrameMixin:ExportCSVClicked()
  self:CloseAnyDialogs()
  self.DataProvider:GetCSV(function(result)
    self.exportCSVDialog:SetExportString(result)
    self.exportCSVDialog:Show()
  end)
end

function AuctionatorShoppingTabFrameMixin:OpenDefaultList()
  local listName = Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_LIST)

  if listName == Auctionator.Constants.NO_LIST then
    return
  end

  local listIndex = Auctionator.Shopping.ListManager:GetIndexForName(listName)

  if listIndex ~= nil then
    self.ListsContainer:CollapseList()
    self.ContainerTabs:SetView(Auctionator.Constants.ShoppingListViews.Lists)
    self.ListsContainer:ExpandList(Auctionator.Shopping.ListManager:GetByIndex(listIndex))
  end
end
