local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Format.money(n: number): string
	if n < 100 and n ~= math.floor(n) then
		-- Small fused incomes like $2.2/s.
		local text = string.format("%.1f", math.floor(n * 10) / 10):gsub("%.0$", "")
		return "$" .. text
	end
	n = math.floor(n)
	if n < 1000 then
		return "$" .. n
	end
	local i = 1
	local value = n
	while value >= 1000 and i < #SUFFIXES do
		value /= 1000
		i += 1
	end
	local text = string.format("%.1f", value):gsub("%.0$", "")
	return "$" .. text .. SUFFIXES[i]
end

-- A big number with a suffix and no "$" (Speed: 12.5K).
function Format.number(n: number): string
	return (string.gsub(Format.money(n), "^%$", ""))
end

-- A weight: "0.82 kg", "12.4 kg", "1,250 kg".
function Format.weight(kg: number): string
	if kg < 10 then
		return string.format("%.2f kg", kg)
	elseif kg < 100 then
		return string.format("%.1f kg", kg)
	end
	return Format.number(math.floor(kg + 0.5)) .. " kg"
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

return Format
