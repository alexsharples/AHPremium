local _, SW = ...

local icons = {}

-- icons[button] = { coin = texture, vendor = texture }, each made on first use.
local function getIcon(button, kind)
  local set = icons[button]
  if not set then
    set = {}
    icons[button] = set
  end
  local icon = set[kind]
  if not icon then
    icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface/Icons/INV_Misc_Coin_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetSize(14, 14)
    if kind == "vendor" then
      icon:SetDesaturated(true) -- grey coin: safe to vendor
      icon:SetPoint("BOTTOMRIGHT", -2, 2)
    else
      icon:SetPoint("TOPRIGHT", -2, -2) -- Scrap uses TOPLEFT
    end
    set[kind] = icon
  end
  return icon
end

local function showIcon(button, kind, show)
  if show or (icons[button] and icons[button][kind]) then
    getIcon(button, kind):SetShown(show)
  end
end

local function setIcon(button, link, isBound)
  local coin, vendor = false, false
  if link and SW.db and (SW.db.showBagIcon or SW.db.showVendorIcon) then
    local r = SW.Evaluate(link, isBound)
    if r and not r.stale then
      coin = SW.db.showBagIcon and (r.verdict == "ah" or r.verdict == "ahonly")
      vendor = SW.db.showVendorIcon and r.verdict == "vendor"
    end
  end
  showIcon(button, "coin", coin)
  showIcon(button, "vendor", vendor)
end

--[[ Blizzard bags ]]--

local function updateBlizzardButton(frame, button)
  if not button:IsShown() then return end
  local bag = (button.GetBagID and button:GetBagID()) or button.bagID or frame:GetID()
  local info = C_Container.GetContainerItemInfo(bag, button:GetID())
  setIcon(button, info and info.hyperlink, info and info.isBound)
end

local function updateContainer(frame)
  if not frame then return end
  if frame.Items then
    for _, button in ipairs(frame.Items) do updateBlizzardButton(frame, button) end
  else
    local name, i = frame:GetName(), 1
    local button = _G[name .. "Item" .. i]
    while button do
      updateBlizzardButton(frame, button)
      i = i + 1
      button = _G[name .. "Item" .. i]
    end
  end
end

local function forEachContainer(fn)
  fn(ContainerFrameCombinedBags)
  local i, frame = 1, _G.ContainerFrame1
  while frame do
    fn(frame)
    i = i + 1
    frame = _G["ContainerFrame" .. i]
  end
end

--[[ Bagnon ]]--

local function updateBagnonButton(button)
  local info = button.info
  setIcon(button, info and info.hyperlink, info and info.isBound)
end

--[[ Wiring ]]--

function SW.RefreshBags()
  forEachContainer(updateContainer)
  if _G.Bagnon and _G.Bagnon.Item then
    for _, name in ipairs({ "BagnonFrameinventory", "BagnonFramebank" }) do
      local frame = _G[name]
      if frame then
        for _, child in ipairs({ frame:GetChildren() }) do
          -- Bagnon nests buttons; refresh happens on its own Update, this is best effort.
          if child.info then updateBagnonButton(child) end
        end
      end
    end
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("BAG_UPDATE_DELAYED")
loader:RegisterEvent("AUCTION_HOUSE_CLOSED") -- a scan changes prices without moving any item
loader:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    if _G.Bagnon and _G.Bagnon.Item and _G.Bagnon.Item.Update then
      hooksecurefunc(_G.Bagnon.Item, "Update", updateBagnonButton)
    elseif ContainerFrame_Update then
      hooksecurefunc("ContainerFrame_Update", updateContainer)
    else
      if ContainerFrameCombinedBags then
        hooksecurefunc(ContainerFrameCombinedBags, "Update", updateContainer)
      end
      forEachContainer(function(frame)
        if frame and frame.Update and frame ~= ContainerFrameCombinedBags then
          hooksecurefunc(frame, "Update", updateContainer)
        end
      end)
    end
  else
    SW.RefreshBags()
  end
end)
