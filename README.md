## limericgen
# Generator of limericks

Generator of limericks with Edward Lear pattern.
It was tested with Lua 5.1 and Python 2.7.

# Dependencies (generator): 
- Lua-cjson
- Lua-nucleo
- Python 2.7
- Python pronouncing module
- Lunatic-python

# Installation (generator):
> sudo apt-get install lua5.1

> sudo apt-get install python

> pip install pronouncing

> sudo luarocks install lua-cjson

> sudo luarocks install lua-nucleo

> git clone lunatic-python

> cd lunatic-python

> edit setup.py and change lua version to 5.1

> sudo python setup.py install

> cd build/lib/

> mv lua-python.so /usr/local/lib/lua/5.1/python.so

# Usage:
To use generator you should launch `limerickgen.lua` script and specify amount of limericks to generate with first parameter.
For example:
> lua limerickgen.lua 1

It will output 1 randomly generated limerick to stdout.
NB: 
You must be in the same directory with script, 
otherwise you won't be able to launch it, 
due to the searching paths of Lua interpreter.

To use mutations of limerick you should use this syntax:
> lua limerickgen.lua 2 --mutation

If done correctly, it prints 2 limricks: first is a default limerick without mutation and second with mutation.

# Dependencies (twitter bot):
- Install lua-twitter (https://github.com/leafo/lua-twitter)
- Twitter account with api tokens

# Installation (twitter bot):
- Download and install lua-twitter from repository
- Write screen_name (your username) of your twitter account to conf.json
- Write your tokens to conf.json
- Clone this repo to any directory
- Setup crontab to start bot.sh with required frequency

Crontab example:
> crontab -e

Then add this line to the end:
> * * * * * /home/username/twitter_bot/bot.sh

This will run script every minute and post new limerick to your twitter. Read crontab docs to more information.
