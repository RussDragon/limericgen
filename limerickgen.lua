local select, math_randomseed, math_random, table_insert = select, math.randomseed, 
																													 math.random, table.insert

local json = require('cjson')
local py = require('python')

local lim_sizes = 
{
	[1] = 9,
	[2] = 8,
	[3] = 6,
	[4] = 6,
	[5] = 9
}

local JSONtoTable = function(path)
	local f = io.open(path)
	local js = f:read('*a')
	f:close()

	return json.decode(js)
end

local createLimerick = function()
	local pattern = 
	{
		[1] = { 'There', 'was', '', '', 'of', '' },
		[2] = { 'Whose', 'conduct', 'was', '', 'and', '' },
		[3] = { 'He', 'sat', 'on', 'the', '' },
		[4] = { 'Eating', '', 'and', '' },
		[5] = { 'That', '', '', '', 'of', '' }
	}

	local pn = py.import('pronouncing')

	local occupations = JSONtoTable('dict/occupations.json')
	local nouns = JSONtoTable('dict/nouns.json')

	local places_rhymes = JSONtoTable('dict/place_rhymes.json')

	local descr = JSONtoTable('dict/descriptions.json')

	local objects_rhymes = JSONtoTable('dict/obj_rhymes.json')
	local objects = JSONtoTable('dict/objs.json')

	do
		local who_article = ''
		local who_syl = 0
		local who_stress = 0

		-- 1 – a/an young/old (2syl), 2 – a/an (3syl)
		if math_random(1, 2) == 1 then
			who_syl = 2
			who_stress = 1

			if math_random(1, 2) == 1 then who_article = 'an Old' else who_article = 'a Young' end
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
				occ = occ:gsub('^%l', string.upper)
				local vowels = 'AEIOU'
				if not who_article then
					if vowels:find(occ:match('.')) then who_article = 'an' else who_article = 'a' end
				end

				table.insert(ok_occup, occ)
			end
		end

		pattern[1][3] = who_article
		pattern[1][4] = ok_occup[math_random(1, #ok_occup)]
		pattern[5][3] = pattern[1][3]:match(' (.+)')
		pattern[5][4] = pattern[1][4]
	end

	do
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
			local adj = descr[math_random(1, #descr)]
			local phones = pn.phones_for_word(string.lower(adj))[0] or ''
			local a_syl = pn.syllable_count(phones)

			if not pattern[2][4] ~= '' and a_syl == lim_sizes[2] - place_syl - 5 then
				local stresses = pn.stresses(phones)

				if stresses:find('1') == 1 then 
					pattern[2][4] = adj
				end
			elseif not pattern[5][2] ~= '' and a_syl == lim_sizes[5] - place_syl - 5 then
				local stresses = pn.stresses(phones)

				if stresses:find('1') == 2 then
					pattern[5][2] = adj
				end
			end

			if pattern[2][4] ~= '' and pattern[5][2] ~= '' then break end
		end

		local place_obj = ok_places[math_random(1, #ok_places)]
		pattern[1][6] = place_obj[1]
		pattern[5][6] = pattern[1][6]
		pattern[2][6] = place_obj[math_random(2, #place_obj)]
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

				for j = 2, #obj do
			if o_syllables == obj_syl and stress:find('1') == 1 then 
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

		local temp = ok_objs[math_random(1, #ok_objs)]
		pattern[3][5] = temp[1]
		pattern[4][4] = temp[math_random(2, #temp)]
	
		while true do
			local nouns = nouns[math_random(1, #nouns)]
			local phones = pn.phones_for_word(string.lower(nouns))[0] or ''
			local o_syl = pn.syllable_count(phones)

			if o_syl == (lim_sizes[4] - obj_syl - 3) then
				local stresses = pn.stresses(phones)

				if stresses:find('1') == 1 then 
					pattern[4][2] = nouns
					break
				end
			end
		end
	end
	
	local lim = {}
	for k, v in pairs(pattern) do 
		lim[k] = table.concat(v, ' ')
	end

	return lim
end

math_randomseed(os.time())

local iters = select(1, ...) or 1
for i = 1, iters do
	local lim = table.concat(createLimerick(), ',\n') .. '.'
	print(lim)
end
