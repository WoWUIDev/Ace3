local recurse = false
function serialize(o, indent, file)
	if not file then file = io.stdout end

	if type(o) == "number" then
		file:write(o)
	elseif type(o) == "string" then
		file:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		file:write(o and "true" or "false")
	elseif type(o) == "function" then
		file:write("nil --[["..tostring(o).."]]")
	elseif type(o) == "table" then
		if not indent then indent = "  " else indent = indent .. "  " end
		local old = recurse
		recurse = true
		file:write("{\n")
		-- Check to see if we have an integer section
		if #o > 0 then
			for k,v in ipairs(o) do
				file:write(indent)
				serialize(v, indent, file)
				file:write(",\n")
			end
		end

		for k,v in pairs(o) do
			local mask
			if type(k) == "number" and #o > 0 and k > 0 and k <= #o then
				mask = true
			end

			if not mask then
				file:write(indent .. "[")
				serialize(k, indent, file)
				file:write("] = ")
				serialize(v, indent, file)
				file:write(",\n")
			end
		end
		recurse = old
		file:write(string.sub(indent,1,-3) .. (recurse and "}" or "}\n"))
	else
		error("Cannot serialize a " .. type(o))
	end
end
