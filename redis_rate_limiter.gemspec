$:.push File.expand_path("../lib", __FILE__)
require 'redis_rate_limiter/version'

Gem::Specification.new do |s|
  s.name          = 'redis_rate_limiter'
  s.version       = RedisRateLimiter::VERSION.dup
  s.licenses      = ["MIT"]
  s.summary       = 'Redis-backed rate limiter'
  s.description   = 'Redis-backed rate limiter'
  s.authors       = ['Sean Xie']
  s.email         = 'seanx@referralcandy.com'
  s.files         = ['lib/redis_rate_limiter.rb']
  s.homepage      = 'https://rubygems.org/gems/redis_rate_limiter'

  s.add_dependency             "redis"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", ">= 2.9.0"
  s.add_development_dependency "mock_redis"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "yard"
end
