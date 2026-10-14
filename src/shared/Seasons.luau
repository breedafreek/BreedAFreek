-- Seasons for Seasonal Freeks. A Freek with `season = "Halloween"` can only be bred (or
-- bought, if it has a price) while that season is running. Once owned it's kept forever
-- and still earns, trades and breeds year-round.
--
-- Dates are UTC, inclusive, and must not wrap past New Year.

local Seasons = {}

Seasons.list = {
	Spring = { name = "Spring", color = Color3.fromRGB(255, 170, 220), from = { 3, 20 }, to = { 4, 30 } },
	Summer = { name = "Summer", color = Color3.fromRGB(255, 220, 60), from = { 6, 21 }, to = { 8, 31 } },
	Halloween = { name = "Halloween", color = Color3.fromRGB(255, 130, 20), from = { 10, 1 }, to = { 10, 31 } },
	Winter = { name = "Winter", color = Color3.fromRGB(140, 220, 255), from = { 12, 1 }, to = { 12, 31 } },
}

function Seasons.isActive(seasonId: string?, now: number?): boolean
	local season = seasonId and Seasons.list[seasonId]
	if not season then
		return false
	end
	local date = os.date("!*t", now or os.time())
	local today = date.month * 100 + date.day
	return today >= season.from[1] * 100 + season.from[2] and today <= season.to[1] * 100 + season.to[2]
end

-- True if this species can be obtained right now (always true for non-seasonal Freeks).
function Seasons.available(species, now: number?): boolean
	return species.season == nil or Seasons.isActive(species.season, now)
end

return Seasons
