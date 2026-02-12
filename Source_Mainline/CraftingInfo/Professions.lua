-- Add a info to the tradeskill frame for reagent prices
local addedFunctionality = false
function Auctionator.CraftingInfo.InitializeProfessionsFrame()
  if addedFunctionality then
    return
  end

  if ProfessionsFrame then
    addedFunctionality = true

    local craftingPageContainer = CreateFrame("Frame", "AuctionatorCraftingInfoProfessionsFrame", ProfessionsFrame.CraftingPage.SchematicForm, "AuctionatorCraftingInfoProfessionsFrameTemplate");
    local ordersPageContainer = CreateFrame("Frame", "AuctionatorCraftingInfoProfessionsOrderFrame", ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm, "AuctionatorCraftingInfoProfessionsFrameTemplate");
    ordersPageContainer:SetDoNotShowProfit()
  end
end

function Auctionator.CraftingInfo.DoTradeSkillReagentsSearch(schematicForm, quantity)
  local recipeInfo = schematicForm:GetRecipeInfo()
  local recipeID = recipeInfo.recipeID
  local recipeLevel = schematicForm:GetCurrentRecipeLevel()

  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)

  local transaction = schematicForm:GetTransaction()

  local searchTerms = {}

  local possibleItems = {}
  local quantities = {}

  local continuableContainer = ContinuableContainer:Create()

  local outputLink = C_TradeSkillUI.GetRecipeOutputItemData(recipeID, transaction:CreateOptionalCraftingReagentInfoTbl(), transaction:GetAllocationItemGUID()).hyperlink

  table.insert(quantities, 0)
  if outputLink then
    table.insert(possibleItems, outputLink)
    continuableContainer:AddContinuable(Item:CreateFromItemLink(outputLink))
  -- Special case, enchants don't include an output in the API, so we use a
  -- precomputed table to get the output
  elseif Auctionator.CraftingInfo.EnchantSpellsToItems[recipeID] then
    local itemID = Auctionator.CraftingInfo.EnchantSpellsToItems[recipeID][1]
    table.insert(possibleItems, itemID)
    continuableContainer:AddContinuable(Item:CreateFromItemID(itemID))
  -- Probably doesn't have a specific item output, but include the recipe name
  -- anyway just in case
  else
    table.insert(searchTerms, {searchString = recipeInfo.name})
  end

  -- Select all mandatory reagents
  for slotIndex, reagentSlotSchematic in ipairs(recipeSchematic.reagentSlotSchematics) do
    if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic and #reagentSlotSchematic.reagents > 0 then
      local itemID = reagentSlotSchematic.reagents[1].itemID
      if itemID ~= nil then
        continuableContainer:AddContinuable(Item:CreateFromItemID(itemID))

        table.insert(possibleItems, itemID)
        table.insert(quantities, reagentSlotSchematic.quantityRequired)
      end
    end
  end

  -- Go through the items one by one and get their names
  local function OnItemInfoReady()
    for index, itemInfo in ipairs(possibleItems) do
      local itemInfo = {C_Item.GetItemInfo(itemInfo)}
      if not Auctionator.Utilities.IsBound(itemInfo) then
        table.insert(searchTerms, {searchString = itemInfo[1], isExact = true, quantity = quantities[index] * quantity})
      end
    end

    Auctionator.API.v1.MultiSearchAdvanced(AUCTIONATOR_L_REAGENT_SEARCH, searchTerms)
  end

  continuableContainer:ContinueOnLoad(OnItemInfoReady)
end

local function GetSkillReagentsTotal(schematicForm)
  local recipeInfo = schematicForm:GetRecipeInfo()
  local recipeID = recipeInfo.recipeID
  local recipeLevel = schematicForm:GetCurrentRecipeLevel()
  local transaction = schematicForm:GetTransaction()
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)

  return Auctionator.CraftingInfo.CalculateCraftCost(recipeSchematic, transaction)
end

local function GetCheapestQualityTotal(schematicForm)
  local recipeInfo = schematicForm:GetRecipeInfo()
  local recipeID = recipeInfo.recipeID
  local recipeLevel = schematicForm:GetCurrentRecipeLevel()
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)
  local transaction = CreateProfessionsRecipeTransaction(recipeSchematic)

  return Auctionator.CraftingInfo.CalculateCraftCost(recipeSchematic, transaction)
end

local function CalculateProfitFromCosts(currentAH, toCraft, count)
  return math.floor(math.floor(currentAH * count * Auctionator.Constants.AfterAHCut - toCraft) / 100) * 100
end

-- Search through a list of items for the first matching the wantedQuality
local function GetItemIDByReagentQuality(possibleItemIDs, wantedQuality)
  if #possibleItemIDs == 1 then
    return possibleItemIDs[1]
  end

  for _, itemID in ipairs(possibleItemIDs) do
    local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID)
    if quality == wantedQuality then
      return itemID
    end
  end
end

local function GetEnchantProfit(schematicForm)
  local recipeID = schematicForm.recipeSchematic.recipeID
  local reagents = schematicForm:GetTransaction():CreateCraftingReagentInfoTbl()
  local allocationGUID = schematicForm:GetTransaction():GetAllocationItemGUID()
  local applyConcentration = schematicForm:GetTransaction():IsApplyingConcentration()

  local recipeLevel = schematicForm:GetCurrentRecipeLevel()
  local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID, recipeLevel)

  local possibleOutputItemIDs = Auctionator.CraftingInfo.EnchantSpellsToItems[recipeID] or {}
  local itemID

  -- For Dragonflight recipes determine the quality and then select the quality
  -- from the list of possible results.
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)
  if recipeSchematic ~= nil and recipeSchematic.hasCraftingOperationInfo then
    local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, reagents, allocationGUID, applyConcentration)
    if operationInfo ~= nil then
      itemID = GetItemIDByReagentQuality(possibleOutputItemIDs, operationInfo.guaranteedCraftingQualityID)
    end
  end
  -- Not a dragonflight recipe, or has no quality data, so only one possible
  -- output
  if itemID == nil then
    itemID = possibleOutputItemIDs[1]
  end

  if itemID ~= nil then
    local currentAH = Auctionator.API.v1.GetAuctionPriceByItemID(AUCTIONATOR_L_REAGENT_SEARCH, itemID) or 0
    local age = Auctionator.API.v1.GetAuctionAgeByItemID(AUCTIONATOR_L_REAGENT_SEARCH, itemID)
    local exact = Auctionator.API.v1.IsAuctionDataExactByItemID(AUCTIONATOR_L_REAGENT_SEARCH, itemID)

    local vellumCost = Auctionator.API.v1.GetVendorPriceByItemID(AUCTIONATOR_L_REAGENT_SEARCH, Auctionator.Constants.EnchantingVellumID) or 0
    local toCraft = GetSkillReagentsTotal(schematicForm) + vellumCost

    local count = schematicForm.recipeSchematic.quantityMin

    return CalculateProfitFromCosts(currentAH, toCraft, count), age, currentAH ~= 0, exact
  else
    return nil
  end
end

local function GetAHProfit(schematicForm)
  local recipeInfo = schematicForm:GetRecipeInfo()

  if recipeInfo.isEnchantingRecipe then
    return GetEnchantProfit(schematicForm)

  else
    local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(
      recipeInfo.recipeID,
      schematicForm:GetTransaction():CreateCraftingReagentInfoTbl(),
      schematicForm:GetTransaction():GetAllocationItemGUID(),
      schematicForm:GetTransaction():IsApplyingConcentration()
    )
    local qualityOverride = operationInfo and recipeInfo.qualityIDs and recipeInfo.qualityIDs[operationInfo.craftingQuality]
    local outputData = C_TradeSkillUI.GetRecipeOutputItemData(
      recipeInfo.recipeID,
      schematicForm:GetTransaction():CreateCraftingReagentInfoTbl(),
      schematicForm:GetTransaction():GetAllocationItemGUID(),
      qualityOverride
    )
    local recipeLink = outputData and outputData.hyperlink

    if recipeLink ~= nil then
      local currentAH = Auctionator.API.v1.GetAuctionPriceByItemLink(AUCTIONATOR_L_REAGENT_SEARCH, recipeLink) or 0
      local age = Auctionator.API.v1.GetAuctionAgeByItemLink(AUCTIONATOR_L_REAGENT_SEARCH, recipeLink)
      local exact = Auctionator.API.v1.IsAuctionDataExactByItemLink(AUCTIONATOR_L_REAGENT_SEARCH, recipeLink)

      local toCraft = GetSkillReagentsTotal(schematicForm)

      local count = schematicForm.recipeSchematic.quantityMin

      return CalculateProfitFromCosts(currentAH, toCraft, count), age, currentAH ~= 0, exact
    else
      return nil
    end
  end
end

local function CraftCostString(schematicForm)
  local price = WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(GetSkillReagentsTotal(schematicForm), true))

  return AUCTIONATOR_L_TO_CRAFT_COLON .. " " .. price
end

local function CheapestQualityCostString(schematicForm)
  local price = WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(GetCheapestQualityTotal(schematicForm), true))

  return AUCTIONATOR_L_CHEAPEST_QUALITY_COST_COLON .. " " .. price
end

local function ProfitString(profit)
  local toCraft = GetSkillReagentsTotal()
  
  local percentageValue = 0
  if toCraft > 0 then
    percentageValue = math.floor((profit / toCraft) * 100 * 100 + 0.5) / 100
  end
  
  local priceText
  if profit >= 0 then
    priceText = WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(profit, true))
  else
    priceText = RED_FONT_COLOR:WrapTextInColorCode("-" .. GetMoneyString(-profit, true))
  end
  
  local percentageText
  if percentageValue >= 0 then
    percentageText = WHITE_FONT_COLOR:WrapTextInColorCode(percentageValue .. "%")
  else
    percentageText = RED_FONT_COLOR:WrapTextInColorCode(percentageValue .. "%")
  end
  
  return AUCTIONATOR_L_PROFIT_COLON .. " " .. priceText .. " (" .. percentageText .. ")"
end

function Auctionator.CraftingInfo.GetInfoText(schematicForm, showProfit)
  local result = ""
  local lines = 0
  if Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_COST) then
    if lines > 0 then
      result = result .. "\n"
    end
    result = result .. CraftCostString(schematicForm)
    lines = lines + 1
  end

  if showProfit and Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_PROFIT) then
    local profit, age, anyPrice, exact = GetAHProfit(schematicForm)

    if profit ~= nil then
      if lines > 0 then
        result = result .. "\n"
      end
      result = result .. ProfitString(profit) .. Auctionator.CraftingInfo.GetProfitWarning(profit, age, anyPrice, exact)
      lines = lines + 1
    end
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_CHEAPEST_QUALITIES_COST) then
    if lines > 0 then
      result = result .. "\n"
    end
    result = result .. CheapestQualityCostString(schematicForm)
    lines = lines + 1
  end

  return result, lines
end
