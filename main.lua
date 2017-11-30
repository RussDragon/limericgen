local json = require('json')
-- local serpent = require('serpent')
local py = require('python')
local pn = py.import('pronouncing')

math.randomseed( os.time() )

local lim_sizes = {}
lim_sizes[1] = 9
lim_sizes[2] = 8
lim_sizes[3] = 6
lim_sizes[4] = 6
lim_sizes[5] = 9

local syll_stress = 3

local function count_string_syllables(str)
	if not str or type(str) ~= 'string' then error('String must be passed') end

	local syl = 0
	for w in str:gmatch('%w+') do 
		syl = syl + tonumber(pn.syllable_count(pn.phones_for_word(string.lower(w))[0]))
	end

	return syl
end

local function JSONtoTable(path)
	local f = io.open(path)
	local js = f:read('*a')
	f:close()

	return json.decode(js)
end

local function createLimeric()
	local occupations = JSONtoTable('occupations.json')
	local nouns = JSONtoTable('nouns.json')

	local places_rhymes = JSONtoTable('place_rhymes.json')

	local descr = JSONtoTable('descriptions.json')

	local objects_rhymes = JSONtoTable('obj_rhymes.json')
	local objects = JSONtoTable('objs.json')

	local who = {'', ''}
	local place_name = ''
	local adjs = {}
	local objs = {'','',''}

	do
		do
			local who_article = ''
			local who_syl = 0
			local who_stress = 0

			-- 1 – a/an young/old (2syl), 2 – a/an (3syl)
			if math.random(1, 2) == 1 then
				who_syl = 2
				who_stress = 1

				if math.random(1, 2) == 1 then who_article = 'an Old ' else who_article = 'a Young ' end
			else
				who_syl = 3
				who_stress = 2

				who_article = nil
			end

			local ok_occup = {}
			for _, occ in pairs(occupations) do
				local phones = pn.phones_for_word(string.lower(occ))[0] or ''
				local occ_syl = pn.syllable_count(phones)
				local stress = pn.stresses(phones)

				if occ_syl == who_syl and stress:find('1') == who_stress then
					occ = occ:gsub("^%l", string.upper)
					local vowels = 'AEIOU'
					if not who_article then
						if vowels:find(occ:match('.')) then occ = 'an ' .. occ else occ = 'a ' .. occ end
					else
						occ = who_article .. occ
					end

					table.insert(ok_occup, occ)
				end
			end

			who[1] = ok_occup[math.random(1, #ok_occup)]
			who[2] = who[1]:match(' (.+)')
		end

		local place_syl = lim_sizes[1] - 8
		local ok_places = {}

		for _, place in pairs(places_rhymes) do 
			local ok_adjs = {}
			local place_name = place[1]

			local phones = pn.phones_for_word(string.lower(place_name))[0]
			local p_syllables = pn.syllable_count(phones)
			local stress = pn.stresses(phones)

			if p_syllables == place_syl and stress:find('1') == 1 then 
				for j = 2, #place do
					phones = pn.phones_for_word(place[j])[0]

					local syllables = pn.syllable_count(phones)
					local stress = pn.stresses(phones)

					if syllables == p_syllables and stress:find('1') == 1 then
						table.insert(ok_adjs, place[j])
					end
				end
			end

			if #ok_adjs > 0 then
				local index = #ok_places+1
				ok_places[index] = {}
				ok_places[index][1] = place_name

				for _, v in pairs(ok_adjs) do 
					table.insert(ok_places[index], v)
				end
			end
		end

		-- TODO: Make a dictionary to remove while true do
		while true do 
			local adj = descr[math.random(1, #descr)]
			local phones = pn.phones_for_word(string.lower(adj))[0] or ''
			local a_syl = pn.syllable_count(phones)

			if not adjs[1] and a_syl == lim_sizes[2] - place_syl - 5 then
				local stresses = pn.stresses(phones)

				if stresses:find('1') == 1 then 
					adjs[1] = adj
				end
			elseif not adjs[3] and a_syl == lim_sizes[5] - place_syl - 5 then
				local stresses = pn.stresses(phones)

				if stresses:find('1') == 2 then
					adjs[3] = adj
				end
			end

			if adjs[1] and adjs[3] then break end
		end

		local place_obj = ok_places[math.random(1, #ok_places)]
		place_name = place_obj[1]
		adjs[2] = place_obj[math.random(2, #place_obj)]
	end

	do
		local obj_syl = lim_sizes[3] - 4
		local ok_objs = {}

		for _, obj in pairs(objects_rhymes) do 
			local ok_objs_r = {}
			local obj_name = obj[1]
			local phones = pn.phones_for_word(string.lower(obj_name))[0]

			local o_syllables = pn.syllable_count(phones)
			local stress = pn.stresses(phones)

			if o_syllables == obj_syl and stress:find('1') == 1 then 
				for j = 2, #obj do
					phones = pn.phones_for_word(obj[j])[0]

					local syllables = pn.syllable_count(phones)
					local stress = pn.stresses(phones)

					if syllables == o_syllables and stress:find('1') == 1 then
						table.insert(ok_objs_r, obj[j])
					end
				end
			end

			if #ok_objs_r > 0 then
				local index = #ok_objs+1
				ok_objs[index] = {}
				ok_objs[index][1] = obj_name

				for _, v in pairs(ok_objs_r) do 
					table.insert(ok_objs[index], v)
				end
			end
		end

		local temp = ok_objs[math.random(1, #ok_objs)]
		objs[1] = temp[1]
		objs[3] = temp[math.random(2, #temp)]
	
		while true do
			local nouns = nouns[math.random(1, #nouns)]
			local phones = pn.phones_for_word(string.lower(nouns))[0] or ''
			local o_syl = pn.syllable_count(phones)

			if o_syl == (lim_sizes[4] - obj_syl - 3) then
				local stresses = pn.stresses(phones)

				if stresses:find('1') == 1 then 
					objs[2] = nouns
					break
				end
			end
		end
	end

	local str = 
	[[
	There was ]] .. who[1] .. [[ of ]] .. place_name .. ',\n' .. [[
	Whose conduct was ]] .. adjs[1] .. [[ and ]] .. adjs[2] .. ',\n' .. [[
	He sat on the ]] .. objs[1] .. [[,
	Eating ]] .. objs[2] .. [[ and ]] .. objs[3] .. [[,
	That ]] .. adjs[3] .. ' ' .. who[2] .. [[ of ]] .. place_name

	return str
end

local file = io.open('lims.txt', 'w')
file:write([[
	There was an Old Person of Chili,
	Whose conduct was painful and silly,
	He sat on the stairs,
	Eating apples and pears,
	That imprudent Old Person of Chili.]], '\n\n')
for i = 1, 1599 do 
	file:write(createLimeric(), '\n\n')
end
file:close()

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