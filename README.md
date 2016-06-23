TODO scraper
============

## Overview

Ruby scraper that greps a directory for TODO comments, and then prints the output in a simple report.

The comments are grouped by "group", and then by filename.  A "group" is defined as anything after TODO, up to the first colon.  For example, the following comments would have the specified group:

|comment|group|
|-------|-----|
|TODO groupA: rest of line is ignored|groupA|
|# TODO some group: more notes|some group|
|# TODO another: next semicolon: is ignored|another|

A sample report:

````
Group: <None>
  File: ./ignoreMe/ignoreA.txt
    TODO something
  File: ./subA/ignoreMeSubA/subAignore.txt
    TODO subAignore
  File: ./subA/subAfile.txt
    todo subafile.txt

Group: group B
  File: ./a.txt
    TODO group B: another thing
  ... etc.
````

## System Requirements

* Ruby (only tested on ruby 2.0.0)
* Underlying OS must support grep and find, as code shells out to OS for that (can verify by running the unit tests)


## Usage

The main script is called from the command line, with options passed in:

````
$ ruby main.rb -h
Usage: main.rb [options]
    -d, --directory DIR              Path to directory to grep
    -g, --global CONFIG              Path to global configuration file
    -c, --config CONFIG              Path to configuration file
    -v, --verbose                    Verbose output
    -h, --help                       Show this message
exit

````

The ```directory``` argument is required.

Two configurations are presented (global and config) as the former is useful for global config settings (eg, to ignore all .git directories, or all .exes), and the latter can be used for project-specific settings.

Sample run, using the sample project:

````
$ ruby main.rb -d test/sampleproj/ -c config.yaml.sample

Group: <None>
  File: ./ignoreMe/ignoreA.txt
    TODO something
  ... etc.
````

### The configuration file

A config.yaml.sample is in the root folder, with some samples.  File exclusion can be done with globbing (ref http://ruby.about.com/od/beginningruby/a/dir2.htm).


## Development

```main.rb``` is a wrapper around a single ruby class, ```src/todout.rb```

Tests:

````
$ cd test
$ ruby test_todout.rb
Finished tests in 0.103679s, 115.7419 tests/s, 221.8386 assertions/s.                                      
12 tests, 23 assertions, 0 failures, 0 errors, 0 skips
````
