local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Format.money(n: number): string
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
