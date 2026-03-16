local Format = {}

function Format.Commas(value)
	local formatted = tostring(math.floor(value))

	while true do
		local replaced, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = replaced

		if count == 0 then
			break
		end
	end

	return formatted
end

function Format.TitleFromKey(key)
	return key:gsub("(%l)(%u)", "%1 %2")
end

function Format.MakeProduceKey(cropId, mutation)
	return string.format("%s::%s", cropId, mutation or "None")
end

function Format.SplitProduceKey(key)
	local cropId, mutation = string.match(key, "([^:]+)::(.+)")
	return cropId, mutation or "None"
end

return Format
