# Balladina

[![Code Climate](https://codeclimate.com/github/dodecaphonic/balladina.png)](https://codeclimate.com/github/dodecaphonic/balladina)
[![Build Status](https://travis-ci.org/dodecaphonic/balladina.png?branch=master)](https://travis-ci.org/dodecaphonic/balladina)
[![Coverage Status](https://coveralls.io/repos/dodecaphonic/balladina/badge.png)](https://coveralls.io/r/dodecaphonic/balladina)

An online jam session with recording capabilities. The idea is to put some people together, using WebRTC for their session and a backend to record each person's track data.

## Running

Be sure that you have the following binaries in your path:

  - zip
  - sox
  - lame

All can be found in good Linux and Unix systems via their lovely package managers (or ersatz managers, such as Homebrew).

Balladina requires a Ruby with 2.0 syntax. That means:

  - Ruby 2.x
  - JRuby-1.7
  - Rubinius 2.2.x

The first two have been tested quite a bit and are known to work well.

After cloning the source, install the bundle and run:

        $ bundle exec foreman start

This will start the stupidest of frontends and the backend. To try it, go to <code>http://localhost:9292</code>. For now, recording is restricted to WebKit-based browsers, and doesn't work on Linux. This will change in the near future.

