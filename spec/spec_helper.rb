require 'coveralls'
Coveralls.wear!
require 'rspec'
require 'rspec/its'
require File.join(File.dirname(__FILE__), '..', 'lib', 'redis_rate_limiter')
require 'mock_redis'
