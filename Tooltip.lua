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

  local text, cr, cg, cb
  if r.verdict == "ah" then
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
  if r.ahNet then
    tooltip:AddDoubleLine("  AH after cut / vendor", money(r.ahNet) .. " / " .. money(r.vendorPrice), 0.7, 0.7, 0.7, 1, 1, 1)
    -- Display-only multiplication of the per-item figures, so it stays out of SW.Evaluate.
    if count and count > 1 then
      tooltip:AddDoubleLine("  Stack x" .. count .. ": AH after cut / vendor",
        money(r.ahNet * count) .. " / " .. money(r.vendorPrice * count), 0.7, 0.7, 0.7, 1, 1, 1)
    end
  end
  tooltip:Show() -- resize to fit the new lines
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addLines)
