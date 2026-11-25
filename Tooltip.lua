local _, SW = ...

local boundTexts = {
  ITEM_SOULBOUND, ITEM_BIND_ON_PICKUP, ITEM_BNETACCOUNTBOUND,
  ITEM_ACCOUNTBOUND, ITEM_BIND_TO_ACCOUNT, ITEM_BIND_TO_BNETACCOUNT,
}

local function tooltipSaysBound(data)
  for _, line in ipairs(data.lines or {}) do
    local text = line.leftText
    if text then
      for _, bound in ipairs(boundTexts) do
        if text == bound then return true end
      end
    end
  end
  return false
end

local function money(copper)
  return C_CurrencyInfo.GetCoinTextureString(math.floor(copper + 0.5))
end

-- Ores that may sell better as bars. Each smelts one ore into one bar, and one Copper
-- plus one Tin Bar make two Bronze Bars. Spells are the Smelt Copper/Tin recipes.
local BRONZE_BAR, SMELT_BRONZE = 2841, 2659
local smelting = {
  [2770] = { bar = 2840, spell = 2657, name = "Copper Bar", -- Copper Ore
    partner = "Tin", partnerOre = 2771, partnerBar = 3576, partnerSpell = 3304 },
  [2771] = { bar = 3576, spell = 3304, name = "Tin Bar", -- Tin Ore
    partner = "Copper", partnerOre = 2770, partnerBar = 2840, partnerSpell = 2657 },
}

-- Treat the recipe as known if the client lacks IsPlayerSpell, rather than hide smelting.
local function knows(spellID)
  return not IsPlayerSpell or IsPlayerSpell(spellID)
end

local function ahNet(itemID)
  local ok, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, SW.callerID, itemID)
  return ok and price and price * (1 - SW.AH_CUT) or nil
end

-- Per-ore value after the AH cut for each bar the player can actually make, plus the best.
local function smeltPrices(itemID)
  local s = itemID and smelting[itemID]
  if not s or not knows(s.spell) then return nil end
  local prices, best = {}, nil
  local function add(name, net, label)
    if not net or net <= 0 then return end
    local p = { name = name, net = net, label = label or (name .. " after cut") }
    prices[#prices + 1] = p
    if not best or net > best.net then best = p end
  end

  add(s.name, ahNet(s.bar))

  -- Bronze needs the other half in the bags: its bar, or its ore if the player can smelt it.
  local bronze = ahNet(BRONZE_BAR)
  local partnerOres = knows(s.partnerSpell) and C_Item.GetItemCount(s.partnerOre) or 0
  if bronze and knows(SMELT_BRONZE) and C_Item.GetItemCount(s.partnerBar) + partnerOres > 0 then
    -- Two Bronze use up the partner too, so subtract the best it would fetch on its own.
    local partnerVendor = select(11, C_Item.GetItemInfo(s.partnerOre)) or 0
    local partnerValue = math.max(ahNet(s.partnerBar) or 0, ahNet(s.partnerOre) or 0, partnerVendor)
    add("Bronze Bar (with " .. s.partner .. ")", 2 * bronze - partnerValue,
      "Bronze Bar after cut, less the " .. s.partner)
  end
  return prices, best
end

local function addLines(tooltip, data)
  if not SW.db or not SW.db.showTooltip then return end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return end

  if not data then return end

  -- Bag tooltips often carry no hyperlink, so look the item up by bag and slot.
  local link, bound, count
  local info = tooltip.processingInfo or tooltip.info
  if info and info.getterName == "GetBagItem" and info.getterArgs then
    local bag, slot = unpack(info.getterArgs)
    local ci = C_Container.GetContainerItemInfo(bag, slot)
    if ci then link, bound, count = ci.hyperlink, ci.isBound, ci.stackCount end
  end
  link = link or data.hyperlink or (data.id and select(2, C_Item.GetItemInfo(data.id)))
  if not link then return end

  local r = SW.Evaluate(link, bound or tooltipSaysBound(data))
  if not r then return end

  -- Smelting wins when the best bar beats selling the ore on the AH and clears the
  -- same vendor threshold the ore verdict uses.
  local smelt, best = smeltPrices(SW.ItemID(link))
  local smeltPct = best and r.vendorPrice > 0 and best.net / r.vendorPrice - 1
  local smeltWins = best and best.net > (r.ahNet or 0)
    and (not smeltPct or smeltPct >= SW.db.thresholdPct / 100)

  local text, cr, cg, cb
  if smeltWins then
    text = smeltPct
      and string.format("AH Premium: smelt to %s, sell on AH (+%d%% over vendor)", best.name, smeltPct * 100 + 0.5)
      or "AH Premium: smelt to " .. best.name .. ", sell on AH"
    cr, cg, cb = 0.2, 1, 0.2
  elseif r.verdict == "ah" then
    text = string.format("AH Premium: sell on AH (+%d%% over vendor)", r.pct * 100 + 0.5)
    cr, cg, cb = 0.2, 1, 0.2
  elseif r.verdict == "vendor" then
    text = string.format("AH Premium: vendor it (AH %+d%%)", r.pct * 100 + (r.pct < 0 and -0.5 or 0.5))
    cr, cg, cb = 1, 0.82, 0.2
  elseif r.verdict == "ahonly" then
    text = "AH Premium: no vendor price, AH only"
    cr, cg, cb = 0.2, 1, 0.2
  else
    text = "AH Premium: no AH data"
    cr, cg, cb = 0.6, 0.6, 0.6
  end

  if r.stale and r.verdict ~= "nodata" then
    text = text .. " (stale)"
    cr, cg, cb = cr * 0.6, cg * 0.6, cb * 0.6
  end

  tooltip:AddLine(text, cr, cg, cb)
  if not SW.db.showPriceBreakdown then
    tooltip:Show()
    return
  end
  if r.ahNet then
    tooltip:AddDoubleLine("  AH after cut / vendor", money(r.ahNet) .. " / " .. money(r.vendorPrice), 0.7, 0.7, 0.7, 1, 1, 1)
    -- Display-only multiplication of the per-item figures, so it stays out of SW.Evaluate.
    if count and count > 1 then
      tooltip:AddDoubleLine("  Stack x" .. count .. ": AH after cut / vendor",
        money(r.ahNet * count) .. " / " .. money(r.vendorPrice * count), 0.7, 0.7, 0.7, 1, 1, 1)
    end
  end
  for _, p in ipairs(smelt or {}) do
    tooltip:AddDoubleLine("  Smelted: " .. p.label, money(p.net), 0.7, 0.7, 0.7, 1, 1, 1)
  end
  tooltip:Show() -- resize to fit the new lines
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addLines)
