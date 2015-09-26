local deferred = require('deferred')

local queue = {1, 4, 7, 2}

function x2(n)
	local d = deferred.new()
	d:resolve(n*2)
	return d
end

function map(list, fn)
	local d = deferred.new()
	local results = {}
	local function donext(i)
		if i > #list then
			d:resolve(results)
		else
			fn(list[i]):next(function(res)
				table.insert(results, res)
				donext(i+1)
			end, function(err)
				d:reject(err)
			end)
		end
	end
	donext(1)
	return d
end

function all(list)
	-- resolve when each is resolved/rejected
end

function first(list)
	-- resolve when first is resolved/rejected
end

seq({5, 2, 1, 4}, x2):next(function(res)
	for _, n in ipairs(res) do
		print(n)
	end
end)
