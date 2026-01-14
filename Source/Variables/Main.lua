local VERSION_8_3 = 6
local VERSION_SERIALIZED = 7
local VERSION_KEY_SERIALIZED = 8
local POSTING_HISTORY_DB_VERSION = 1
local VENDOR_PRICE_CACHE_DB_VERSION = 1

function Auctionator.Variables.Initialize()
  Auctionator.Variables.InitializeSavedState()

  Auctionator.Config.InitializeData()
  Auctionator.Config.InitializeFrames()

  local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  Auctionator.State.CurrentVersion = GetAddOnMetadata("Auctionator", "Version")

  Auctionator.Variables.InitializeShoppingLists()
  Auctionator.Variables.InitializePostingHistory()
  Auctionator.Variables.InitializeVendorPriceCache()

  Auctionator.Groups.Initialize()
end

function Auctionator.Variables.InitializeLate()
  Auctionator.Variables.InitializeDatabase()

  Auctionator.State.Loaded = true
end

function Auctionator.Variables.Commit()
  Auctionator.Variables.CommitDatabase()
end

function Auctionator.Variables.InitializeSavedState()
  if AUCTIONATOR_SAVEDVARS == nil then
    AUCTIONATOR_SAVEDVARS = {}
  end
  Auctionator.SavedState = AUCTIONATOR_SAVEDVARS
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
function Auctionator.Variables.InitializeDatabase()
  Auctionator.Debug.Message("Auctionator.Database.Initialize()")
  -- Auctionator.Utilities.TablePrint(AUCTIONATOR_PRICE_DATABASE, "AUCTIONATOR_PRICE_DATABASE")

  -- First time users need the price database initialized
  if AUCTIONATOR_PRICE_DATABASE == nil then
    AUCTIONATOR_PRICE_DATABASE = {
      ["__dbversion"] = VERSION_8_3
    }
  end

  local LibCBOR = LibStub("LibCBOR-1.0")

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

  local realm = Auctionator.Variables.GetConnectedRealmRoot()
  Auctionator.State.CurrentRealm = realm

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
        if C_EncodingUtil then
          AUCTIONATOR_PRICE_DATABASE[key] = C_EncodingUtil.SerializeCBOR(data)
        else
          AUCTIONATOR_PRICE_DATABASE[key] = LibCBOR:Serialize(data)
        end
        break
      end
    end
  end)

  -- Only deserialize the current realm and save the deserialization in the
  -- saved variables to speed up reloads or changing character on the same
  -- realm.
  --]]
  -- Deserialize the current realm if it was left serialized by a previous
  -- version of Auctionator
  local raw = AUCTIONATOR_PRICE_DATABASE[realm]
  if type(raw) == "string" then
    local success, data
    if C_EncodingUtil then
      success, data = pcall(C_EncodingUtil.DeserializeCBOR, raw)
    else
      success, data = pcall(LibCBOR.Deserialize, LibCBOR, raw)
    end
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
          if C_EncodingUtil then
            realmData[key] = C_EncodingUtil.DeserializeCBOR(itemData)
          else
            realmData[key] = LibCBOR:Deserialize(itemData)
          end
        end
      end
      realmData.version = 2
    end
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.NO_PRICE_DATABASE) then
    Auctionator.Database = CreateAndInitFromMixin(Auctionator.DatabaseMixin, {})
  else
    Auctionator.Database = CreateAndInitFromMixin(Auctionator.DatabaseMixin, AUCTIONATOR_PRICE_DATABASE[realm])
  end
end

function Auctionator.Variables.InitializePostingHistory()
  Auctionator.Debug.Message("Auctionator.Variables.InitializePostingHistory()")

  if AUCTIONATOR_POSTING_HISTORY == nil  or
     AUCTIONATOR_POSTING_HISTORY["__dbversion"] ~= POSTING_HISTORY_DB_VERSION then
    AUCTIONATOR_POSTING_HISTORY = {
      ["__dbversion"] = POSTING_HISTORY_DB_VERSION
    }
  end

  Auctionator.PostingHistory = CreateAndInitFromMixin(Auctionator.PostingHistoryMixin, AUCTIONATOR_POSTING_HISTORY)
end

function Auctionator.Variables.InitializeShoppingLists()
  Auctionator.Shopping.ListManager = CreateAndInitFromMixin(
    AuctionatorShoppingListManagerMixin,
    function() return AUCTIONATOR_SHOPPING_LISTS end,
    function(newVal) AUCTIONATOR_SHOPPING_LISTS = newVal end
  )

  AUCTIONATOR_RECENT_SEARCHES = AUCTIONATOR_RECENT_SEARCHES or {}
end

function Auctionator.Variables.InitializeVendorPriceCache()
  Auctionator.Debug.Message("Auctionator.Variables.InitializeVendorPriceCache()")

  if AUCTIONATOR_VENDOR_PRICE_CACHE == nil  or
     AUCTIONATOR_VENDOR_PRICE_CACHE["__dbversion"] ~= VENDOR_PRICE_CACHE_DB_VERSION then
    AUCTIONATOR_VENDOR_PRICE_CACHE = {
      ["__dbversion"] = VENDOR_PRICE_CACHE_DB_VERSION
    }
  end
end
