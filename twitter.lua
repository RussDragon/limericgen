local select, tonumber = select, tonumber
local twitter = require('twitter').Twitter
local json = require('cjson')

-------------------------------------------------------------------------------

local load_conf = function(path)
  local f = io.open(path, 'r')
  local conf = json.decode(f:read('*a'))
  f:close()

  return conf
end

-------------------------------------------------------------------------------

local conf = load_conf('conf.json')
local username = conf.username

local acc = twitter(conf.api_keys)

local command = {}

command.update = function(msg)
  acc:post_status({ status = msg })
end

command.get = function(n)
  local tweets = acc:get_user_timeline(
    { tweet_mode = 'extended', screen_name = username, n = tonumber(n) }
  )

  return tweets
end

-------------------------------------------------------------------------------

local cmd, param = select(1, ...), select(2, ...)
local res = command[cmd](param) or {}

for _, v in pairs(res) do 
  local s = v.full_text or v.text or ''
  io.write(s, '\n')
end
