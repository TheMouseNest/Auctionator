---@class addonTableAuctionator
local addonTable = select(2, ...)

-- All "realms" that are connected together use the same AH database, this
-- determines which database is in use.
-- Call this AFTER event PLAYER_LOGIN fires.
function addonTable.Storage.GetConnectedRealmRoot()
  -- We use GetRealmName() because GetNormalizedRealmName() isn't available on
  -- first load.
  local currentRealm = GetNormalizedRealmName()
  local connections = GetAutoCompleteRealms()

  -- We sort so that we always get the same first realm to use for the database
  table.sort(connections)

  if connections[1] ~= nil then
    -- Case where we are on a connected realm
    return connections[1]
  else
    -- We are not on a connected realm
    return currentRealm
  end
end

function addonTable.Storage.Initialize()
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    addonTable.Storage.InitializeInternal()
  end)
end

local VERSION_8_3 = 6
local VERSION_SERIALIZED = 7
local VERSION_KEY_SERIALIZED = 8
local POSTING_HISTORY_DB_VERSION = 1
local VENDOR_PRICE_CACHE_DB_VERSION = 1

function addonTable.Storage.InitializeInternal()
  addonTable.Storage.InitializeDatabase()
  addonTable.Storage.InitializeShoppingLists()
  addonTable.Storage.InitializePostingHistory()
  addonTable.Storage.InitializeVendorPriceCache()
end

-- Attempt to import from other connected realms (this may happen if another
-- realm was connected or the databases are not currently shared)
--
-- Assumes rootRealm has no active database
local function ImportFromConnectedRealm(rootRealm)
  local connections = GetAutoCompleteRealms()

  if #connections == 0 then
    return false
  end

  for _, altRealm in ipairs(connections) do
    if AUCTIONATOR_PRICE_DATABASE[altRealm] ~= nil then
      AUCTIONATOR_PRICE_DATABASE[rootRealm] = AUCTIONATOR_PRICE_DATABASE[altRealm]
      -- Remove old database (no longer needed)
      AUCTIONATOR_PRICE_DATABASE[altRealm] = nil
      return true
    end
  end

  return false
end

local function ImportFromNotNormalizedName(target)
  local unwantedName = GetRealmName()

  if AUCTIONATOR_PRICE_DATABASE[unwantedName] ~= nil then
    AUCTIONATOR_PRICE_DATABASE[target] = AUCTIONATOR_PRICE_DATABASE[unwantedName]
    -- Remove old database (no longer needed)
    AUCTIONATOR_PRICE_DATABASE[unwantedName] = nil
    return true
  end

  return false
end

-- Deserialize current realm when not already deserialized in the saved
-- variables and serialize any other realms.
-- We keep the current realm deserialized in the saved variables to speed up
-- /reloads and logging in/out when only using one realm.
function addonTable.Storage.InitializeDatabase()
  -- First time users need the price database initialized
  if AUCTIONATOR_PRICE_DATABASE == nil then
    AUCTIONATOR_PRICE_DATABASE = {
      ["__dbversion"] = VERSION_8_3
    }
  end

  if AUCTIONATOR_PRICE_DATABASE["__dbversion"] == VERSION_8_3 then
    AUCTIONATOR_PRICE_DATABASE["__dbversion"] = VERSION_SERIALIZED
  end
  if AUCTIONATOR_PRICE_DATABASE["__dbversion"] == VERSION_SERIALIZED then
    AUCTIONATOR_PRICE_DATABASE["__dbversion"] = VERSION_KEY_SERIALIZED
  end

  -- If we changed how we record item info we need to reset the DB
  if AUCTIONATOR_PRICE_DATABASE["__dbversion"] ~= VERSION_KEY_SERIALIZED then
    AUCTIONATOR_PRICE_DATABASE = {
      ["__dbversion"] = VERSION_KEY_SERIALIZED
    }
  end

  local realm = addonTable.Storage.GetConnectedRealmRoot()

  if C_EncodingUtil then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function()
      local raw = AUCTIONATOR_PRICE_DATABASE[realm]
      AUCTIONATOR_PRICE_DATABASE[realm] = C_EncodingUtil.SerializeCBOR(raw)
    end)
  end

  -- Check for current realm and initialize if not present
  if AUCTIONATOR_PRICE_DATABASE[realm] == nil then
    if not ImportFromNotNormalizedName(realm) and not ImportFromConnectedRealm(realm) then
      AUCTIONATOR_PRICE_DATABASE[realm] = {}
    end
  end

  C_Timer.After(0, function()
    -- Serialize and other unserialized realms so their data doesn't contribute to
    -- a constant overflow when the client parses the saved variables.
    for key, data in pairs(AUCTIONATOR_PRICE_DATABASE) do
      -- Convert one realm at a time, no need to hold up a login indefinitely
      if key ~= "__dbversion" and key ~= realm and type(data) == "table" then
        AUCTIONATOR_PRICE_DATABASE[key] = C_EncodingUtil.SerializeCBOR(data)
        break
      end
    end
  end)

  -- Only deserialize the current realm and save the deserialization in the
  -- saved variables to speed up reloads or changing character on the same
  -- realm.
  --
  -- Deserialize the current realm if it was left serialized by a previous
  -- version of Auctionator
  local raw = AUCTIONATOR_PRICE_DATABASE[realm]
  if type(raw) == "string" then
    local success, data = pcall(C_EncodingUtil.DeserializeCBOR, raw)
    if not success then
      AUCTIONATOR_PRICE_DATABASE[realm] = {}
    else
      AUCTIONATOR_PRICE_DATABASE[realm] = data
    end
  end

  -- Fix conversion error from old code
  if type(AUCTIONATOR_PRICE_DATABASE[realm]) ~= "table" then
    AUCTIONATOR_PRICE_DATABASE[realm] = {}
  end

  assert(AUCTIONATOR_PRICE_DATABASE[realm], "Realm data missing somehow")

  for realm, realmData in pairs(AUCTIONATOR_PRICE_DATABASE) do
    if type(realmData) == "table" and realmData.version ~= 2 then
      for key, itemData in pairs(realmData) do
        if type(itemData) == "table" and itemData.pending then
          for _, field in ipairs({"a", "h", "l"}) do
            local new = {}
            -- Make it valid JSON (legacy)
            for day, data in pairs(itemData[field] or {}) do
              new[tostring(day)] = data
            end
            itemData[field] = new
          end
        elseif type(itemData) == "table" and itemData.pending then
          itemData = itemData.old
        end
        -- Reverse per-item CBOR format
        if type(itemData) == "string" then
          realmData[key] = C_EncodingUtil.DeserializeCBOR(itemData)
        end
      end
      realmData.version = 2
    end
  end

  addonTable.PriceDatabase = CreateAndInitFromMixin(addonTable.Storage.PriceDatabaseMixin, AUCTIONATOR_PRICE_DATABASE[realm])
end

function addonTable.Storage.InitializePostingHistory()
  if AUCTIONATOR_POSTING_HISTORY == nil  or
     AUCTIONATOR_POSTING_HISTORY["__dbversion"] ~= POSTING_HISTORY_DB_VERSION then
    AUCTIONATOR_POSTING_HISTORY = {
      ["__dbversion"] = POSTING_HISTORY_DB_VERSION
    }
  end

  addonTable.PostingHistory = CreateAndInitFromMixin(addonTable.Storage.PostingHistoryMixin, AUCTIONATOR_POSTING_HISTORY)
end

function addonTable.Storage.InitializeShoppingLists()
  addonTable.ShoppingListManager = CreateAndInitFromMixin(
    addonTable.Storage.ShoppingListManagerMixin,
    function() return AUCTIONATOR_SHOPPING_LISTS end,
    function(newVal) AUCTIONATOR_SHOPPING_LISTS = newVal end
  )

  AUCTIONATOR_RECENT_SEARCHES = AUCTIONATOR_RECENT_SEARCHES or {}
end

function addonTable.Storage.InitializeVendorPriceCache()
  if AUCTIONATOR_VENDOR_PRICE_CACHE == nil  or
     AUCTIONATOR_VENDOR_PRICE_CACHE["__dbversion"] ~= VENDOR_PRICE_CACHE_DB_VERSION then
    AUCTIONATOR_VENDOR_PRICE_CACHE = {
      ["__dbversion"] = VENDOR_PRICE_CACHE_DB_VERSION
    }
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("MERCHANT_SHOW")
  frame:SetScript("OnEvent", function()
    for i = 1, GetMerchantNumItems() do
      local itemID = GetMerchantItemID(i)
      if itemID ~= nil then
        local item = Item:CreateFromItemID(itemID)
        if not item:IsItemEmpty() then
          item:ContinueOnItemLoad(function()
            local price, stack, numAvailable = select(3, GetMerchantItemInfo(i))
            local itemLink = GetMerchantItemLink(i)
            local dbKey = addonTable.Storage.BasicDBKeyFromLink(itemLink)
            if dbKey ~= nil and price ~= 0 and numAvailable == -1 then
              local oldPrice = AUCTIONATOR_VENDOR_PRICE_CACHE[dbKey]
              local newPrice = price / stack
              AUCTIONATOR_VENDOR_PRICE_CACHE[dbKey] = newPrice
            elseif dbKey ~= nil then
              AUCTIONATOR_VENDOR_PRICE_CACHE[dbKey] = nil
            end
          end)
        end
      end
    end
  end)
end
