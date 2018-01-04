## limericgen
#Generator of limericks

Generator of limericks with Edward Lear pattern.

#Dependencies (generator): 
- Lua-cjson
- Python 2.7
- Python pronouncing module
- Lunatic-python

#Installation (generator):
> apt-get install lua5.1
> apt-get install python
> pip install pronouncing

> git clone lunatic-python
> cd lunatic-python
> edit setup.py and change lua version to 5.1
> sudo python setup.py install
> cd build/lib/
> mv lua-python.so /usr/local/lib/lua/5.1/python.so

#Dependencies (twitter bot):
- Twiiter t (https://github.com/sferik/t)
- Twitter account with api tokens

#Installation (twitter bot):
- Download and install twitter t
- Authorize your twitter with "t authorize"
- Clone this repo to any directory
- Setup crontab to start bot.sh with required frequency

Crontab example:
> crontab -e

Then add this line to the end:
> * * * * * /home/username/twitter_bot/bot.sh

This will run script every minute and post new limerick to your twitter. Read crontab docs to more information.
