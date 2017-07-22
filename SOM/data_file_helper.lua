require 'io'
require 'math'
require 'torch'

function is_data_line(line)
	if line ~= "" and line:sub(1, 1) ~= "@" then return true
	else return false end
end

function read_arff_data(path)
	local capture = "([^,]+)"

	local rows, cols = 0, -1
	local file = assert(io.open(path, "r"))
	for line in file:lines() do
		if is_data_line(line) then
			if rows == 0 then
				for value in line:gmatch(capture) do
					cols = cols+1
				end
			end
			rows = rows+1
		end
	end
	file:close()

	local data = torch.FloatTensor(rows, cols)
	local i = 1
	file = assert(io.open(path, "r"))
	for line in file:lines() do
		if is_data_line(line) then
			local j = 1
			for value in line:gmatch(capture) do
				if j <= cols then
					data[i][j] = tonumber(value)
					j = j+1
				end
			end
			i = i+1
		end
	end
	file:close()

	return data
end

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

	if assignments:nElement() == 0 then
		--rare case when there is no assignment pair at all, we must write at least one
		file:write("0 0\n")
	else
		local q = assignments:size(1)
		for i = 1, q do
			file:write(assignments[i][1]-1, " ", assignments[i][2]-1, "\n")
		end
	end

	file:close()
end

