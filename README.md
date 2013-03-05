# DECC 2050 CALCULATOR TOOL

An experimental alternative web interface to the www.decc.gov.uk 2050 energy and climate change calculator

Further detail on the project:
http://www.decc.gov.uk/2050

Canonical source:
http://github.com/decc/42Questions

Original interface
http://github.com/decc/twenty-fifty

# INSTALATION

1. Install ruby 1.9.2 or greater (including development headers)
2. 'gem install bundler' or 'sudo gem install bundler'
3. cd 42Questions
4. bundle

# RUNNING

It can run in two modes, 'production' and 'development'.

Production is what you usually want:

1. cd 42Questions
2. ruby 2050.rb -e production
3. Navigate to http://0.0.0.0:4567 in your web browser

Development takes more effort to set up, but then reloads various files on each page request, making development easier:

1. cd 42Questions
2. rackup
3. Navigate to http://0.0.0.0:9292 in your web browser

Note: If the development version doesn't seem to be working, try deleting public/index.html

# HACKING

You are welcome to improve this code. Please read the LICENCE file and then the HACKING file contains some hints and tips on changing the code and a process for sending in patches and bug reports.
