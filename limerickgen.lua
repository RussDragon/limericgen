local pairs, select, math_randomseed, math_random, table_insert, table_concat,
			os_time, io_open, type, string_lower
		= pairs, select, math.randomseed, math.random, table.insert, table.concat,
			os.time, io.open, type, string.lower

local json = require('cjson')
local py = require('python')
local pn = py.import('pronouncing')

local lim_sizes =
{
	[1] = 9,
	[2] = 8,
	[3] = 6,
	[4] = 6,
	[5] = 9
}

-------------------------------------------------------------------------------

local JSON_to_table = function(path)
	local f = io_open(path)
	local js = f:read('*a')
	f:close()

	return json.decode(js)
end

local string_syllable_count = function(str)
	assert(str, 'string_syllable_count: str must be passed')

	if type(str) == 'table' then
		str = table.concat(str, ' ') or ''
	end

	local syl_count = 0
	for word in str:gmatch('%w+') do
		local phones = pn.phones_for_word(string_lower(word))[0] or ''
		local syls = pn.syllable_count(phones) or 0

		syl_count = syl_count + syls
	end

	return syl_count
end

local count_free_syls = function(str, str_size)
	return str_size - string_syllable_count(str)
end

local get_word_size = function(word)
	local phones = pn.phones_for_word(string_lower(word))[0] or ''
	local sylls = pn.syllable_count(phones)
	local stress = pn.stresses(phones)

	return sylls, stress
end

local check_word_size = function(word, sylls, stress_pos)
	-- Here must be assertions
	local wsylls, wstress = get_word_size(word)

	if wsylls ~= sylls or wstress:find('1') ~= stress_pos then return false end

	return true
end

-- Returns true if rhyming word fit to size of main
local comapre_word_sizes = function(main, rhyming)
	local msylls, mstress = get_word_size(main)
	local rsylls, rstress = get_word_size(rhyming)

	if msylls ~= rsylls or mstress:find('1') ~= rstress:find('1') then return false end

	return true
end

-------------------------------------------------------------------------------

local create_limerick = function()
	local pattern =
	{
		[1] = { 'There', 'was', '', '', 'of', '' },
		[2] = { 'Whose', 'conduct', 'was', '', 'and', '' },
		[3] = { 'He', 'sat', 'on', 'the', '' },
		[4] = { 'Eating', '', 'and', '' },
		[5] = { 'That', '', '', '', 'of', '' }
	}

	local occupations = JSON_to_table('dict/occupations.json')
	local nouns = JSON_to_table('dict/one_syl_nouns.json')

	local places_rhymes = JSON_to_table('dict/place_rhymes.json')

	local descr = JSON_to_table('dict/descriptions.json')

	local objects_rhymes = JSON_to_table('dict/obj_rhymes.json')
	local objects = JSON_to_table('dict/objs.json')

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
			if check_word_size(occ, who_syl, who_stress) then
				occ = occ:gsub('^%l', string.upper)
				local vowels = 'AEIOU'

				local article
				if not who_article then
					if vowels:find(occ:match('.')) then article = 'an' else article = 'a' end
				end
				article = article or who_article

				table_insert(ok_occup, {[1] = article, [2] = occ})
				article = nil -- HACK. FIX LATER
			end
		end

		local occ_obj = ok_occup[math_random(1, #ok_occup)]
		pattern[1][3] = occ_obj[1]
		pattern[1][4] = occ_obj[2]

		pattern[5][3] = pattern[1][3]:match(' (.+)') or '' -- HACK, FIX LATER
		pattern[5][4] = pattern[1][4]
	end

	do
		local place_syl = lim_sizes[1] - 8
		local place_stress = 1
		local ok_places = {}

		for _, place in pairs(places_rhymes) do
			local ok_adjs = {}
			local place_name = place[1]

			if check_word_size(place_name, place_syl, place_stress) then
				for j = 2, #place do
					if comapre_word_sizes(place_name, place[j]) then
						table_insert(ok_adjs, place[j])
					end
				end
			end

			if #ok_adjs > 0 then
				local index = #ok_places+1
				ok_places[index] = {}
				ok_places[index][1] = place_name

				for _, v in pairs(ok_adjs) do
					table_insert(ok_places[index], v)
				end
			end
		end

		local place_obj = ok_places[math_random(1, #ok_places)]
		pattern[1][6] = place_obj[1]
		pattern[5][6] = pattern[1][6]
		pattern[2][6] = place_obj[math_random(2, #place_obj)]
	end

	do
		-- TODO: Make a dictionary to remove while true do
		while true do
			local adj = descr[math_random(1, #descr)]

			if pattern[2][4] == '' then
				if check_word_size(adj, count_free_syls(pattern[2], lim_sizes[2]), 1) then
					pattern[2][4] = adj
				end
			elseif pattern[5][2] == '' then
				if check_word_size(adj, count_free_syls(pattern[5], lim_sizes[5]), 2) then
					pattern[5][2] = adj
				end
			end

			if pattern[2][4] ~= '' and pattern[5][2] ~= '' then break end
		end
	end

	do
		local obj_syl = lim_sizes[3] - 4
		local obj_stress = 1
		local ok_objs = {}

		for _, obj in pairs(objects_rhymes) do
			local ok_objs_rhymes = {}
			local obj_name = obj[1]

			if check_word_size(obj_name, obj_syl, obj_stress) then
				for j = 2, #obj do
					if comapre_word_sizes(obj_name, obj[j]) then
						table_insert(ok_objs_rhymes, obj[j])
					end
				end
			end

			if #ok_objs_rhymes > 0 then
				local index = #ok_objs+1
				ok_objs[index] = {}
				ok_objs[index][1] = obj_name

				for _, v in pairs(ok_objs_rhymes) do
					table_insert(ok_objs[index], v)
				end
			end
		end

		local temp = ok_objs[math_random(1, #ok_objs)] -- HACK. FIX LATER
		pattern[3][5] = temp[1]
		pattern[4][4] = temp[math_random(2, #temp)]
	end
	
	pattern[4][2] = nouns[math.random(1, #nouns)]
	
	local lim = {}
	for k, v in pairs(pattern) do
		lim[k] = table_concat(v, ' '):gsub('%s%s', ' ') -- HACK. FIX LATER
	end

	return lim
end

-------------------------------------------------------------------------------

math_randomseed(os_time())

local iters = select(1, ...) or 1
for i = 1, iters do
	local lim = table_concat(create_limerick(), ',\n') .. '.'
	print(lim)
end
