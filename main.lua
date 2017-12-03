local limgen = require 'limerickgen'

for l in io.lines() do 
	print(limgen.createLimerick())
end

-----------------------------------------------------------------------------
-- Create a json-object with place rhymes

-- do
-- 	local places = JSONtoTable('places.json')
-- 	local adjs = JSONtoTable('adjs.json')

-- 	local ok_places = {}
-- 	for _, c in pairs(places) do 
-- 		local rh = tostring(pn.rhymes(string.lower(c)))
-- 		if rh ~= '[]' and rh then
-- 			print(c)
			
-- 			ok_places[#ok_places+1] = {}
-- 			local rhymes = ok_places[#ok_places]
			
-- 			-- First entry of rhymes array is a country name
-- 			table.insert(rhymes, c)

-- 			for w in rh:gmatch("u'(.-)'") do
-- 				for _, a in pairs(adjs) do 
-- 					if a == w then 
-- 						table.insert(rhymes, a) 
-- 					end
-- 				end
-- 			end

-- 			if #rhymes <= 1 then ok_places[#ok_places] = nil end
-- 		end
-- 	end

-- 	local str = json.encode(ok_places)
-- 	local file = io.open('place_rhymes2.json', 'w')
-- 	file:write(str)
-- 	file:close()
-- end

-----------------------------------------------------------------------------
-- Create a json-object with objects rhymes

-- do
-- 	local objs = JSONtoTable('objs.json')
-- 	local nouns = JSONtoTable('nouns.json')

-- 	local obj_rhymes = {}

-- 	for _, obj in pairs(objs) do
-- 		local rh = tostring(pn.rhymes(string.lower(obj)))

-- 		if rh and rh ~= '[]' then
-- 			print(obj)

-- 			obj_rhymes[#obj_rhymes + 1] = {}
-- 			local rhymes = obj_rhymes[#obj_rhymes]

-- 			table.insert(rhymes, obj)

-- 			for w in rh:gmatch("u'(.-)'") do
-- 				for _, o in pairs(objs) do
-- 					if w == o and w ~= obj then 
-- 						table.insert(rhymes, o)
-- 					end
-- 				end

-- 				for _, n in pairs(nouns) do
-- 					if w == n and w ~= obj then
-- 						for k, r in pairs(rhymes) do 
-- 							if r == n then table.remove(rhymes, k) end
-- 						end

-- 						table.insert(rhymes, n)
-- 					end
-- 				end
-- 			end

-- 			if #rhymes <= 1 then obj_rhymes[#obj_rhymes] = nil end
-- 		end
-- 	end

-- 	local str = json.encode(obj_rhymes)
-- 	local file = io.open('obj_rhymes_2.json', 'w')
-- 	file:write(str)
-- 	file:close()
-- end

-----------------------------------------------------------------------------

-- remove duplicates
-- do
-- 	local nouns = JSONtoTable('nouns.json')

-- 	local t = {}
-- 	for k, v in pairs(nouns) do
-- 		if not t[v] then t[v] = 1 else t[v] = t[v] + 1 end
-- 	end

-- 	for k, v in pairs(nouns) do
-- 		if t[v] > 1 then 
-- 			table.remove(nouns, k)
-- 			t[v] = t[v] - 1
-- 		end
-- 	end

-- 	local f = io.open('nouns.json', 'w')
-- 	f:write(json.encode(nouns))
-- end

-- make plurals
-- do
-- 	local nouns = JSONtoTable('nouns.json')
-- 	local inflect = py.import('inflect')
-- 	local en = inflect.engine()

-- 	for k, v in pairs(nouns) do
-- 		nouns[k] = en.plural(v)
-- 	end

-- 	local f = io.open('nouns.json', 'w')
-- 	f:write(json.encode(nouns))
-- end
