local ADDON, SW = ...
_G.AHPremium = SW

SW.callerID = "AHPremium"
SW.AH_CUT = 0.05

SW.defaults = {
  thresholdPct = 10, -- AH net must beat vendor by this many percent
  staleDays = 1,
  includeJunk = false, -- grey (poor quality) items are skipped unless this is on
  showTooltip = true,
  showPriceBreakdown = false, -- price lines under the tooltip verdict
  showBagIcon = true,
  showVendorIcon = true,
  ignoreVendorItems = true, -- skip items seen on a vendor with unlimited stock (food, water, arrows)
}

local function initDB()
  AHPremiumDB = AHPremiumDB or {}
  for k, v in pairs(SW.defaults) do
    if AHPremiumDB[k] == nil then
      AHPremiumDB[k] = v
    end
  end
  AHPremiumDB.vendorItems = AHPremiumDB.vendorItems or {} -- [itemID] = true, learned at vendors
  SW.db = AHPremiumDB

  AHPremiumCharDB = AHPremiumCharDB or {}
  AHPremiumCharDB.ignored = AHPremiumCharDB.ignored or {} -- [itemID] = true
  SW.charDB = AHPremiumCharDB
end

function SW.ItemID(link)
  local id = link and link:match("item:(%d+)")
  return id and tonumber(id)
end

-- Returns a table, or nil when there is nothing worth showing.
--   verdict: "ah", "vendor", "ahonly", "nodata"
--   ahPrice / vendorPrice: per item, copper. ahNet is ahPrice after the AH cut.
--   pct: ahNet / vendorPrice - 1 (nil when vendorPrice is 0)
--   stale: true when the AH price is older than staleDays
function SW.Evaluate(link, isBound)
  if not link then return nil end

  local itemID = SW.ItemID(link)
  if itemID and SW.charDB and SW.charDB.ignored[itemID] then return nil end
  if itemID and SW.db.ignoreVendorItems and SW.db.vendorItems[itemID] then return nil end

  local _, _, quality, _, _, _, _, _, _, _, sellPrice, _, _, bindType = C_Item.GetItemInfo(link)
  if sellPrice == nil then return nil end -- item info not cached yet

  if quality == 0 and not SW.db.includeJunk then return nil end

  -- Soulbound, bind on pickup and quest items can't go on the AH.
  if isBound or bindType == 1 or bindType == 4 then return nil end

  local ahPrice, age
  if Auctionator and Auctionator.API and Auctionator.API.v1 then
    local ok, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemLink, SW.callerID, link)
    if ok then ahPrice = price end
    if ahPrice then
      local okAge, a = pcall(Auctionator.API.v1.GetAuctionAgeByItemLink, SW.callerID, link)
      if okAge then age = a end
    end
  end

  local result = { vendorPrice = sellPrice, ahPrice = ahPrice }

  if not ahPrice then
    if sellPrice == 0 then return nil end
    result.verdict = "nodata"
    return result
  end

  -- Auctionator returns nil for age when the last sighting was over 21 days ago.
  result.stale = (age == nil) or (age > SW.db.staleDays)
  result.ahNet = ahPrice * (1 - SW.AH_CUT)

  if sellPrice == 0 then
    result.verdict = "ahonly"
    return result
  end

  result.pct = result.ahNet / sellPrice - 1
  if result.pct >= SW.db.thresholdPct / 100 then
    result.verdict = "ah"
  else
    result.verdict = "vendor"
  end
  return result
end

-- Remember items a vendor always has in stock, so they can be skipped. Limited-stock
-- and extended-cost (honour, tokens) entries are left out. Runs once per vendor window.
local function learnVendorItems()
  if not SW.db then return end
  local known, changed = SW.db.vendorItems, false
  for i = 1, GetMerchantNumItems() do
    local numAvailable, extendedCost
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
      local info = C_MerchantFrame.GetItemInfo(i)
      if info then numAvailable, extendedCost = info.numAvailable, info.hasExtendedCost end
    elseif GetMerchantItemInfo then
      local _
      _, _, _, _, numAvailable, _, extendedCost = GetMerchantItemInfo(i)
    end
    if numAvailable == -1 and not extendedCost then
      local id = SW.ItemID(GetMerchantItemLink(i))
      if id and not known[id] then
        known[id] = true
        changed = true
      end
    end
  end
  if changed and SW.RefreshBags then SW.RefreshBags() end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "MERCHANT_SHOW" then
    learnVendorItems()
  elseif name == ADDON then
    initDB()
    frame:UnregisterEvent("ADDON_LOADED")
  end
end)
