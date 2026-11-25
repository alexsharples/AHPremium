local _, SW = ...

-- Optional Journalator integration. Journalator only knows the player's own auctions,
-- so this is "how often have I sold this", not market-wide sell-through.
local MIN_LISTINGS = 3 -- fewer than this and the history says too little to act on

-- Returns { chance, sold, failed } for an item, or nil when Journalator's Statistics
-- module isn't loaded or there are too few past listings. chance is the sale rate,
-- scaled down when today's AH price is above the most the player has sold it for.
-- Journalator's prices are per unit before the AH cut, like Auctionator's.
function SW.SaleHistory(itemName, ahPrice)
  local api = itemName and Journalator and Journalator.API and Journalator.API.v1
  -- The base addon defines stub counts; only the Statistics module adds MaxSold.
  if not api or not api.GetRealmMaxSoldByItemName then return nil end

  local okS, sold = pcall(api.GetRealmSuccessCountByItemName, SW.callerID, itemName)
  local okF, failed = pcall(api.GetRealmFailureCountByItemName, SW.callerID, itemName)
  if not okS or not okF or not sold or not failed or sold + failed < MIN_LISTINGS then return nil end

  local chance = sold / (sold + failed)
  local okM, maxSold = pcall(api.GetRealmMaxSoldByItemName, SW.callerID, itemName)
  if okM and maxSold and maxSold > 0 and ahPrice and ahPrice > maxSold then
    chance = chance * maxSold / ahPrice
  end
  return { chance = chance, sold = sold, failed = failed }
end
