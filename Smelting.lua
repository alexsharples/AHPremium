local _, SW = ...

-- Classic smelting recipes, keyed by ore. Each ore makes one bar, except Dark Iron,
-- which takes eight. Spells are the Smelt recipes, used to check the player knows them.
-- Elementium is left out: its ore is bind on pickup.
local oreRecipes = {
  [2770]  = { spell = 2657,  bar = 2840,  name = "Copper Bar" },
  [2771]  = { spell = 3304,  bar = 3576,  name = "Tin Bar" },
  [2775]  = { spell = 2658,  bar = 2842,  name = "Silver Bar" },
  [2772]  = { spell = 3307,  bar = 3575,  name = "Iron Bar" },
  [2776]  = { spell = 3308,  bar = 3577,  name = "Gold Bar" },
  [3858]  = { spell = 10097, bar = 3860,  name = "Mithril Bar" },
  [7911]  = { spell = 10098, bar = 6037,  name = "Truesilver Bar" },
  [10620] = { spell = 16153, bar = 12359, name = "Thorium Bar" },
  [11370] = { spell = 14891, bar = 11371, name = "Dark Iron Bar", ores = 8 },
}

-- Alloys: one of each input makes `yield` bars. Inputs are { itemID, short name }.
local alloys = {
  { spell = 2659, bar = 2841, name = "Bronze Bar", yield = 2, inputs = { { 2840, "Copper" }, { 3576, "Tin" } } },
  { spell = 3569, bar = 3859, name = "Steel Bar", yield = 1, inputs = { { 3575, "Iron" }, { 3857, "Coal" } } },
}

-- So an alloy partner can also come from its ore.
local oreForBar = {}
for ore, r in pairs(oreRecipes) do oreForBar[r.bar] = ore end

-- Treat the recipe as known if the client lacks IsPlayerSpell, rather than hide smelting.
local function knows(spellID)
  return not IsPlayerSpell or IsPlayerSpell(spellID)
end

-- AH price after cut, or nil when there is none or it is stale, so old bar
-- prices can't drive a smelt recommendation.
local function freshAHNet(itemID)
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not api then return nil end
  local ok, price = pcall(api.GetAuctionPriceByItemID, SW.callerID, itemID)
  if not ok or not price then return nil end
  local okAge, age = pcall(api.GetAuctionAgeByItemID, SW.callerID, itemID)
  if not okAge or age == nil or age > SW.db.staleDays then return nil end
  return price * (1 - SW.AH_CUT)
end

local function vendorPrice(itemID)
  return select(11, C_Item.GetItemInfo(itemID)) or 0
end

-- How many of the alloy partner are in the bags, as itself or as ore the player can smelt into it.
local function partnerCount(id)
  local n = C_Item.GetItemCount(id)
  local ore = oreForBar[id]
  if ore and knows(oreRecipes[ore].spell) then n = n + C_Item.GetItemCount(ore) end
  return n
end

-- The best the partner would fetch on its own, as itself or as its ore.
local function partnerValue(id)
  local value = math.max(freshAHNet(id) or 0, vendorPrice(id))
  local ore = oreForBar[id]
  if ore then value = math.max(value, freshAHNet(ore) or 0, vendorPrice(ore)) end
  return value
end

-- Per-ore value after the AH cut for each bar the player can actually make. An alloy
-- short of partners for every ore in the bags carries `limit`, the ore it can take.
-- Called from SW.Evaluate; returns nil for anything that isn't a smeltable ore.
function SW.SmeltPrices(itemID)
  local r = itemID and oreRecipes[itemID]
  if not r or not knows(r.spell) then return nil end
  local prices = {}
  local function add(name, net, label, limit)
    if not net or net <= 0 then return end
    prices[#prices + 1] = { name = name, net = net, label = label or (name .. " after cut"), limit = limit }
  end

  local ores = r.ores or 1
  local barNet = freshAHNet(r.bar)
  add(r.name, barNet and barNet / ores, ores > 1 and (r.name .. " after cut, per ore") or nil)

  for _, a in ipairs(alloys) do
    local mine, partner = a.inputs[1], a.inputs[2]
    if partner[1] == r.bar then mine, partner = partner, mine end
    local partners = partnerCount(partner[1])
    if mine[1] == r.bar and knows(a.spell) and partners > 0 then
      local alloyNet = freshAHNet(a.bar)
      -- The alloy uses up the partner too, so subtract what it would fetch on its own.
      if alloyNet then
        add(a.name .. " (with " .. partner[2] .. ")", (a.yield * alloyNet - partnerValue(partner[1])) / ores,
          a.name .. " after cut, less the " .. partner[2],
          partners < C_Item.GetItemCount(itemID) and partners or nil)
      end
    end
  end
  return prices
end
