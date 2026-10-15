-- Hybrids: what you get when two different Freeks fuse.
--
-- A hybrid is identified by the base species that went into it, e.g. "Nerdle+Oinkle".
-- Fusing a hybrid again adds its species to the mix ("Flexo+Nerdle+Oinkle"); when one
-- species is in there more than once it gets a count ("Nerdle*2+Oinkle"). Counts are kept
-- in lowest terms, so the same mix always has the same id however it was made, and
-- fusing two of the same species just makes that species again.
--
-- Everything else about a hybrid comes from its id, so nothing needs to be listed by hand:
--   name    the two main species' names mashed together (Chuckles + Flexo = "Chuxo")
--   rarity  the rarest species in it (fusing never raises rarity)
--   look    built by FreekModel from the two main species: the first one's body (legs,
--           arms, tail) wearing the second one's head, body colours blended
-- Each hybrid Freek also stores its own income (see Breeding.babyIncome).
--
-- Freeks.byId[id] works for hybrid ids too (Freeks.luau asks this module).

local Rarities = require(script.Parent.Rarities)

local Hybrids = {}

function Hybrids.isHybrid(id: string): boolean
	return string.find(id, "+", 1, true) ~= nil
end

-- { [baseId] = count } for any species or hybrid id.
function Hybrids.counts(id: string): { [string]: number }
	local counts = {}
	for piece in string.gmatch(id, "[^+]+") do
		local base, n = string.match(piece, "^(.-)%*(%d+)$")
		base = base or piece
		counts[base] = (counts[base] or 0) + (tonumber(n) or 1)
	end
	return counts
end

local function gcd(a: number, b: number): number
	while b ~= 0 do
		a, b = b, a % b
	end
	return a
end

-- The id for a mix of species (a plain species id if there's only one).
function Hybrids.key(counts: { [string]: number }): string
	local ids = {}
	local divisor = 0
	for id, n in counts do
		table.insert(ids, id)
		divisor = gcd(divisor, n)
	end
	table.sort(ids)
	local pieces = {}
	for _, id in ids do
		local n = counts[id] // divisor
		table.insert(pieces, if n > 1 then id .. "*" .. n else id)
	end
	return table.concat(pieces, "+")
end

-- What two species (or hybrids) fuse into.
function Hybrids.combine(a: string, b: string): string
	local counts = Hybrids.counts(a)
	for id, n in Hybrids.counts(b) do
		counts[id] = (counts[id] or 0) + n
	end
	return Hybrids.key(counts)
end

-- The species in a hybrid, most-used first (ties alphabetical).
function Hybrids.ranked(id: string): { string }
	local counts = Hybrids.counts(id)
	local list = {}
	for base in counts do
		table.insert(list, base)
	end
	table.sort(list, function(a, b)
		if counts[a] ~= counts[b] then
			return counts[a] > counts[b]
		end
		return a < b
	end)
	return list
end

-- Name mashing ------------------------------------------------------------------------

local VOWELS = "aeiouyAEIOUY"

local function letters(name: string): string
	return (string.gsub(name, "[^%a]", ""))
end

-- The start of a name up to its first vowels: "Chuckles" -> "Chu", "Glamora" -> "Gla".
local function front(name: string): string
	local word = letters(name)
	local _, finish = string.find(word, "^[^" .. VOWELS .. "]*[" .. VOWELS .. "]+")
	return if finish then string.sub(word, 1, finish) else word
end

-- The rest of a name after its first vowel: "Oinkle" -> "inkle", "Flexo" -> "xo".
local function back(name: string): string
	local word = letters(name)
	local _, finish = string.find(word, "^[^" .. VOWELS .. "]*[" .. VOWELS .. "]")
	local rest = if finish then string.sub(word, finish + 1) else word
	if #rest < 2 then
		rest = string.sub(word, -3)
	end
	return string.lower(rest)
end

-- Mashes two names, trying both orders and keeping the one that sounds most like a name.
local function mash(nameA: string, nameB: string): string
	local wordA, wordB = letters(nameA), letters(nameB)
	local average = (#wordA + #wordB) / 2
	local candidates = {}
	for _, pair in { { wordA, wordB }, { wordB, wordA } } do
		local start = front(pair[1])
		local penalty = if #start < 3 then 2 else 0 -- weak start, like "Oi"
		table.insert(candidates, { start .. back(pair[2]), penalty })
		-- Fallbacks for when the parents' names look alike: plain halves, then a short mix.
		local first = string.sub(pair[1], 1, math.ceil(#pair[1] / 2))
		local second = string.lower(string.sub(pair[2], math.ceil(#pair[2] / 2) + 1))
		table.insert(candidates, { first .. second, 3 })
		table.insert(candidates, { string.sub(pair[1], 1, 2) .. string.lower(string.sub(pair[2], -3)), 6 })
	end
	local best, bestScore = nil, math.huge
	for _, entry in candidates do
		local candidate, score = entry[1], entry[2]
		score += math.abs(#candidate - average)
		if #candidate < 5 then
			score += 3 -- too short
		end
		local lower = string.lower(candidate)
		if lower == string.lower(wordA) or lower == string.lower(wordB) then
			score += 100 -- just one of the parents' names again
		end
		if score < bestScore or (score == bestScore and candidate < best) then
			best, bestScore = candidate, score
		end
	end
	return string.upper(string.sub(best, 1, 1)) .. string.sub(best, 2)
end

-- Builds the species-like info for a hybrid id. get(baseId) returns a base species.
function Hybrids.info(id: string, get)
	local ranked = Hybrids.ranked(id)
	if #ranked < 2 then
		return nil
	end
	local rank = 1
	for _, base in ranked do
		local species = get(base)
		if not species then
			return nil
		end
		rank = math.max(rank, Rarities.rank[species.rarity])
	end
	local a, b = get(ranked[1]), get(ranked[2])
	local name = mash(a.name, b.name)
	if ranked[3] then
		name ..= "-" .. front(get(ranked[3]).name)
	end
	return {
		id = id,
		name = name,
		rarity = Rarities.order[rank],
		income = a.income + b.income, -- only a guide: each hybrid Freek stores its own
		hybrid = true,
		series = "Hybrid",
		walk = a.walk,
		parts = ranked,
		look = { hybrid = { a = a.id, b = b.id } },
		order = math.huge,
	}
end

return Hybrids
