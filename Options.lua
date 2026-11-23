local _, SW = ...

local category

local function register()
  local db = SW.db
  local layout
  category, layout = Settings.RegisterVerticalLayoutCategory("AH Premium")

  local function onChange() if SW.RefreshBags then SW.RefreshBags() end end

  local function addCheckbox(key, label, tip)
    local setting = Settings.RegisterAddOnSetting(category, "AHPremium_" .. key, key, db,
      Settings.VarType.Boolean, label, SW.defaults[key])
    Settings.SetOnValueChangedCallback("AHPremium_" .. key, onChange)
    Settings.CreateCheckbox(category, setting, tip)
  end

  local function addSlider(key, label, tip, min, max, step, fmt)
    local setting = Settings.RegisterAddOnSetting(category, "AHPremium_" .. key, key, db,
      Settings.VarType.Number, label, SW.defaults[key])
    Settings.SetOnValueChangedCallback("AHPremium_" .. key, onChange)
    local options = Settings.CreateSliderOptions(min, max, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(v) return string.format(fmt, v) end)
    Settings.CreateSlider(category, setting, options, tip)
  end

  addSlider("thresholdPct", "AH premium over vendor",
    "How much more (after the 5% AH cut) the AH price must be than the vendor price before AH Premium says to sell on the AH.",
    0, 500, 5, "%d%%")
  addSlider("staleDays", "Stale after (days)",
    "AH prices last seen longer ago than this are marked stale and get no bag icon.",
    1, 21, 1, "%d")
  addCheckbox("showTooltip", "Show tooltip line", "Add the AH Premium verdict to item tooltips.")
  addCheckbox("showBagIcon", "Show bag icon", "Mark items worth selling on the AH in your bags.")
  addCheckbox("showVendorIcon", "Show vendor icon", "Mark items that are better vendored than sold on the AH with a grey coin.")
  addCheckbox("ignoreVendorItems", "Ignore vendor-bought items",
    "Skip items you have seen sold in unlimited supply by a vendor, such as food, water and arrows. AH Premium learns them as you open vendor windows.")
  addCheckbox("includeJunk", "Include junk (grey) items", "Off by default. Grey items are skipped unless this is on.")

  -- Kept separate so a missing button API doesn't break the rest of the panel.
  -- /ahp list opens the same window.
  pcall(function()
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Ignored items (this character)", "View list",
      function() SW.ShowIgnoreList() end,
      "See the items you have ignored and remove them.", true))
  end)

  Settings.RegisterAddOnCategory(category)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  local ok, err = pcall(register)
  if not ok then
    print("|cffff8800AH Premium:|r could not build the options panel: " .. tostring(err))
  end
end)

SLASH_AHPREMIUM1 = "/ahp"
SlashCmdList.AHPREMIUM = function(msg)
  local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = cmd:lower()

  if cmd == "list" then
    SW.ShowIgnoreList()
    return
  end

  if cmd == "ignore" or cmd == "unignore" then
    local id = SW.ItemID(rest)
    if not id then
      print("AH Premium: usage /ahp " .. cmd .. " [item link] (shift-click an item to insert its link)")
      return
    end
    local name = rest:match("%[.-%]") or ("item " .. id)
    if cmd == "ignore" then
      SW.charDB.ignored[id] = true
      print("AH Premium: now ignoring " .. name .. " on this character.")
    else
      SW.charDB.ignored[id] = nil
      print("AH Premium: no longer ignoring " .. name .. ".")
    end
    SW.RefreshBags()
    return
  end

  if category then
    Settings.OpenToCategory(category:GetID())
  else
    print("AH Premium: options panel unavailable.")
  end
end
