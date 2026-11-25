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
  useSaleHistory = true, -- weigh Journalator's sale history when it's installed
  minSaleRatePct = 50, -- below this chance of selling, an AH item becomes hold or vendor
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

-- A bar replaces the verdict when it beats the ore on the AH (and any bar already
-- chosen) and clears the vendor threshold. Bar prices are already fresh, so the
-- verdict isn't stale. A capped alloy goes last and keeps the verdict it replaced
-- as `rest`, for the ore it has no partner for. Kept outside SW.Evaluate so bag
-- refreshes don't create a closure per slot.
local function smeltOver(result, bar, sellPrice)
  if not bar or bar.net <= math.max(result.ahNet or 0, result.smeltBar and result.smeltBar.net or 0) then return end
  local pct = sellPrice > 0 and bar.net / sellPrice - 1 or nil
  if pct and pct < SW.db.thresholdPct / 100 then return end
  if bar.limit then
    result.rest = { verdict = result.verdict, pct = result.pct, smeltBar = result.smeltBar, stale = result.stale,
      saleChance = result.saleChance }
  end
  result.verdict, result.smeltBar, result.pct, result.stale = "smelt", bar, pct, false
end

-- Returns a table, or nil when there is nothing worth showing.
--   verdict: "ah", "hold", "vendor", "smelt", "ahonly", "nodata"
--   ahPrice / vendorPrice: per item, copper. ahNet is ahPrice after the AH cut.
--   pct: ahNet / vendorPrice - 1, or the best bar's for "smelt" (nil when vendorPrice is 0)
--   stale: true when the AH price is older than staleDays
--   smelt: bar prices for ores the player can smelt; smeltBar: the best, when verdict is "smelt"
--   rest: { verdict, pct, smeltBar, stale, saleChance } for ore left over when smeltBar.limit caps an alloy
--   saleChance, sold, failed: from Journalator's sale history, when it was used
-- notInBags: how many of the item are on show outside the bags (a loot slot), so
-- alloy advice is capped against them too.
function SW.Evaluate(link, isBound, notInBags)
  if not link then return nil end

  local itemID = SW.ItemID(link)
  if itemID and SW.charDB and SW.charDB.ignored[itemID] then return nil end
  if itemID and SW.db.ignoreVendorItems and SW.db.vendorItems[itemID] then return nil end

  local name, _, quality, _, _, _, _, _, _, _, sellPrice, _, _, bindType = C_Item.GetItemInfo(link)
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
  if ahPrice then
    -- Auctionator returns nil for age when the last sighting was over 21 days ago.
    result.stale = (age == nil) or (age > SW.db.staleDays)
    result.ahNet = ahPrice * (1 - SW.AH_CUT)
    if sellPrice == 0 then
      result.verdict = "ahonly"
    else
      result.pct = result.ahNet / sellPrice - 1
      result.verdict = result.pct >= SW.db.thresholdPct / 100 and "ah" or "vendor"
    end
  elseif sellPrice > 0 then
    result.verdict = "nodata"
  end

  -- An AH verdict only stands if the item tends to sell. Below the cut-off, hold it
  -- while the expected return (chance x AH price) still beats the vendor, else vendor.
  if SW.db.useSaleHistory and (result.verdict == "ah" or result.verdict == "ahonly") then
    local h = SW.SaleHistory(name, ahPrice)
    if h then
      result.saleChance, result.sold, result.failed = h.chance, h.sold, h.failed
      if h.chance < SW.db.minSaleRatePct / 100 then
        local holds = result.verdict == "ahonly" or h.chance * result.ahNet >= sellPrice
        result.verdict = holds and "hold" or "vendor"
        -- Vendoring because it won't sell: show the expected AH return, not the list price.
        if not holds then result.pct = h.chance * result.ahNet / sellPrice - 1 end
      end
    end
  end

  result.smelt = SW.SmeltPrices(itemID, notInBags)
  local full, capped
  for _, bar in ipairs(result.smelt or {}) do
    if bar.limit then
      if not capped or bar.net > capped.net then capped = bar end
    elseif not full or bar.net > full.net then
      full = bar
    end
  end
  smeltOver(result, full, sellPrice)
  smeltOver(result, capped, sellPrice)

  if not result.verdict then return nil end
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
      _, _, _, _, numAvailable, _, _, extendedCost = GetMerchantItemInfo(i)
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
