---@class addonTableAuctionator
local addonTable = select(2, ...)
addonTable.Config = {}

addonTable.Config = addonTable.Config

local settings = {
  TOOLTIPS_MAILBOX = {key = "mailbox_tooltips", default = true},
  TOOLTIPS_VENDOR = {key = "vendor_tooltips", default = true},
  TOOLTIPS_AUCTION = {key = "auction_tooltips", default = true},
  TOOLTIPS_AUCTION_AGE = {key = "auction_age_tooltips", default = false},
  TOOLTIPS_SHIFT_STACK = {key = "shift_stack_tooltips", default = true},

  TOOLTIPS_ENCHANT = {key = "enchant_tooltips", default = false},
  TOOLTIPS_PROSPECT = {key = "prospect_tooltips", default = false}, -- Classic
  TOOLTIPS_MILL = {key = "mill_tooltips", default = false}, -- Classic

  TOOLTIPS_AUCTION_MEAN = {key = "auction_mean_tooltip", default = false},
  AUCTION_MEAN_DAYS_LIMIT = {key = "auction_mean_days_limit", default = 21},
  TOOLTIPS_PET = {key = "pet_tooltips", default = true},

  DEFAULT_TAB = {key = "default_tab", default = 0},

  SHOPPING_AUTO_LIST_SEARCH = {key = "auto_list_search", default = addonTable.Constants.IsRetail},
  SHOPPING_DEFAULT_LIST = {key = "default_list_2", default = addonTable.Constants.NoList},
  SHOPPING_LAST_CONTAINER_VIEW = {key = "shopping_last_container_view", default = addonTable.Constants.ShoppingListViews.Lists},

  SELLING_SHOW_BID_PRICE = {key = "show_selling_bid_price", default = false},
  SELLING_AUTO_SELECT_NEXT = {key = "selling_auto_select_next", default = false},

  SELLING_BAG_SELECT_SHORTCUT = {key = "selling_bag_select_shortcut", default = addonTable.Constants.Shortcuts.AltLeftClick},
  SELLING_SHOW_BAG = {key = "show_selling_bag_2", default = true},

  SELLING_POST_SHORTCUT = {key = "selling_post_shortcut", default = "SPACE"},
  SELLING_SKIP_SHORTCUT = {key = "selling_skip_shortcut", default = "SHIFT-SPACE"},
  SELLING_PREV_SHORTCUT = {key = "selling_prev_shortcut", default = "BACKSPACE"},
  SELLING_AUCTION_DURATION = {key = "selling_auction_duration", default = addonTable.Constants.Durations.Medium},
  SELLING_AUCTION_UNDERCUT = {key = "selling_auction_undercut", default = {mode = addonTable.Constants.UndercutType.Static, value = Auctionator.Constants.IsLegacyAH and 1 or 0}},
  SELLING_ITEM_MATCHING = {key = "selling_item_matching", default = addonTable.Constants.ItemMatching.Full},
  SELLING_REMEMBER_ITEM = {key = "selling_remember_item", default = false},
  SELLING_ITEM_TO_RESTORE = {key = "selling_item_to_restore", default = ""},

  SELLING_STACK_SIZE_MEMORY = {key = "stack_size_memory", default = {}}, -- Classic

  CANCELLING_UNDERCUT_SHORTCUT = {key = "cancel_undercut_shortcut", default = "SPACE"},

  SKINS = {key = "skins", default = {}},
  DISABLED_SKINS = {key = "disabled_skins", default = {}},
  CURRENT_SKIN = {key = "current_skin", default = "blizzard"},

  COLUMNS = {key = "columns", default = {}},

  PRICE_HISTORY_DAYS = {key = "price_history_days", default = 21},
  POSTING_HISTORY_LENGTH = {key = "auctions_history_length", default = 10},

  SCAN_STATE = {key = "scan_state", default = {TimeOfLastRestricted = 0, TimeOfLastFree = 0}},

  DEBUG = {key = "debug", default = false},
}

addonTable.Config.RefreshType = {}

addonTable.Config.Options = {}
addonTable.Config.Defaults = {}

for key, details in pairs(settings) do
  if details.refresh then
    local refreshType = {}
    for _, r in ipairs(details.refresh) do
      refreshType[r] = true
    end
    addonTable.Config.RefreshType[details.key] = refreshType
  end
  addonTable.Config.Options[key] = details.key
  addonTable.Config.Defaults[details.key] = details.default
end

function addonTable.Config.IsValidOption(name)
  for _, option in pairs(addonTable.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

local function RawSet(name, value)
  local tree = {strsplit(".", name)}
  if addonTable.Config.CurrentProfile == nil then
    error("AUCTIONATOR_CONFIG not initialized")
  elseif not addonTable.Config.IsValidOption(tree[1]) then
    error("Invalid option '" .. name .. "'")
  elseif #tree == 1 then
    local oldValue = addonTable.Config.CurrentProfile[name]
    addonTable.Config.CurrentProfile[name] = value
    if value ~= oldValue then
      return true
    end
  else
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree - 1 do
      root = root[tree[i]]
      if type(root) ~= "table" then
        error("Invalid option '" .. name .. "', broke at [" .. i .. "]")
      end
    end
    local tail = tree[#tree]
    if root[tail] == nil then
      error("Invalid option '" .. name .. "', broke at [tail]")
    end
    local oldValue = root[tail]
    root[tail] = value
    if value ~= oldValue then
      return true
    end
  end
  return false
end

function addonTable.Config.Set(name, value)
  if RawSet(name, value) then
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    if addonTable.Config.RefreshType[name] then
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", addonTable.Config.RefreshType[name])
    end
  end
end

-- Set multiple settings at once and after all are set fire the setting changed
-- events
function addonTable.Config.MultiSet(nameValueMap)
  local changed = {}
  for name, value in pairs(nameValueMap) do
    if RawSet(name, value) then
      table.insert(changed, name)
    end
  end

  local refreshState = {}
  for _, name in ipairs(changed) do
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    if addonTable.Config.RefreshType[name] then
      refreshState = Mixin(refreshState, addonTable.Config.RefreshType[name])
    end
  end
  if next(refreshState) ~= nil then
    addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
  end
end

local addedInstalledNestedToList = {}
local installedNested = {}

function addonTable.Config.Install(name, defaultValue)
  if AUCTIONATOR_CONFIG == nil then
    error("AUCTIONATOR_CONFIG not initialized")
  elseif name:find("%.") == nil then
    if addonTable.Config.CurrentProfile[name] == nil then
      addonTable.Config.CurrentProfile[name] = defaultValue
    end
  else
    if not addedInstalledNestedToList[name] then
      addedInstalledNestedToList[name] = true
      table.insert(installedNested, name)
    end
    local tree = {strsplit(".", name)}
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree - 1 do
      if not root[tree[i]] then
        root[tree[i]] = {}
      end
      root = root[tree[i]]
    end
    if root[tree[#tree]] == nil then
      root[tree[#tree]] = defaultValue
    end
  end
end

function addonTable.Config.ResetOne(name)
  local newValue = addonTable.Config.Defaults[name]
  if newValue == nil then
    error("Can't reset that", name)
  else
    if type(newValue) == "table" then
      newValue = CopyTable(newValue)
    end
    addonTable.Config.Set(name, newValue)
  end
end

function addonTable.Config.Reset()
  AUCTIONATOR_CONFIG = {
    Profiles = {
      DEFAULT = {},
    },
    Version = 1,
  }
  addonTable.Config.InitializeData()
end

local function ImportDefaultsToProfile()
  for option, value in pairs(addonTable.Config.Defaults) do
    if addonTable.Config.CurrentProfile[option] == nil then
      if type(value) == "table" then
        addonTable.Config.CurrentProfile[option] = CopyTable(value)
      else
        addonTable.Config.CurrentProfile[option] = value
      end
    end
  end
end

function addonTable.Config.InitializeData()
  if AUCTIONATOR_CONFIG == nil then
    addonTable.Config.Reset()
    return
  end

  if AUCTIONATOR_CONFIG.Profiles == nil then
    AUCTIONATOR_CONFIG = {
      Profiles = {
        DEFAULT = AUCTIONATOR_CONFIG,
      },
      Version = 1,
    }
  end

  if AUCTIONATOR_CONFIG.Profiles.DEFAULT == nil then
    AUCTIONATOR_CONFIG.Profiles.DEFAULT = {}
  end
  if AUCTIONATOR_CONFIG.Profiles[AUCTIONATOR_CURRENT_PROFILE] == nil then
    AUCTIONATOR_CURRENT_PROFILE = "DEFAULT"
  end

  addonTable.Config.CurrentProfile = AUCTIONATOR_CONFIG.Profiles[AUCTIONATOR_CURRENT_PROFILE]
  ImportDefaultsToProfile()
end

function addonTable.Config.GetProfileNames()
  return GetKeysArray(AUCTIONATOR_CONFIG.Profiles)
end

function addonTable.Config.MakeProfile(newProfileName, clone)
  assert(tIndexOf(addonTable.Config.GetProfileNames(), newProfileName) == nil, "Existing Profile")
  if clone then
    AUCTIONATOR_CONFIG.Profiles[newProfileName] = CopyTable(addonTable.Config.CurrentProfile)
  else
    AUCTIONATOR_CONFIG.Profiles[newProfileName] = {}
  end
  addonTable.Config.ChangeProfile(newProfileName)
end

function addonTable.Config.DeleteProfile(profileName)
  assert(profileName ~= "DEFAULT" and profileName ~= AUCTIONATOR_CURRENT_PROFILE)

  AUCTIONATOR_CONFIG.Profiles[profileName] = nil
end

function addonTable.Config.ChangeProfile(newProfileName)
  assert(tIndexOf(addonTable.Config.GetProfileNames(), newProfileName) ~= nil, "Invalid Profile")

  local changedOptions = {}
  local refreshState = {}
  local newProfile = AUCTIONATOR_CONFIG.Profiles[newProfileName]

  for name, value in pairs(addonTable.Config.CurrentProfile) do
    if value ~= newProfile[name] then
      table.insert(changedOptions, name)
      Mixin(refreshState, addonTable.Config.RefreshType[name] or {})
    end
  end

  tAppendAll(changedOptions, installedNested)

  addonTable.Config.CurrentProfile = newProfile
  AUCTIONATOR_CURRENT_PROFILE = newProfileName

  ImportDefaultsToProfile()

  addonTable.Core.MigrateSettings()

  for _, name in ipairs(changedOptions) do
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
  end
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
end

-- characterName is optional, only use if need a character specific setting for
-- a character other than the current one.
function addonTable.Config.Get(name, characterName)
  -- This is ONLY if a config is asked for before variables are loaded
  if addonTable.Config.CurrentProfile == nil then
    return addonTable.Config.Defaults[name]
  elseif name:find("%.") == nil then
    return addonTable.Config.CurrentProfile[name]
  else
    local tree = {strsplit(".", name)}
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree do
      root = root[tree[i]]
      if root == nil then
        break
      end
    end
    return root
  end
end
