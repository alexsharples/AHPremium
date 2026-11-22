local _, SW = ...

local ROW_HEIGHT = 24
local frame, content, emptyText
local rows = {}

local function newRow(index)
  local row = CreateFrame("Frame", nil, content)
  row:SetSize(290, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
  row:EnableMouse(true)
  row:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.itemID)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)

  row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.remove:SetSize(70, 20)
  row.remove:SetPoint("RIGHT")
  row.remove:SetText("Remove")

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.text:SetPoint("LEFT", 4, 0)
  row.text:SetPoint("RIGHT", row.remove, "LEFT", -6, 0)
  row.text:SetJustifyH("LEFT")
  row.text:SetWordWrap(false)

  rows[index] = row
  return row
end

local function build()
  frame = CreateFrame("Frame", "AHPremiumIgnoreList", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(340, 400)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetScript("OnShow", function() SW.RefreshIgnoreList() end)
  frame:Hide()
  tinsert(UISpecialFrames, "AHPremiumIgnoreList") -- close with Esc

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -6)
  title:SetText("AH Premium: ignored items")

  local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -34)
  scroll:SetPoint("BOTTOMRIGHT", -32, 12)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(290, 1)
  scroll:SetScrollChild(content)

  emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyText:SetPoint("CENTER")
  emptyText:SetText("No ignored items on this character.")

  frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  frame:SetScript("OnEvent", function() SW.RefreshIgnoreList() end)
end

function SW.RefreshIgnoreList()
  if not frame or not frame:IsShown() then return end

  local ids = {}
  for id in pairs(SW.charDB.ignored) do ids[#ids + 1] = id end

  local function nameOf(id)
    return (C_Item.GetItemInfo(id)) or ("Item " .. id)
  end
  table.sort(ids, function(a, b) return nameOf(a):lower() < nameOf(b):lower() end)

  for i, id in ipairs(ids) do
    local row = rows[i] or newRow(i)
    local _, link = C_Item.GetItemInfo(id)
    if not link then C_Item.RequestLoadItemDataByID(id) end
    row.itemID = id
    row.text:SetText(link or ("Item " .. id))
    row.remove:SetScript("OnClick", function()
      SW.charDB.ignored[id] = nil
      SW.RefreshBags()
      SW.RefreshIgnoreList()
    end)
    row:Show()
  end
  for i = #ids + 1, #rows do rows[i]:Hide() end

  content:SetHeight(math.max(1, #ids * ROW_HEIGHT))
  emptyText:SetShown(#ids == 0)
end

function SW.ShowIgnoreList()
  if not frame then build() end
  frame:SetShown(not frame:IsShown())
end
