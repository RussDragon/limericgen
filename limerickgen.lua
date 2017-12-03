local json = require('cjson')
local py = require('python')

local lim_sizes = {}
lim_sizes[1] = 9
lim_sizes[2] = 8
lim_sizes[3] = 6
lim_sizes[4] = 6
lim_sizes[5] = 9

local JSONtoTable = function(path)
	local f = io.open(path)
	local js = f:read('*a')
	f:close()

	return json.decode(js)
end

local createLimerick = function()
	local pn = py.import('pronouncing')

	local occupations = JSONtoTable('dict/occupations.json')
	local nouns = JSONtoTable('dict/nouns.json')

	local places_rhymes = JSONtoTable('dict/place_rhymes.json')

	local descr = JSONtoTable('dict/descriptions.json')

	local objects_rhymes = JSONtoTable('dict/obj_rhymes.json')
	local objects = JSONtoTable('dict/objs.json')

	local who = {'', ''}
	local place_name = ''
	local adjs = {}
	local objs = {'','',''}

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

	local str = [[
There was %s of %s,
Whose conduct was %s and %s, 
He sat on the %s, 
Eating %s and %s,
That %s %s of %s
]]

	return str:format(
										who[1], place_name, adjs[1], adjs[2], objs[1], objs[2], 
										objs[3], adjs[3], who[2], place_name
									)
end

return 
{
	createLimerick = createLimerick
}
