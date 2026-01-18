Auctionator.Groups.Constants = {
  IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC,
  IsMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC,
  IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC,
  IsBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC,
  IsVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
}

Auctionator.Groups.Constants.Events = {
  "BagCacheUpdated",
  "ViewGroupToggled",
  "ViewComplete",

  "BagCacheOff",
  "BagCacheOn",

  "BagUse.BagItemClicked",
  "BagUse.AddToDefaultGroup",

  "Customise.EditMade",
}

if Auctionator.Groups.Constants.IsVanilla or Auctionator.Groups.Constants.IsBC then
  -- Note that -2 is the keyring bag, which only exists in classic era
  Auctionator.Groups.Constants.BagIDs = {-2, 0, 1, 2, 3, 4}
elseif not Auctionator.Groups.Constants.IsRetail then
  Auctionator.Groups.Constants.BagIDs = {0, 1, 2, 3, 4}
elseif Auctionator.Groups.Constants.IsRetail then
  Auctionator.Groups.Constants.BagIDs = {0, 1, 2, 3, 4, 5}
end

if Auctionator.Groups.Constants.IsRetail then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
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
    Enum.ItemClass.Housing,
    Enum.ItemClass.Miscellaneous,
  }
elseif Auctionator.Groups.Constants.IsMists then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.ItemEnhancement,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Battlepet,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsCata then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.ItemEnhancement,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsWrath then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsBC then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
  }
elseif Auctionator.Groups.Constants.IsVanilla then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
end

Auctionator.Groups.Constants.GroupType = {
  List = 1,
  ClassID = 2,
}

Auctionator.Groups.Constants.DefaultGroups = {
}

for _, classID in ipairs(Auctionator.Groups.Constants.ValidItemClassIDs) do
  table.insert(Auctionator.Groups.Constants.DefaultGroups, {
    name = C_Item.GetItemClassInfo(classID),
    type = Auctionator.Groups.Constants.GroupType.ClassID,
    classID = classID,
  })
end
