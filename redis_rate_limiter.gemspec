Gem::Specification.new do |s|
  s.name          = 'redis_rate_limiter'
  s.version       = '0.0.1'
  s.date          = '2013-09-25'
  s.summary       = 'Redis-backed rate limiter'
  s.description   = 'Redis-backed rate limiter'
  s.authors       = ['Sean Xie']
  s.email         = 'sean.xie.sx@gmail.com'
  s.files         = ['lib/redis_rate_limiter.rb']
  s.homepage      = 'https://rubygems.org/gems/redis_rate_limiter'

  s.add_dependency             "redis"
  s.add_development_dependency "rspec", ">= 2.9.0"
  s.add_development_dependency "mock_redis"
end
