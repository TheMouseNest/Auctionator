local function SearchItem(text)
  if text == nil or AuctionatorShoppingFrame == nil or not AuctionatorShoppingFrame:IsVisible() then
    return false
  end

  C_Timer.After(0, function()
    StackSplitFrame:Hide()
  end)

  -- Borrowed from Blizzard InsertLink to avoid inserting textures with
  -- DF reagent links
  local name;
  if ( strfind(text, "battlepet:") ) then
    local petName = strmatch(text, "%[(.+)%]");
    name = petName;
  elseif ( strfind(text, "item:", 1, true) ) then
    name = C_Item.GetItemInfo(text);
  elseif ( strfind(text, "enchant:", 1, true) ) then
    name = Auctionator.Utilities.GetNameFromLink(text)
  end

  if name == nil then
    name = text
  end

  local searchTerm
  -- Non-exact with enchants as the name doesn't match exactly
  if text:match("enchant:") then
    searchTerm = name
  else
    searchTerm = "\"" .. name .. "\""
  end
  AuctionatorShoppingFrame:DoSearch({searchTerm}, {})
  AuctionatorShoppingFrame.SearchOptions:SetSearchTerm(searchTerm)
  Auctionator.Shopping.Recents.Save(searchTerm)

  return true
end

local function Callback(text)
  -- Prevent searching when the user is attempting to link the item in chat
  if GetCurrentKeyBoardFocus() == nil or GetCurrentKeyBoardFocus():GetName() == nil then
    SearchItem(text)
  end
end

-- We would replace InsertLink so that the return value is used, but
-- that causes a taint error when attempting to buy vendor items with the stack
-- selection dialog (to replicate, when InsertLink is manually
-- replaced, hold down "c" while pressing [Enter] with the stack dialog open)
if ChatFrameUtil and ChatFrameUtil.InsertLink then
  hooksecurefunc(ChatFrameUtil, "InsertLink", Callback)
else
  hooksecurefunc(_G, "ChatEdit_InsertLink", Callback)
end
