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

-- Text and colour for a verdict: the item's own, or the leftover ore's after a capped alloy.
local function verdictLine(prefix, v)
  local text, cr, cg, cb
  if v.verdict == "smelt" then
    local bar = v.smeltBar.limit and (v.smeltBar.limit .. " to " .. v.smeltBar.name) or ("to " .. v.smeltBar.name)
    text = v.pct
      and string.format("smelt %s, sell on AH (+%d%% over vendor)", bar, v.pct * 100 + 0.5)
      or "smelt " .. bar .. ", sell on AH"
    cr, cg, cb = 0.2, 1, 0.2
  elseif v.verdict == "ah" then
    text = string.format("sell on AH (+%d%% over vendor)", v.pct * 100 + 0.5)
    cr, cg, cb = 0.2, 1, 0.2
  elseif v.verdict == "vendor" then
    text = string.format("vendor it (AH %+d%%)", v.pct * 100 + (v.pct < 0 and -0.5 or 0.5))
    cr, cg, cb = 1, 0.82, 0.2
  elseif v.verdict == "ahonly" then
    text = "no vendor price, AH only"
    cr, cg, cb = 0.2, 1, 0.2
  else
    text = "no AH data"
    cr, cg, cb = 0.6, 0.6, 0.6
  end

  if v.stale and v.verdict ~= "nodata" then
    text = text .. " (stale)"
    cr, cg, cb = cr * 0.6, cg * 0.6, cb * 0.6
  end
  return prefix .. text, cr, cg, cb
end

local function addLines(tooltip, data)
  if not SW.db or not SW.db.showTooltip then return end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return end

  if not data then return end

  -- Bag tooltips often carry no hyperlink, so look the item up by bag and slot.
  local link, bound, count, notInBags
  local info = tooltip.processingInfo or tooltip.info
  if info and info.getterName == "GetBagItem" and info.getterArgs then
    local bag, slot = unpack(info.getterArgs)
    local ci = C_Container.GetContainerItemInfo(bag, slot)
    if ci then link, bound, count = ci.hyperlink, ci.isBound, ci.stackCount end
  elseif info and info.getterName == "GetLootItem" and info.getterArgs then
    -- Loot isn't in the bags yet, so tell Evaluate how much is coming.
    notInBags = select(3, GetLootSlotInfo(info.getterArgs[1]))
  end
  link = link or data.hyperlink or (data.id and select(2, C_Item.GetItemInfo(data.id)))
  if not link then return end

  local r = SW.Evaluate(link, bound or tooltipSaysBound(data), notInBags)
  if not r then return end

  tooltip:AddLine(verdictLine("AH Premium: ", r))
  if r.rest and r.rest.verdict then
    tooltip:AddLine(verdictLine("AH Premium: the rest, ", r.rest))
  end
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
  for _, p in ipairs(r.smelt or {}) do
    tooltip:AddDoubleLine("  Smelted: " .. p.label, money(p.net), 0.7, 0.7, 0.7, 1, 1, 1)
  end
  tooltip:Show() -- resize to fit the new lines
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addLines)
