# REST assured

[![Build status](https://secure.travis-ci.org/BBC/REST-assured.png)](https://secure.travis-ci.org/BBC/REST-assured)

## Overview

Stub/spy http(s) based external dependencies in your integration/acceptance tests.

In a nutshell, you can:

* replace external data sources with predefined data (stubbing)
* verify requests to external services (spying)
* simulate different behavior of external services using web UI; useful in development

Here is how it works. REST-assured starts an application that can be instructed (via ruby client library or plain REST api) to respond to any request with arbitrary content, status, headers, etc. Configure api endpoints of the application under test to point to that application instead of real services. Then in tests use the API (create doubles) that match requests your application is supposed to be firing. Either to stub content or to verify various aspects of how your application requests dependencies (headers, payload, etc).

Check out [example](https://github.com/artemave/REST-assured-example)


## Set up

You are going to need ruby >= 1.8.7 on Linux/MacOS. Also, one of sqlite3, postgres or mysql.

### Ruby Client

```ruby
# Gemfile
gem 'sqlite3' # or mysql2 or pg
gem 'thin'    # to make it faster; optional
gem 'rest-assured'

# env.rb/spec_helper.rb
require 'rest-assured'

RestAssured::Server.start(database: ':memory:', port: 7899) # or any other option available on command line
# Alternatively, if you want to use existing server instance:
RestAssured::Server.address = 'http://localhost:4578' # or wherever it is
```

### Standalone instance

Install db client gem:

    $ gem install sqlite3 # or mysql2 or pg

If using mysql/postgres, rest-assured expects database `rest_assured` to be accessible by user `root` with no password. Those are defaults and can be changed with cli options.

It is also recommended to have thin installed. This improves startup time (over default webrick) and also it works with in-memory sqlite (which webrick does not):

    $ gem install thin

Then install gem and run:

    $ gem install rest-assured
    $ rest-assured &

Or clone and run:

    $ git clone git://github.com/BBC/REST-assured.git
    $ cd REST-assured && bundle install
    $ ./bin/rest-assured -d :memory: & # in-memory sqlite db

This starts up an instance of rest-assured on port 4578. It is accessible via REST or web interfaces on `http://localhost:4578`

Various options (such as ssl, port, db credentials, etc.) are available through command line options. Check out `rest-assured -h` to see what they are.

You can also deploy it to heroku:

    $ git clone git://github.com/BBC/REST-assured.git
    $ cd REST-assured

    $ gem install heroku
    $ heroku login # assuming you already have an account
    $ heroku create --stack cedar
    
    $ git push heroku master

## Usage

REST-assured is all about doubles. Double is a stub/spy of HTTP request. Create one that has the same request fullpath and method as the one your app is sending to a dependant service and then convience your app that REST-assured is that dependency (hint: by making endpoints configurable).

### Ruby Client

REST-assured provides client library to work with doubles. Check out 'Ruby API' section in [live documentation](https://www.relishapp.com/artemave/rest-assured) for full reference.

Create double:

```ruby
RestAssured::Double.create(fullpath: '/products', content: 'this is content')
```

Now GET `http://localhost:4578/products` will be returning `this is content`.

You can also verify what requests happen on a double (spy on it). Say this is a Given part of a test:

```ruby
@double = RestAssured::Double.create(fullpath: '/products', verb: 'POST')
```

Then let us assume that `http://localhost:4578/products` got POSTed as a result of some actions in When part. Now we can examine requests happened on that double in Then part:

```ruby
@double.wait_for_requests(1, timeout: 10) # defaults to 5 seconds
# or, if waiting for specific amount of requests does not suit the test, just
@double.reload # before verifying

req = @double.requests.first

req.body.should == some_expected_payload
JSON.parse(req.params).should == expected_params_hash
JSON.parse(req.rack_env)['HTTP_ACCEPT'].should == 'text/html'
```

Use plain REST api to clear doubles/redirects between tests:

```ruby
RestClient.delete "#{RestAssured::Server.address}/redirects/all"
RestClient.delete "#{RestAssured::Server.address}/doubles/all"
```

### Plain REST API

For those using REST-assured from non-ruby environments.

#### Create double

  HTTP POST to `/doubles` creates a double and returns its json representation.
  The following options can be passed as request parameters:

  - __fullpath__ - e.g., `/some/api/object`, or with parameters in query string (useful for doubling GETs) - `/some/other/api/object?a=2&b=c`. Mandatory.
  - __content__ - whatever you want this double to respond with. Optional.
  - __verb__ - one of http the following http verbs: `GET`, `POST`, `PUT`, `DELETE`. Optional. `GET` is default.
  - __status__ - status returned when double is requested. Optional. `200` is default.
  - __response_headers__ - key/value map of headers. Optional.
  
  Example:

```
    $ curl -d 'fullpath=/api/something&content=awesome&response_headers%5BContent-Type%5D=text%2Fhtml' http://localhost:4578/doubles
    {"double":{"active":true,"content":"awesome","description":null,"fullpath":"/api/something","id":1,"response_headers":{"Content-Type":"text/html"},"status":200,"verb":"GET"}}

    $ curl http://localhost:4578/api/something
    awesome
```

  If there is more than one double for the same fullpath and verb, the last created one gets served. In UI you can manually control which double is 'active' (gets served).

#### Get double state

  HTTP GET to `/doubles/:id.json` returns json with double current state. Use id from create json as `:id`.
  
  Example:
    
    $ curl http://localhost:4578/doubles/1.json | prettify_json.rb
    {
        "double": {
            "verb": "GET",
            "fullpath": "/api/something",
            "response_headers": {
                "Content-Type": "text/html"
            },
            "id": 1,
            "requests": [
                {
                    "double_id": 1,
                    "created_at": "2011-12-12T11:13:33+00:00",
                    "body": "",
                    "rack_env": "{\"SERVER_SOFTWARE\":\"thin 1.3.1 codename Triple Espresso\",\"SERVER_NAME\":\"localhost\",\"rack.version\":[1,0],\"rack.multithread\":false,\"rack.multiprocess\":false,\"rack.run_once\":false,\"REQUEST_METHOD\":\"GET\",\"REQUEST_PATH\":\"/api/something\",\"PATH_INFO\":\"/api/something\",\"REQUEST_URI\":\"/api/something\",\"HTTP_VERSION\":\"HTTP/1.1\",\"HTTP_USER_AGENT\":\"curl/7.19.7 (universal-apple-darwin10.0) libcurl/7.19.7 OpenSSL/0.9.8l zlib/1.2.3\",\"HTTP_HOST\":\"localhost:4578\",\"HTTP_ACCEPT\":\"*/*\",\"GATEWAY_INTERFACE\":\"CGI/1.2\",\"SERVER_PORT\":\"4578\",\"QUERY_STRING\":\"\",\"SERVER_PROTOCOL\":\"HTTP/1.1\",\"rack.url_scheme\":\"http\",\"SCRIPT_NAME\":\"\",\"REMOTE_ADDR\":\"127.0.0.1\",\"async.callback\":{},\"async.close\":{},\"rack.session\":{\"session_id\":\"2d206d4edb880d41ae098bf0551c6904a4914f8632d101606b5304d4f651ce52\",\"tracking\":{\"HTTP_USER_AGENT\":\"06e79511d71287ca292dced4ef07c8fff9400376\",\"HTTP_ACCEPT_ENCODING\":\"da39a3ee5e6b4b0d3255bfef95601890afd80709\",\"HTTP_ACCEPT_LANGUAGE\":\"da39a3ee5e6b4b0d3255bfef95601890afd80709\"},\"__FLASH__\":{}},\"rack.session.options\":{\"key\":\"rack.session\",\"path\":\"/\",\"domain\":null,\"expire_after\":null,\"secure\":false,\"httponly\":true,\"defer\":false,\"renew\":false,\"sidbits\":128,\"secure_random\":{\"pid\":7885},\"secret\":\"bf80c75d713c92d2e3f94ea58be318c3f8988a3ed79d997f9cf883cc7aab1141225477ed81da7fe62ac77ecac3f979d255328dcbe8caa1bb342f4be6cb850983\",\"coder\":{},\"id\":\"2d206d4edb880d41ae098bf0551c6904a4914f8632d101606b5304d4f651ce52\"},\"rack.request.cookie_hash\":{},\"rack.session.unpacked_cookie_data\":{\"session_id\":\"2d206d4edb880d41ae098bf0551c6904a4914f8632d101606b5304d4f651ce52\"},\"x-rack.flash\":{\"opts\":{\"sweep\":true},\"store\":{\"session_id\":\"2d206d4edb880d41ae098bf0551c6904a4914f8632d101606b5304d4f651ce52\",\"tracking\":{\"HTTP_USER_AGENT\":\"06e79511d71287ca292dced4ef07c8fff9400376\",\"HTTP_ACCEPT_ENCODING\":\"da39a3ee5e6b4b0d3255bfef95601890afd80709\",\"HTTP_ACCEPT_LANGUAGE\":\"da39a3ee5e6b4b0d3255bfef95601890afd80709\"},\"__FLASH__\":{}},\"flagged\":[]},\"rack.request.query_string\":\"\",\"rack.request.query_hash\":{}}",
                    "id": 1,
                    "params": "{}"
                }
            ],
            "content": "awesome",
            "description": null,
            "status": 200,
            "active": true
        }
    }

  The above assumes that that double has been requested once. Request history is in `requests` array (in chronological order). Each element contains the following data (keys):
  
  - __body__ - request payload
  - __params__ - request parameters. json
  - __created_at__ - request timestamp
  - __rack_env__ - raw request dump (json) including request headers

#### Delete all doubles

  HTTP DELETE to `/doubles/all` deletes all doubles. Useful for cleaning up between tests.

## Redirects

It is sometimes desirable to only double certain calls while letting others through to the "real" services. Meet Redirects. Kind of "rewrite rules" for requests that didn't match any double. 

Another use for redirects is setting up a "default" double that matches multiple fullpaths. If a redirect pattern matches a defined double then it will act like a double and respond directly.  If it does not match a double then it will return HTTP 303 redirect instead.  Note that HTTP redirects are usually converted to GET requests by HTTP clients.

Here is the rest API for managing redirects:

### Create redirect

  HTTP POST to `/redirects` creates redirect.
  The following options can be passed as request parameters:

  - __pattern__ - regex (perl5 style) tested against request fullpath. e.g, `^/auth/(.*)`. Mandatory
  - __to__ - url base e.g, `http://example.com/api/\1?p=1` where `\1` is a reference to captured group from the pattern. Mandatory

  Example:

```  
    $ curl -d 'pattern=^/auth&to=https://myserver.com/api' http://localhost:4578/redirects
```

  Now request (any verb) to `http://localhost:4578/auth/services/1` will get redirected to `https://myserver.com/api/`. Provided of course there is no double matched for that fullpath and verb. Captured group in pattern can be referenced from replacement e.g. `\1`, `\2`, etc.
  Much like rewrite rules, redirects are evaluated in order (of creation). In UI you can manually rearrange the order.

### Delete all redirects

  HTTP DELETE to `/redirects/all` deletes all redirects. Useful for cleaning up between tests.
  
## Running tests

Tests require there to be mysql database `rest_assured_test` accessible by `root` with no password. Cucumber tests also need firefox.

    $ git clone git://github.com/BBC/REST-assured.git
    $ cd rest-assured && bundle install
    $ bundle exec rspec spec
    $ bundle exec cucumber

### Useful test references

* http://rubydoc.info/gems/rspec-mocks/frames

## Author

[Artem Avetisyan](https://github.com/artemave)

## Changelog

#### 1.1.8 (11 May 2012)

* add status to UI
* support PATCH
* minor UI tweeks

#### 1.1.5 (19 Apr 2012)

* add Double.all and Double#destroy

#### 1.1.3 (21 Mar 2012)

* support long (>256 chars) fullpath

#### 1.1.2 (04 Mar 2012)

* support postgres
* heroku deployable

#### 1.1.1 (01 Mar 2012)

* Add 'verb' to UI
* No more forked version of Server

#### 1.1.0 (17 Feb 2012)

* Redirects support 'real' (without http redirect) rewrite to local double

#### 1.0.0 (14 Feb 2012)

* start/stop rest-assured via api
* redirects support pattern/replacement

#### 0.3.2 (23 Jan 2012)

* double 'activeness' does not take verb into account (bugfix)

#### 0.3.1 (09 Jan 2012)

* lock rack version to <= 1.3.6 until they release fix for https://github.com/rack/rack/issues/299

#### 0.3 (12 Dec 2011)

* you can now specify response headers for double to respond with

#### 0.2

* adds verifications
* adds ruby client
* adds custom return statuses
* adds ssl
* adds mysql support

#### 0.1

* initial public release

