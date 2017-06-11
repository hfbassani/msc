require 'io'
require 'math'

--custom arff file with class labels bitmask
function read_arff_data(path, normalize)
	local rows = {}

	local capture = "([^,]+)"
	local file = assert(io.open(path, "r"))
	for line in file:lines() do
		if line ~= "" and line:sub(1, 1) ~= "@" then
			local row = {}
			for value in line:gmatch(capture) do
				table.insert(row, value)
			end
			--remove class column
			table.remove(row)
			table.insert(rows, row)
		end
	end
	file:close()

	if normalize then
		local dn, dim = table.getn(rows), table.getn(rows[1])
		--for every attribute
		for j = 1, dim do
			--minimum and maximum
			min, max = math.huge, -math.huge
			for i = 1, dn do
				local v = rows[i][j]
				min = math.min(min, v)
				max = math.max(max, v)
			end

			--normalize
			local rng = max-min
			if rng > 1e-12 then
				for i = 1, dn do
					local v = rows[i][j]
					rows[i][j] = (v-min)/rng
				end
			else
				for i = 1, dn do
					rows[i][j] = 0
				end
			end
		end
	end

	return rows
end

--results file without cluster descriptions
function write_results_file(path, assignments, relevances, cn, dim)
	local file = assert(io.open(path, "w"))
	file:write(cn, " ", dim, "\n")

	for i = 1, cn do
		file:write(i-1)
		for j = 1, dim do
			file:write(" ", relevances[i][j])
		end
		file:write("\n")
	end

	local any_assg = false
	local dn = table.getn(assignments)
	for i = 1, dn do
		local q = table.getn(assignments[i])
		for j = 1, q do
			file:write(i-1, " ", assignments[i][j]-1, "\n")
			any_assg = true
		end
	end

	--rare case when there is no assignment pair at all, we must write at least one
	if not any_assg then
		file:write("0 0\n")
	end
	file:close()
end

