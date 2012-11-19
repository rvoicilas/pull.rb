pull.rb [![Build Status](https://secure.travis-ci.org/rvoicilas/pull.rb.png)](http://travis-ci.org/rvoicilas/pull.rb)

Command-line tool for switching branches and pulling data in from upstream for multiple projects in the same time (for now only git is supported). 
Skips the project  if there are local changes.

Usage:
    
    bin/pull.rb master

    bin/pull.rb --quiet --file ~/.pull_rb_config.yml develop