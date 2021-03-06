require 'lua-nucleo'

local pairs, select, math_randomseed, math_random, table_insert, table_concat,
      os_time, io_open, type, string_lower
    = pairs, select, math.randomseed, math.random, table.insert, table.concat,
      os.time, io.open, type, string.lower

local json = require('cjson')
local py = require('python')
local pn = py.import('pronouncing')

local split_by_char = import 'lua-nucleo/string'
{
  'split_by_char';
}

-------------------------------------------------------------------------------

local JSON_to_table = function(path)
  local f = io_open(path)
  local js = f:read('*a')
  f:close()

  return json.decode(js)
end

-------------------------------------------------------------------------------

local string_syllable_count = function(str)
  assert(str, 'string_syllable_count: str must be passed')

  -- HACK. CHANGE LATER
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

-- Use only with dictionaries like obj_rhymes/place_rhymes, first word must be
-- main and all the rest is rhyming to it
local get_rhyming_pair = function(dictionary, sylls, stress_pos)
  -- Here must be assertions

  local ok_sets = {}

  for _, set in pairs(dictionary) do
    local ok_rhymes = {}
    local main = set[1]

    if check_word_size(main, sylls, stress_pos) then
      for j = 2, #set do
        if comapre_word_sizes(main, set[j]) then
          table_insert(ok_rhymes, set[j])
        end
      end
    end

    if #ok_rhymes > 0 then
      local index = #ok_sets+1
      ok_sets[index] = {}
      ok_sets[index][1] = main

      for _, v in pairs(ok_rhymes) do
        table_insert(ok_sets[index], v)
      end
    end
  end

  local set = ok_sets[math_random(1, #ok_sets)]

  return set[1], set[math_random(2, #set)]
end

-- Use only for plain dictionaries like adjs, descriptions, nouns, etc
local get_random_word = function(dictionary, sylls, stress_pos)
  local ok_elems = {}
  for _, elem in pairs(dictionary) do
    if check_word_size(elem, sylls, stress_pos) then
      table_insert(ok_elems, elem)
    end
  end

  return ok_elems[math_random(1, #ok_elems)]
end


-------------------------------------------------------------------------------

local parse_limerick = function(str)
  local pattern = {}

  for k, line in pairs(split_by_char(str, '\n')) do
    pattern[k] = {}
    for word in line:gmatch('%w+') do
      table_insert(pattern[k], word)
    end
  end

  return pattern
end

-------------------------------------------------------------------------------

local occupations = JSON_to_table('dict/occupations.json')
local nouns = JSON_to_table('dict/one_syl_nouns.json')
local descr = JSON_to_table('dict/descriptions.json')

local places_rhymes = JSON_to_table('dict/place_rhymes.json')
local objects_rhymes = JSON_to_table('dict/obj_rhymes.json')

local lim_sizes =
{
  [1] = 8, -- 8 because we count 2 syllables in 'there'
  [2] = 8,
  [3] = 6,
  [4] = 6,
  [5] = 9
}

local make_limerick
do
  local add_occupation = function(pattern)
    pattern[1][3] = ''
    pattern[1][4] = ''
    pattern[5][3] = ''
    pattern[5][4] = ''

    local who_syl
    local who_stress

    -- 1 – a/an young/old (2syl), 2 – a/an (3syl)
    if math_random(1, 2) == 1 then
      if math_random(1, 2) == 1 then
        pattern[1][3] = 'an'
        pattern[1][4] = 'Old'
      else
        pattern[1][3] = 'a'
        pattern[1][4] = 'Young'
      end

      who_syl = 2
      who_stress = 1
    else
      who_syl = 3
      who_stress = 2
    end

    local who = get_random_word(occupations, who_syl, who_stress):gsub('^%l', string.upper)
    pattern[1][5] = who
    pattern[5][4] = pattern[1][5]

    if pattern[1][3] == '' then
      local vowels = 'AEIOU'

      if vowels:find(who:match('.')) then
        pattern[1][3] = 'an'
      else
        pattern[1][3] = 'a'
      end
    end

    pattern[5][3] = pattern[1][4]
  end

  local add_place = function(pattern)
    pattern[1][7] = ''
    pattern[2][6] = ''
    pattern[5][6] = ''

    local place_syl = count_free_syls(pattern[1], lim_sizes[1])
    local place_stress = 1

    local place, adj = get_rhyming_pair(places_rhymes, place_syl, place_stress)

    pattern[1][7] = place
    pattern[2][6] = adj
    pattern[5][6] = pattern[1][7]
  end

  local add_descriptions = function(pattern)
    pattern[2][4] = ''
    pattern[5][2] = ''

    pattern[2][4] = get_random_word(descr, count_free_syls(pattern[2], lim_sizes[2]), 1)
    pattern[5][2] = get_random_word(descr, count_free_syls(pattern[5], lim_sizes[5]), 2)
  end

  local add_objects = function(pattern)
    pattern[3][5] = ''
    pattern[4][4] = ''

    local obj_syl = count_free_syls(pattern[3], lim_sizes[3])
    local obj_stress = 1

    local obj, obj_rhyme = get_rhyming_pair(objects_rhymes, obj_syl, obj_stress)

    pattern[3][5] = obj
    pattern[4][4] = obj_rhyme
  end

  local add_noun = function(pattern)
    pattern[4][2] = ''
    pattern[4][2] = nouns[math.random(1, #nouns)]
  end

  local generate = function(self)
    add_occupation(self.pattern_)
    add_place(self.pattern_)
    add_descriptions(self.pattern_)
    add_objects(self.pattern_)
    add_noun(self.pattern_)

    return self
  end

  local mutate = function(self)
    local change_pos = math.random(1, 5)

    if change_pos == 1 then
      add_occupation(self.pattern_)
    elseif change_pos == 2 then
      add_place(self.pattern_)
    elseif change_pos == 3 then
      add_descriptions(self.pattern_)
    elseif change_pos == 4 then
      add_objects(self.pattern_)
    elseif change_pos == 5 then
      add_noun(self.pattern_)
    end

    return self
  end

  local render = function(self)
    local lim = {}
    for k, v in pairs(self.pattern_) do
      lim[k] = table_concat(v, ' '):gsub('%s%s', ' ')
    end

    return table_concat(lim, '\n') .. '.'
  end

  local set_pattern = function(self, str)
    self.pattern_ = parse_limerick(str)
  end

  local get_pattern = function(self)
    return self.pattern_
  end

  make_limerick = function()
    return
    {
      generate = generate;
      mutate = mutate;
      render = render;
      set_pattern = set_pattern;
      get_pattern = get_pattern;

      pattern_ =
      {
        [1] = { 'There', 'was', '', '', '', 'of', '' },
        [2] = { 'Whose', 'conduct', 'was', '', 'and', '' },
        [3] = { 'He', 'sat', 'on', 'the', '' },
        [4] = { 'Eating', '', 'and', '' },
        [5] = { 'That', '', '', '', 'of', '' }
      }
    }
  end
end

-------------------------------------------------------------------------------

math_randomseed(os_time())

local iters = select(1, ...) or 4
local is_mutated = (select(2, ...) == '--mutate')
local passed_lim = select(3, ...)

if not is_mutated and passed_lim then
  error('ERROR: you passed limerick but did not specify mutation flag')
end

local limerick = make_limerick()

if passed_lim then
  limerick:set_pattern(passed_lim)
else
  limerick:generate()
end

for i = 1, iters do
  io.write(limerick:render(), '\n\n')

  if is_mutated then
    limerick:mutate()
  else
    limerick:generate()
  end
end
